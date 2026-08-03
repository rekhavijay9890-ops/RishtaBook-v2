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

  /// TODO: replace with your live/test Razorpay key id from the Razorpay
  /// dashboard. This id alone is safe to ship in the client (it's not a
  /// secret), but see CreditService's class doc — crediting on the
  /// success callback still needs server-side signature verification
  /// before this goes anywhere near real money.
  static const String razorpayKeyId = "rzp_test_1234567890abcd";
}
