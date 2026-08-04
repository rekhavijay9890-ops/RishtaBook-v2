import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/app_config.dart';
import '../../models/credit_pack.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/rb_section_label.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int? _selected;
  late final Razorpay _razorpay;
  final CreditService _creditService = CreditService();
  final AuthService _authService = AuthService();

  bool _adLoading = false;
  int? _adsRemainingToday;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    _refreshAdsRemaining();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _refreshAdsRemaining() async {
    final uid = _authService.currentUser?.uid ?? '';
    final remaining = await _creditService.adRewardsRemainingToday(uid);
    if (mounted) setState(() => _adsRemainingToday = remaining);
  }

  void _watchAdForCredits() {
    final remaining = _adsRemainingToday ?? 0;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.adLimitReached'))));
      return;
    }
    setState(() => _adLoading = true);
    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _adLoading = false);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.adFailed'))));
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) async {
            final uid = _authService.currentUser?.uid ?? '';
            final ok = await _creditService.grantAdReward(uid);
            await _refreshAdsRemaining();
            if (mounted && ok) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(context.t('wallet.adRewardEarned', [CreditService.adRewardAmount])), backgroundColor: AppColors.success));
            }
          });
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() => _adLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.adFailed'))));
        },
      ),
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_selected == null) return;
    final pack = CreditPack.all[_selected!];
    final uid = _authService.currentUser?.uid ?? '';
    // See CreditService.completePurchase's doc — this trusts the client
    // success callback; production needs a Cloud Function verifying the
    // Razorpay payment signature before granting credits.
    await _creditService.completePurchase(uid, credits: pack.credits, label: '${pack.priceLabel} pack');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentSuccess')), backgroundColor: AppColors.success));
      setState(() => _selected = null);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentFailed')), backgroundColor: AppColors.error));
  }

  void _pay(CreditPack pack) {
    final email = _authService.currentUser?.email ?? '';
    final options = {
      'key': AppConfig.razorpayKeyId,
      'amount': pack.priceInRupees * 100,
      'name': 'RishtaBook',
      'description': '${pack.credits} credits',
      'prefill': {'email': email},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentFailed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          Container(
            color: AppColors.headerBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(children: [
                  Row(children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
                    const SizedBox(width: 10),
                    Text(context.t('wallet.title'), style: AppText.headerTitle),
                  ]),
                  const SizedBox(height: 18),
                  Text(context.t('wallet.available'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ghost, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  StreamBuilder<int>(
                    stream: _creditService.creditsStream(uid),
                    builder: (context, snap) {
                      final credits = snap.data ?? 0;
                      return Column(children: [
                        Text('$credits', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
                        Text(context.t('wallet.remaining', [credits ~/ CreditService.chatUnlockCost]), style: const TextStyle(fontSize: 11, color: AppColors.ghost)),
                      ]);
                    },
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _creditService.transactionsStream(uid),
              builder: (context, txnSnap) {
                final txns = txnSnap.data?.docs ?? [];
                final chatsOpened = txns.where((d) => d.data()['type'] == 'chat_opened').length;
                final earned = txns.where((d) => d.data()['type'] == 'referral').fold<int>(0, (a, d) => a + ((d.data()['delta'] as num?)?.toInt() ?? 0));
                final bought = txns.where((d) => d.data()['type'] == 'purchase').fold<int>(0, (a, d) => a + ((d.data()['delta'] as num?)?.toInt() ?? 0));

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(children: [
                      _statTile('$chatsOpened', context.t('wallet.chatsOpened')),
                      _statTile('$earned', context.t('wallet.earned')),
                      _statTile('$bought', context.t('wallet.totalBought')),
                    ]),
                    const SizedBox(height: 18),
                    RbSectionLabel(title: context.t('wallet.buyCredits')),
                    ...CreditPack.all.asMap().entries.map((e) {
                      final i = e.key; final pack = e.value; final sel = _selected == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = i),
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.safLight : (pack.popular && _selected == null ? AppColors.goldLight : AppColors.cardBg),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sel ? AppColors.saffron : (pack.popular ? AppColors.gold : AppColors.borderColor), width: sel || pack.popular ? 2 : 1),
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${pack.credits} credits', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                const SizedBox(height: 2),
                                Text('${pack.credits ~/ CreditService.chatUnlockCost} chats', style: AppText.caption),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: sel ? [AppColors.saffron, AppColors.safDark] : (pack.popular ? [AppColors.gold, AppColors.saffron] : [AppColors.pageBg, AppColors.pageBg])),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: sel || pack.popular ? Colors.transparent : AppColors.borderColor),
                                ),
                                child: Text(pack.priceLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: sel || pack.popular ? Colors.white : AppColors.ink)),
                              ),
                            ]),
                          ),
                          if (pack.popular)
                            Positioned(
                              top: -9, left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gold, AppColors.saffron]), borderRadius: BorderRadius.circular(100)),
                                child: Text(context.t('wallet.mostPopular'), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                        ]),
                      );
                    }),
                    if (_selected != null) ...[
                      GestureDetector(
                        onTap: () => _pay(CreditPack.all[_selected!]),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.saffron, AppColors.safDark]), borderRadius: BorderRadius.circular(16)),
                          child: Text(context.t('wallet.payVia', [CreditPack.all[_selected!].priceLabel]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealLight, AppColors.safLight]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.teal.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Text('📺', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.t('wallet.watchAd'), style: AppText.headingSmall),
                          const SizedBox(height: 2),
                          Text(
                            context.t('wallet.watchAdDesc', [CreditService.adRewardAmount, _adsRemainingToday ?? CreditService.maxAdRewardsPerDay, CreditService.maxAdRewardsPerDay]),
                            style: AppText.caption,
                          ),
                        ])),
                        GestureDetector(
                          onTap: (_adLoading || (_adsRemainingToday ?? 1) <= 0) ? null : _watchAdForCredits,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: (_adsRemainingToday ?? 1) <= 0 ? AppColors.borderColor : AppColors.teal,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: _adLoading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(context.t('wallet.watchAdCta'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: (_adsRemainingToday ?? 1) <= 0 ? AppColors.muted : Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.roseLight, AppColors.safLight]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.saffron.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Text('👥', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.t('wallet.referTitle'), style: AppText.headingSmall),
                          const SizedBox(height: 2),
                          Text(context.t('wallet.referDesc', [CreditService.referralBonus]), style: AppText.caption),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    RbSectionLabel(title: context.t('wallet.history')),
                    if (txns.isEmpty)
                      Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(context.t('wallet.noHistory'), style: AppText.caption)))
                    else
                      Container(
                        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
                        clipBehavior: Clip.hardEdge,
                        child: Column(children: txns.asMap().entries.map((e) {
                          final data = e.value.data();
                          final delta = (data['delta'] as num?)?.toInt() ?? 0;
                          final pos = delta > 0;
                          final type = data['type'] as String? ?? '';
                          final label = switch (type) {
                            'chat_opened' => context.t('wallet.txn.chatOpened'),
                            'referral' => context.t('wallet.txn.referral'),
                            'purchase' => context.t('wallet.txn.purchase'),
                            'signup_bonus' => context.t('wallet.txn.signupBonus'),
                            'ad_reward' => context.t('wallet.txn.adReward'),
                            'profile_unlocked' => context.t('search.unlock'),
                            _ => type,
                          };
                          return Column(children: [
                            if (e.key > 0) const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(children: [
                                Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: pos ? AppColors.tealLight : AppColors.roseLight),
                                    child: Center(child: Text(pos ? '💰' : '💬', style: const TextStyle(fontSize: 14)))),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                  const SizedBox(height: 1),
                                  Text('${data['label'] ?? ''}', style: AppText.caption),
                                ])),
                                Text('${pos ? '+' : ''}$delta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pos ? AppColors.teal : AppColors.rose)),
                              ]),
                            ),
                          ]);
                        }).toList()),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String n, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderColor)),
          child: Column(children: [
            Text(n, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(l, textAlign: TextAlign.center, style: AppText.label),
          ]),
        ),
      );
}
