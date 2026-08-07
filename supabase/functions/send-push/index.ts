// Supabase Edge Function: send-push
//
// Sends a single FCM push notification. Exists because Firebase Cloud
// Functions (the normal way to do this) require the Blaze billing plan,
// which is blocked on the project owner's Google account - this holds the
// same Google service-account credential Firebase Cloud Functions would
// use, just running on Supabase's free tier instead.
//
// Called from lib/services/push_service.dart with:
//   POST { token: "<fcm device token>", title: "...", body: "..." }
//   Authorization: Bearer <supabase anon key>
//
// Requires three secrets set once via the Supabase CLI (see the PR
// description this shipped in for the exact commands):
//   FCM_PROJECT_ID    - the Firebase project id (rishtabook-60663)
//   FCM_CLIENT_EMAIL  - client_email from the downloaded service account JSON
//   FCM_PRIVATE_KEY   - private_key from that same JSON, newlines intact
//
// Get that JSON from Firebase Console -> Project Settings -> Service
// accounts -> Generate new private key. Never commit it - it's a real
// secret, unlike the Firebase apiKey used elsewhere in this app.

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function base64url(bytes: Uint8Array): string {
  let str = btoa(String.fromCharCode(...bytes));
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
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

// Exchanges the service account credential for a short-lived OAuth2 access
// token scoped to FCM, via a self-signed JWT (the standard Google
// service-account "JWT bearer" flow) - no extra npm/deno dependency needed,
// just Web Crypto.
async function getAccessToken(clientEmail: string, privateKeyPem: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
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
    const { token, title, body } = await req.json();
    if (!token || !title || !body) {
      return new Response(JSON.stringify({ error: 'token, title, body are required' }), {
        status: 400,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const projectId = Deno.env.get('FCM_PROJECT_ID');
    const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const privateKey = Deno.env.get('FCM_PRIVATE_KEY');
    if (!projectId || !clientEmail || !privateKey) {
      return new Response(JSON.stringify({ error: 'FCM secrets not configured' }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const accessToken = await getAccessToken(clientEmail, privateKey);

    const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
        },
      }),
    });

    const fcmJson = await fcmRes.json();
    return new Response(JSON.stringify(fcmJson), {
      status: fcmRes.status,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
    });
  }
});
