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
}
