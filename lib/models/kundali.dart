/// One row of the 8-koot (Ashtakoot) Guna Milan breakdown.
class KootResult {
  final String name;
  final int score;
  final int max;
  const KootResult(this.name, this.score, this.max);
}

class GunaMilanResult {
  final List<KootResult> koots;
  final bool manglikClash;

  const GunaMilanResult(this.koots, {this.manglikClash = false});

  int get total => koots.fold(0, (a, k) => a + k.score);
  int get maxTotal => koots.fold(0, (a, k) => a + k.max);
}
