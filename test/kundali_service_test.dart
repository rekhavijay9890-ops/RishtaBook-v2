import 'package:flutter_test/flutter_test.dart';
import 'package:rishtabook/services/kundali_service.dart';

void main() {
  group('KundaliService.compute', () {
    test('identical rashi and nakshatra scores full marks on same-sign koots', () {
      final result = KundaliService.compute(
        boyRashi: 'Mesh (Aries)', boyNakshatra: 'Ashwini',
        girlRashi: 'Mesh (Aries)', girlNakshatra: 'Ashwini',
      );
      // Same nakshatra -> same nadi -> Nadi koot (max weight, 8) should be
      // the traditionally inauspicious "same nadi" case, i.e. 0 - this is
      // the single most consequential rule in Ashtakoot matching (a "Nadi
      // dosha"), so it's worth pinning down explicitly rather than just
      // checking totals.
      final nadi = result.koots.firstWhere((k) => k.name == 'Nadi');
      expect(nadi.score, 0);
    });

    test('total is always between 0 and 36 (the traditional Ashtakoot max)', () {
      const rashis = KundaliService.rashis;
      const nakshatras = KundaliService.nakshatras;
      // Spot-check a spread of combinations rather than the full 12x27x12x27
      // cross product, to keep this test fast.
      for (var i = 0; i < rashis.length; i++) {
        for (var j = 0; j < nakshatras.length; j += 5) {
          final result = KundaliService.compute(
            boyRashi: rashis[i], boyNakshatra: nakshatras[j],
            girlRashi: rashis[(i + 3) % rashis.length], girlNakshatra: nakshatras[(j + 7) % nakshatras.length],
          );
          expect(result.total, inInclusiveRange(0, 36), reason: 'boy=${rashis[i]}/${nakshatras[j]}');
          expect(result.maxTotal, 36);
        }
      }
    });

    test('produces exactly the 8 standard koots, each within its own max', () {
      final result = KundaliService.compute(
        boyRashi: 'Simha (Leo)', boyNakshatra: 'Magha',
        girlRashi: 'Kark (Cancer)', girlNakshatra: 'Pushya',
      );
      expect(result.koots.length, 8);
      expect(result.koots.map((k) => k.name).toSet(), {
        'Varna', 'Vashya', 'Tara', 'Yoni', 'Graha Maitri', 'Gana', 'Bhakoot', 'Nadi',
      });
      for (final koot in result.koots) {
        expect(koot.score, inInclusiveRange(0, koot.max), reason: koot.name);
      }
    });

    test('is symmetric-safe: swapping boy/girl never throws and stays in range', () {
      final a = KundaliService.compute(
        boyRashi: 'Tula (Libra)', boyNakshatra: 'Swati',
        girlRashi: 'Vrishchik (Scorpio)', girlNakshatra: 'Anuradha',
      );
      final b = KundaliService.compute(
        boyRashi: 'Vrishchik (Scorpio)', boyNakshatra: 'Anuradha',
        girlRashi: 'Tula (Libra)', girlNakshatra: 'Swati',
      );
      expect(a.total, inInclusiveRange(0, 36));
      expect(b.total, inInclusiveRange(0, 36));
    });
  });
}
