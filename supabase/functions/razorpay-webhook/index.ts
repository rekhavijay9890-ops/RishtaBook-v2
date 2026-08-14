// Supabase Edge Function: razorpay-webhook
//
// Closes a real security gap flagged in lib/services/credit_service.dart's
// doc comment: today, a successful Razorpay payment is trusted purely from
// the CLIENT's success callback (WalletPage._onPaymentSuccess calling
// CreditService.completePurchase directly) - a modified/hacked build of the
// app could call that same method without ever paying and grant itself
// free credits. This function is the fix: Razorpay calls it server-to-server
// once a payment is genuinely captured, we verify that request really came
// from Razorpay (HMAC signature check against a secret only Razorpay and
// this function know), and only THEN write credits to Firestore - using a
// Google service-account OAuth token, which (unlike the Firebase client
// SDK) bypasses firestore.rules entirely, the same way Cloud Functions'
// Admin SDK would.
//
// Reuses the SAME Google service-account credential already configured for
// push notifications (see supabase/functions/send-push) - same Firebase
// project, just a different OAuth scope (Firestore instead of FCM), so no
// new Firebase-side setup is needed, only one new secret:
//   RAZORPAY_WEBHOOK_SECRET - from Razorpay Dashboard -> Settings -> Webhooks
//                             (set when creating the webhook pointing here)
//
// Requires the client (WalletPage._pay) to attach `notes: {uid, credits,
// label}` to the Razorpay checkout options - that's how this function knows
// WHO to credit and HOW MUCH, since it never talks to the app directly.

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, x-razorpay-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function toHex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function verifySignature(rawBody: string, signature: string, secret: string): Promise<boolean> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const mac = await crypto.subtle.sign('HMAC', key, enc.encode(rawBody));
  const expected = toHex(mac);
  // Signatures are fixed-length hex - safe to length-check before a
  // constant-time-ish compare (Deno has no built-in timingSafeEqual here).
  if (expected.length !== signature.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  return diff === 0;
}

function pemToDer(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const raw = atob(b64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes;
}

function base64url(bytes: Uint8Array): string {
  let str = btoa(String.fromCharCode(...bytes));
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// Same JWT-bearer flow as send-push, just scoped to Firestore instead of
// FCM - a Google service account can mint a token for whichever API's
// scope it asks for with the same underlying credential.
async function getAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const enc = new TextEncoder();
  const signingInput =
    base64url(enc.encode(JSON.stringify(header))) + '.' + base64url(enc.encode(JSON.stringify(claims)));

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(privateKeyPem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(signingInput));
  const jwt = signingInput + '.' + base64url(new Uint8Array(signature));

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=${encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')}&assertion=${jwt}`,
  });
  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  return json.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });

  try {
    const rawBody = await req.text();
    const signature = req.headers.get('x-razorpay-signature') ?? '';
    const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET');
    if (!webhookSecret) {
      return new Response(JSON.stringify({ error: 'RAZORPAY_WEBHOOK_SECRET not configured' }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const validSignature = await verifySignature(rawBody, signature, webhookSecret);
    if (!validSignature) {
      // Wrong/missing signature - either a misconfigured webhook secret or
      // someone trying to fake a payment. Never proceed past this point.
      return new Response(JSON.stringify({ error: 'invalid signature' }), {
        status: 400,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const body = JSON.parse(rawBody);
    if (body.event !== 'payment.captured') {
      // Not an event we act on (e.g. payment.failed, order.paid) - 200 so
      // Razorpay doesn't keep retrying delivery of something we're
      // intentionally ignoring.
      return new Response(JSON.stringify({ ok: true, ignored: body.event }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const payment = body.payload?.payment?.entity;
    const uid = payment?.notes?.uid as string | undefined;
    const label = (payment?.notes?.label as string | undefined) ?? 'Credit purchase';
    const paymentId = payment?.id as string | undefined;
    // `amount` is in paise and, unlike `notes`, is set by Razorpay itself
    // from what was actually captured - the client can't forge it. Credits
    // are computed from THIS, not from notes.credits, so a tampered app
    // build can no longer claim more credits than it actually paid for.
    // CREDITS_PER_RUPEE must match CreditService.creditsPerRupee in the app.
    const CREDITS_PER_RUPEE = 1;
    const amountPaise = payment?.amount as number | undefined;
    const credits = typeof amountPaise === 'number' ? Math.floor((amountPaise / 100) * CREDITS_PER_RUPEE) : NaN;

    if (!uid || !paymentId || !Number.isFinite(credits) || credits <= 0) {
      // Malformed notes/amount - nothing sane to credit. Don't retry forever.
      return new Response(JSON.stringify({ error: 'missing uid/amount/paymentId on payment' }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY');
    if (!projectId || !clientEmail || !privateKey) {
      return new Response(JSON.stringify({ error: 'Google service account secrets not configured' }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const accessToken = await getAccessToken(clientEmail, privateKey);
    const base = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

    // Idempotency guard: create the transaction doc keyed by Razorpay's own
    // payment id FIRST. Razorpay retries webhook delivery on anything but a
    // clean 2xx, so this same event can legitimately arrive more than once -
    // a second attempt hits 409 ALREADY_EXISTS here and we stop before ever
    // touching the credits balance, so a retried delivery can never
    // double-credit.
    const createTxnRes = await fetch(
      `${base}/users/${uid}/transactions?documentId=${encodeURIComponent(paymentId)}`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fields: {
            type: { stringValue: 'purchase' },
            delta: { integerValue: String(credits) },
            label: { stringValue: label },
            createdAt: { timestampValue: new Date().toISOString() },
          },
        }),
      },
    );

    if (createTxnRes.status === 409) {
      return new Response(JSON.stringify({ ok: true, duplicate: true }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }
    if (!createTxnRes.ok) {
      throw new Error(`transaction write failed: ${createTxnRes.status} ${await createTxnRes.text()}`);
    }

    // Only now, having durably recorded that we're crediting this payment
    // exactly once, apply the actual balance change.
    const commitRes = await fetch(`${base}:commit`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        writes: [
          {
            transform: {
              document: `projects/${projectId}/databases/(default)/documents/users/${uid}`,
              fieldTransforms: [{ fieldPath: 'credits', increment: { integerValue: String(credits) } }],
            },
          },
        ],
      }),
    });
    if (!commitRes.ok) {
      throw new Error(`credit increment failed: ${commitRes.status} ${await commitRes.text()}`);
    }

    return new Response(JSON.stringify({ ok: true, credited: credits }), {
      status: 200,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    // Non-2xx so Razorpay retries - this branch means something on our end
    // went wrong (network blip, token exchange failure, etc.), not a bad
    // request, so a retry is the right response.
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }
});
