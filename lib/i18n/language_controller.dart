import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { hindi, english }

/// App-wide language toggle (Hindi / English), persisted locally.
/// Toggled from the Home screen header; every screen reads through
/// [LanguageController] via `context.watch` so a flip rebuilds instantly.
class LanguageController extends ChangeNotifier {
  static const _prefKey = 'rb_language';

  AppLanguage _language = AppLanguage.hindi;
  AppLanguage get language => _language;
  bool get isHindi => _language == AppLanguage.hindi;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'english') _language = AppLanguage.english;
    notifyListeners();
  }

  Future<void> toggle() async {
    _language = _language == AppLanguage.hindi ? AppLanguage.english : AppLanguage.hindi;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _language == AppLanguage.english ? 'english' : 'hindi');
  }
}
