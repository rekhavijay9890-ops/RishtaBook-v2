/// App-wide constants.
///
/// [adminEmails] controls who sees the Admin tab (verification review
/// queue). Log in with one of these email addresses to get admin
/// access - there's no separate admin app, it's the same login screen.
class AppConfig {
  AppConfig._();

  static const List<String> adminEmails = [
    "admin@rishtabook.online", // TODO: replace with your real admin email(s)
  ];

  static bool isAdmin(String? email) =>
      email != null && adminEmails.contains(email.toLowerCase());

  /// Razorpay TEST MODE key id — safe to ship in the client (it's not a
  /// secret, unlike the Key Secret, which must never appear here). See
  /// CreditService's class doc — crediting on the success callback still
  /// needs server-side signature verification before this goes anywhere
  /// near real money. Switch to a live key only once ready to charge real
  /// cards, and only after that server-side verification exists.
  static const String razorpayKeyId = "rzp_test_TKnAAwgRET7i6X";

  /// TODO: replace with your own AdMob rewarded ad unit id once you have an
  /// AdMob account — this is Google's public TEST rewarded ad unit id, safe
  /// to ship as-is (it always fills with a real, working Google test ad,
  /// it just never pays out real revenue). The matching test APPLICATION_ID
  /// is set in android/app/src/main/AndroidManifest.xml — replace both
  /// together, they're a pair.
  static const String admobRewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917";

  /// Supabase Storage only — Auth and the database stay on Firebase. This
  /// is a single-purpose swap because Firebase Storage requires the Blaze
  /// billing plan to even provision a bucket, which was blocked on the
  /// project owner's end. The anon key is meant to be public/client-side
  /// (Supabase's equivalent of a Firebase apiKey) — it has no access
  /// beyond what the storage bucket's own policies allow.
  static const String supabaseUrl = "https://sozqfervnjsdzmfyzvyj.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvenFmZXJ2bmpzZHptZnl6dnlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMDQxNjgsImV4cCI6MjEwMTY4MDE2OH0.3frmPMnXQYsc-9zRKIYEd6k-jqSw7iQLwzaKtObPAE4";
  static const String supabasePhotosBucket = "profile-photos";
}
