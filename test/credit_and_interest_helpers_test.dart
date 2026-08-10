import 'package:flutter_test/flutter_test.dart';
import 'package:rishtabook/services/credit_service.dart';
import 'package:rishtabook/services/interest_service.dart';

void main() {
  group('InterestService.matchIdFor', () {
    test('is order-independent - the same pair always maps to the same doc id', () {
      expect(InterestService.matchIdFor('alice', 'bob'), InterestService.matchIdFor('bob', 'alice'));
    });

    test('different pairs never collide', () {
      expect(InterestService.matchIdFor('alice', 'bob'), isNot(InterestService.matchIdFor('alice', 'carol')));
    });

    test('is deterministic (sorted uids joined by underscore)', () {
      expect(InterestService.matchIdFor('zed', 'amy'), 'amy_zed');
    });
  });

  group('CreditService.normalizePhone', () {
    test('strips spaces, dashes, and a +91 country code prefix symbol down to digits only', () {
      expect(CreditService.normalizePhone('+91 98765-43210'), '919876543210');
      expect(CreditService.normalizePhone('9876543210'), '9876543210');
    });

    test('produces an empty string for input with no digits at all', () {
      expect(CreditService.normalizePhone('abc'), '');
    });
  });

  group('CreditService.generateReferralCode', () {
    test('always starts with RB and is 8 characters total', () {
      final code = CreditService.generateReferralCode();
      expect(code, startsWith('RB'));
      expect(code.length, 8);
    });

    test('never contains visually-ambiguous characters (0/O/1/I)', () {
      // Generate a good sample rather than relying on one random draw.
      for (var i = 0; i < 200; i++) {
        final code = CreditService.generateReferralCode();
        expect(code.contains(RegExp('[01OI]')), isFalse, reason: code);
      }
    });
  });
}
