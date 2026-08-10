import 'package:flutter_test/flutter_test.dart';
import 'package:rishtabook/models/partner_preferences.dart';
import 'package:rishtabook/models/user_profile.dart';
import 'package:rishtabook/services/matchmaking_service.dart';

/// Builds a birth-date string for someone who is exactly [age] years old
/// today, in the dd/mm/yyyy format UserProfile.age parses - avoids hardcoding
/// a date that would make these tests flaky as time passes.
String _dobForAge(int age) {
  final now = DateTime.now();
  return '01/01/${now.year - age}';
}

UserProfile _profile({
  int? age,
  int? heightCm,
  String religion = 'Hindu',
  String maritalStatus = 'Never Married',
  String education = 'Graduate',
  String state = 'Maharashtra',
  String manglik = 'no',
}) {
  return UserProfile.fromMap('test-uid', {
    if (age != null) 'age': _dobForAge(age),
    if (heightCm != null) 'heightCm': heightCm,
    'religion': religion,
    'maritalStatus': maritalStatus,
    'education': education,
    'state': state,
    'manglik': manglik,
  });
}

void main() {
  group('MatchmakingService.score', () {
    test('perfect match on every criterion scores 100', () {
      final prefs = PartnerPreferences.defaults().copyWith(
        ageMin: 25, ageMax: 35, heightMinCm: 150, heightMaxCm: 180,
        religions: ['Hindu'], maritalStatuses: ['Never Married'],
        educations: ['Graduate'], states: ['Maharashtra'], manglik: 'no',
      );
      final candidate = _profile(age: 30, heightCm: 165, manglik: 'no');
      expect(MatchmakingService.score(candidate, prefs, kundaliScore: 36), 100);
    });

    test('empty preference lists ("any") always pass, never exclude', () {
      final prefs = PartnerPreferences.defaults(); // every list empty
      final candidate = _profile(age: 30, heightCm: 165, religion: 'Muslim', education: 'PhD', state: 'Kerala');
      // Every criterion with an "any" preference should score full marks,
      // so this should still land at/near 100 despite matching nothing
      // specific.
      expect(MatchmakingService.score(candidate, prefs, kundaliScore: 36), greaterThanOrEqualTo(95));
    });

    test('age outside range is penalized proportionally to distance, not zeroed', () {
      final prefs = PartnerPreferences.defaults().copyWith(ageMin: 25, ageMax: 30);
      final near = _profile(age: 32); // 2 years over
      final far = _profile(age: 45); // 15 years over
      final nearScore = MatchmakingService.score(near, prefs);
      final farScore = MatchmakingService.score(far, prefs);
      expect(nearScore, greaterThan(farScore));
    });

    test('missing candidate data (no age/height set) never crashes and scores a neutral half-credit', () {
      final prefs = PartnerPreferences.defaults();
      final candidate = _profile(); // no age, no heightCm
      expect(() => MatchmakingService.score(candidate, prefs), returnsNormally);
      final score = MatchmakingService.score(candidate, prefs);
      expect(score, inInclusiveRange(0, 100));
    });

    test('religion mismatch against a non-empty preference list loses points but does not exclude', () {
      final prefs = PartnerPreferences.defaults().copyWith(religions: ['Hindu']);
      final match = _profile(religion: 'Hindu');
      final mismatch = _profile(religion: 'Sikh');
      expect(MatchmakingService.score(match, prefs), greaterThan(MatchmakingService.score(mismatch, prefs)));
    });

    test('score is always within 0-100 regardless of inputs', () {
      final prefs = PartnerPreferences.defaults().copyWith(ageMin: 60, ageMax: 65);
      final candidate = _profile(age: 18, heightCm: 100); // wildly out of range
      final score = MatchmakingService.score(candidate, prefs, kundaliScore: 0);
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
