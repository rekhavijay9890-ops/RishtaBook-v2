import '../models/partner_preferences.dart';
import '../models/user_profile.dart';

/// Compatibility scoring between a candidate profile and the viewer's
/// stated partner preferences, 0-100. Weighted, deterministic, and
/// entirely client-side (matches the rest of this app's architecture -
/// there's no backend to run this server-side, and the candidate pool
/// per screen is already small since Home/Search bound their queries).
///
/// Design: criteria the viewer left unset ("any") always pass at full
/// weight rather than excluding candidates - this is a RANKING signal,
/// not a hard filter. A dedicated hard-filter search (by exact caste,
/// etc.) is Search's job; Home's "suggested for you" should still show
/// people even if every field isn't a perfect match, just ranked lower.
class MatchmakingService {
  MatchmakingService._();

  static const int _wAge = 25;
  static const int _wHeight = 15;
  static const int _wReligion = 20;
  static const int _wMaritalStatus = 10;
  static const int _wEducation = 10;
  static const int _wLocation = 10;
  static const int _wManglik = 5;
  static const int _wKundali = 5;
  static const int _maxScore =
      _wAge + _wHeight + _wReligion + _wMaritalStatus + _wEducation + _wLocation + _wManglik + _wKundali;

  /// [kundaliScore] is optional (0-36, from KundaliService) - pass it in
  /// when both profiles have rashi/nakshatra set, for a small bonus on
  /// top of the preference-based score.
  static int score(UserProfile candidate, PartnerPreferences prefs, {int? kundaliScore}) {
    var points = 0;

    final age = candidate.age;
    if (age == null) {
      points += (_wAge / 2).round();
    } else if (age >= prefs.ageMin && age <= prefs.ageMax) {
      points += _wAge;
    } else {
      final distance = age < prefs.ageMin ? prefs.ageMin - age : age - prefs.ageMax;
      points += (_wAge - distance * 3).clamp(0, _wAge);
    }

    final height = candidate.heightCm;
    if (height == null) {
      points += (_wHeight / 2).round();
    } else if (height >= prefs.heightMinCm && height <= prefs.heightMaxCm) {
      points += _wHeight;
    } else {
      points += (_wHeight * 0.3).round();
    }

    if (prefs.religions.isEmpty || prefs.religions.contains(candidate.religion)) {
      points += _wReligion;
    }

    if (prefs.maritalStatuses.isEmpty || prefs.maritalStatuses.contains(candidate.maritalStatus)) {
      points += _wMaritalStatus;
    }

    if (prefs.educations.isEmpty || prefs.educations.contains(candidate.education)) {
      points += _wEducation;
    }

    if (prefs.states.isEmpty || prefs.states.contains(candidate.state)) {
      points += _wLocation;
    }

    if (prefs.manglik == 'any' || candidate.manglik == prefs.manglik || candidate.manglik == 'unknown') {
      points += _wManglik;
    }

    if (kundaliScore != null) {
      points += ((kundaliScore / 36) * _wKundali).round();
    } else {
      points += (_wKundali / 2).round();
    }

    return ((points / _maxScore) * 100).round().clamp(0, 100);
  }
}
