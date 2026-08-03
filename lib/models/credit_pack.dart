/// A purchasable credit pack shown on the Wallet screen.
class CreditPack {
  final int credits;
  final int priceInRupees;
  final bool popular;

  const CreditPack({required this.credits, required this.priceInRupees, this.popular = false});

  String get priceLabel => '₹$priceInRupees';

  static const List<CreditPack> all = [
    CreditPack(credits: 50, priceInRupees: 49),
    CreditPack(credits: 150, priceInRupees: 99, popular: true),
    CreditPack(credits: 500, priceInRupees: 299),
  ];
}
