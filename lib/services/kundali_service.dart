import '../models/kundali.dart';

/// Ashtakoot (8-koot) Guna Milan compatibility scoring.
///
/// This is a rule-based lookup implementation driven only by Rashi (moon
/// sign) and Nakshatra (birth star) — it does not compute planetary
/// positions from birth date/time/place, so it can't replace a real
/// panchang/ephemeris engine or a qualified astrologer. It exists to give
/// a deterministic, explainable score matching the standard published
/// koot tables, which is why the UI always pairs it with a disclaimer.
class KundaliService {
  KundaliService._();

  static const List<String> rashis = [
    'Mesh (Aries)', 'Vrishabha (Taurus)', 'Mithun (Gemini)', 'Kark (Cancer)',
    'Simha (Leo)', 'Kanya (Virgo)', 'Tula (Libra)', 'Vrishchik (Scorpio)',
    'Dhanu (Sagittarius)', 'Makar (Capricorn)', 'Kumbh (Aquarius)', 'Meen (Pisces)',
  ];

  static const List<String> nakshatras = [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
    'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni',
    'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha',
    'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta',
    'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
  ];

  // ── Per-rashi tables (index 0-based, matches `rashis` order) ──
  static const List<String> _lord = [
    'Mars', 'Venus', 'Mercury', 'Moon', 'Sun', 'Mercury',
    'Venus', 'Mars', 'Jupiter', 'Saturn', 'Saturn', 'Jupiter',
  ];
  static const List<int> _varnaRank = [
    // Brahmin=4, Kshatriya=3, Vaishya=2, Shudra=1
    3, 2, 1, 4, 3, 2, 1, 3, 3, 1, 1, 4,
  ];
  static const List<String> _vashya = [
    'Chatushpada', 'Chatushpada', 'Dwipad', 'Jalachar', 'Vanachar', 'Dwipad',
    'Dwipad', 'Keet', 'Chatushpada', 'Jalachar', 'Dwipad', 'Jalachar',
  ];

  // ── Per-nakshatra tables (index 0-based, matches `nakshatras` order) ──
  static const List<String> _gana = [
    'Deva', 'Manushya', 'Rakshasa', 'Manushya', 'Deva', 'Manushya',
    'Deva', 'Deva', 'Rakshasa', 'Rakshasa', 'Manushya', 'Manushya',
    'Deva', 'Rakshasa', 'Deva', 'Rakshasa', 'Deva', 'Rakshasa',
    'Rakshasa', 'Manushya', 'Manushya', 'Deva', 'Rakshasa',
    'Rakshasa', 'Manushya', 'Manushya', 'Deva',
  ];
  static const List<String> _yoni = [
    'Horse', 'Elephant', 'Sheep', 'Serpent', 'Serpent', 'Dog',
    'Cat', 'Sheep', 'Cat', 'Rat', 'Rat', 'Cow',
    'Buffalo', 'Tiger', 'Buffalo', 'Tiger', 'Deer', 'Deer',
    'Dog', 'Monkey', 'Mongoose', 'Monkey', 'Lion',
    'Horse', 'Lion', 'Cow', 'Elephant',
  ];
  static const List<String> _nadi = [
    'Aadi', 'Madhya', 'Antya', 'Antya', 'Madhya', 'Aadi',
    'Aadi', 'Madhya', 'Antya', 'Antya', 'Madhya', 'Aadi',
    'Aadi', 'Madhya', 'Antya', 'Antya', 'Madhya', 'Aadi',
    'Aadi', 'Madhya', 'Antya', 'Antya', 'Madhya', 'Aadi',
    'Aadi', 'Madhya', 'Madhya',
  ];

  static const Map<String, List<String>> _friends = {
    'Sun': ['Moon', 'Mars', 'Jupiter'],
    'Moon': ['Sun', 'Mercury'],
    'Mars': ['Sun', 'Moon', 'Jupiter'],
    'Mercury': ['Sun', 'Venus'],
    'Jupiter': ['Sun', 'Moon', 'Mars'],
    'Venus': ['Mercury', 'Saturn'],
    'Saturn': ['Mercury', 'Venus'],
  };
  static const Map<String, List<String>> _enemies = {
    'Sun': ['Venus', 'Saturn'],
    'Moon': [],
    'Mars': ['Mercury'],
    'Mercury': ['Moon'],
    'Jupiter': ['Mercury', 'Venus'],
    'Venus': ['Sun', 'Moon'],
    'Saturn': ['Sun', 'Moon', 'Mars'],
  };

  static const List<List<String>> _yoniEnemyPairs = [
    ['Horse', 'Buffalo'],
    ['Elephant', 'Lion'],
    ['Sheep', 'Monkey'],
    ['Serpent', 'Mongoose'],
    ['Dog', 'Deer'],
    ['Cat', 'Rat'],
    ['Cow', 'Tiger'],
  ];

  static int _varnaScore(String boyRashi, String girlRashi) {
    final b = _varnaRank[rashis.indexOf(boyRashi)];
    final g = _varnaRank[rashis.indexOf(girlRashi)];
    return b >= g ? 1 : 0;
  }

  static int _vashyaScore(String boyRashi, String girlRashi) {
    final b = _vashya[rashis.indexOf(boyRashi)];
    final g = _vashya[rashis.indexOf(girlRashi)];
    if (b == g) return 2;
    if (b == 'Vanachar' || g == 'Vanachar') return 0;
    return 1;
  }

  static int _taraScore(String boyNak, String girlNak) {
    final bi = nakshatras.indexOf(boyNak) + 1;
    final gi = nakshatras.indexOf(girlNak) + 1;
    int countFrom(int from, int to) => ((to - from + 27) % 27) + 1;
    // Groups counted in 9s; remainders 3,5,7 (0-indexed within the 9-cycle)
    // are the traditionally inauspicious ones.
    bool bad(int count) => (count % 9) == 3 || (count % 9) == 5 || (count % 9) == 7;
    final d1 = countFrom(gi, bi);
    final d2 = countFrom(bi, gi);
    final ok1 = !bad(d1);
    final ok2 = !bad(d2);
    if (ok1 && ok2) return 3;
    if (ok1 || ok2) return 2;
    return 0;
  }

  static int _yoniScore(String boyNak, String girlNak) {
    final b = _yoni[nakshatras.indexOf(boyNak)];
    final g = _yoni[nakshatras.indexOf(girlNak)];
    if (b == g) return 4;
    for (final pair in _yoniEnemyPairs) {
      if ((pair[0] == b && pair[1] == g) || (pair[1] == b && pair[0] == g)) return 0;
    }
    return 2;
  }

  static int _grahaMaitriScore(String boyRashi, String girlRashi) {
    final bl = _lord[rashis.indexOf(boyRashi)];
    final gl = _lord[rashis.indexOf(girlRashi)];
    if (bl == gl) return 5;
    final bToG = _friends[bl]!.contains(gl) ? 2 : (_enemies[bl]!.contains(gl) ? 0 : 1);
    final gToB = _friends[gl]!.contains(bl) ? 2 : (_enemies[gl]!.contains(bl) ? 0 : 1);
    final sum = bToG + gToB; // 0..4
    switch (sum) {
      case 4: return 5;
      case 3: return 4;
      case 2: return 3;
      case 1: return 1;
      default: return 0;
    }
  }

  static int _ganaScore(String boyNak, String girlNak) {
    final b = _gana[nakshatras.indexOf(boyNak)];
    final g = _gana[nakshatras.indexOf(girlNak)];
    const table = {
      'Deva':      {'Deva': 6, 'Manushya': 5, 'Rakshasa': 1},
      'Manushya':  {'Deva': 6, 'Manushya': 6, 'Rakshasa': 0},
      'Rakshasa':  {'Deva': 0, 'Manushya': 0, 'Rakshasa': 6},
    };
    return table[b]![g]!;
  }

  static int _bhakootScore(String boyRashi, String girlRashi) {
    final bi = rashis.indexOf(boyRashi) + 1;
    final gi = rashis.indexOf(girlRashi) + 1;
    final count = ((bi - gi + 12) % 12) + 1;
    const dosha = {2, 6, 8, 12};
    return dosha.contains(count) ? 0 : 7;
  }

  static int _nadiScore(String boyNak, String girlNak) {
    final b = _nadi[nakshatras.indexOf(boyNak)];
    final g = _nadi[nakshatras.indexOf(girlNak)];
    return b == g ? 0 : 8;
  }

  /// Computes the full 8-koot breakdown for a boy/girl pair. Rashi and
  /// Nakshatra must be exact values from [rashis] / [nakshatras].
  static GunaMilanResult compute({
    required String boyRashi,
    required String boyNakshatra,
    required String girlRashi,
    required String girlNakshatra,
  }) {
    final koots = [
      KootResult('Varna', _varnaScore(boyRashi, girlRashi), 1),
      KootResult('Vashya', _vashyaScore(boyRashi, girlRashi), 2),
      KootResult('Tara', _taraScore(boyNakshatra, girlNakshatra), 3),
      KootResult('Yoni', _yoniScore(boyNakshatra, girlNakshatra), 4),
      KootResult('Graha Maitri', _grahaMaitriScore(boyRashi, girlRashi), 5),
      KootResult('Gana', _ganaScore(boyNakshatra, girlNakshatra), 6),
      KootResult('Bhakoot', _bhakootScore(boyRashi, girlRashi), 7),
      KootResult('Nadi', _nadiScore(boyNakshatra, girlNakshatra), 8),
    ];
    return GunaMilanResult(koots);
  }
}
