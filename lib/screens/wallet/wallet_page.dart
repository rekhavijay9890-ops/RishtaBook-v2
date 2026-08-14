import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/app_config.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/profile_service.dart';
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
  late final Razorpay _razorpay;
  final CreditService _creditService = CreditService();
  final AuthService _authService = AuthService();

  final ProfileService _profileService = ProfileService();
  bool _adLoading = false;
  bool _boosting = false;
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

  Future<void> _boost() async {
    setState(() => _boosting = true);
    final uid = _authService.currentUser?.uid ?? '';
    final ok = await _creditService.boostProfile(uid);
    if (mounted) {
      setState(() => _boosting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? context.t('wallet.boostSuccess') : context.t('chat.insufficientCredits')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
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

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    // Credits are NOT granted here - see supabase/functions/razorpay-webhook
    // and CreditService's class doc. This callback just confirms the
    // checkout UI closed successfully; the actual grant comes from
    // Razorpay's own server-to-server webhook once it independently
    // verifies the payment, which the creditsStream/transactionsStream
    // StreamBuilders below will reflect the moment it lands (typically a
    // few seconds).
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentSuccess')), backgroundColor: AppColors.success));
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentFailed')), backgroundColor: AppColors.error));
  }

  void _pay(int amountRupees) {
    final uid = _authService.currentUser?.uid ?? '';
    final email = _authService.currentUser?.email ?? '';
    final credits = amountRupees * CreditService.creditsPerRupee;
    final options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountRupees * 100,
      'name': 'RishtaBook',
      'description': '$credits credits',
      'prefill': {'email': email},
      // Read by supabase/functions/razorpay-webhook once Razorpay confirms
      // this payment - it's the only way that server-side function knows
      // who to credit, since it never talks to this app directly. Razorpay
      // echoes `notes` back verbatim on every payment object, including in
      // the webhook payload. The webhook does NOT trust `notes.credits` for
      // the actual amount to grant, though (a tampered client build could
      // lie about it) - it independently recomputes credits from Razorpay's
      // own verified `payment.amount` using the same CreditService.
      // creditsPerRupee rate. `notes.credits` here is only for the
      // transaction ledger's display label.
      'notes': {'uid': uid, 'credits': '$credits', 'label': '₹$amountRupees top-up'},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('wallet.paymentFailed'))));
    }
  }

  void _showAddMoneySheet() {
    final controller = TextEditingController();
    const quickAmounts = [50, 100, 200, 500];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final amount = int.tryParse(controller.text) ?? 0;
            final credits = amount * CreditService.creditsPerRupee;
            final valid = amount >= CreditService.minTopUpRupees;
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.pageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(100)))),
                const SizedBox(height: 16),
                RbSectionLabel(title: context.t('wallet.addMoney')),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSheetState(() {}),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
                    hintText: '0',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.saffron, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: quickAmounts.map((amt) {
                    final sel = amount == amt;
                    return GestureDetector(
                      onTap: () {
                        controller.text = '$amt';
                        setSheetState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.safLight : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: sel ? AppColors.saffron : AppColors.borderColor, width: sel ? 2 : 1),
                        ),
                        child: Text('₹$amt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? AppColors.safDark : AppColors.ink)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (amount > 0) ...[
                  Text(context.t('wallet.creditsPreview', [credits, credits ~/ CreditService.chatUnlockCost]), style: AppText.headingSmall),
                  const SizedBox(height: 4),
                ],
                Text(context.t('wallet.creditRate', [CreditService.chatUnlockCost]), style: AppText.caption),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: valid
                      ? () {
                          Navigator.pop(sheetContext);
                          _pay(amount);
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: valid ? const LinearGradient(colors: [AppColors.saffron, AppColors.safDark]) : null,
                      color: valid ? null : AppColors.borderColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      valid ? context.t('wallet.payVia', ['₹$amount']) : context.t('wallet.minTopUp', [CreditService.minTopUpRupees]),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valid ? Colors.white : AppColors.muted),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
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
                  Text(context.t('wallet.available'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  StreamBuilder<int>(
                    stream: _creditService.creditsStream(uid),
                    builder: (context, snap) {
                      final credits = snap.data ?? 0;
                      return Column(children: [
                        Text('$credits', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
                        Text(context.t('wallet.remaining', [credits ~/ CreditService.chatUnlockCost]), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ]);
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showAddMoneySheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                      child: Text(context.t('wallet.addMoney'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.safDark)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _creditService.transactionsStream(uid),
              builder: (context, txnSnap) {
                final txns = txnSnap.data?.docs ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  children: [
                    // Lifetime totals need the FULL transaction history, not
                    // just the recent page fetched for the list below - see
                    // CreditService.allTransactionsStream's doc comment.
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _creditService.allTransactionsStream(uid),
                      builder: (context, allTxnSnap) {
                        final allTxns = allTxnSnap.data?.docs ?? [];
                        final chatsOpened = allTxns.where((d) => d.data()['type'] == 'chat_opened').length;
                        final earned = allTxns.where((d) => d.data()['type'] == 'referral').fold<int>(0, (a, d) => a + ((d.data()['delta'] as num?)?.toInt() ?? 0));
                        final bought = allTxns.where((d) => d.data()['type'] == 'purchase').fold<int>(0, (a, d) => a + ((d.data()['delta'] as num?)?.toInt() ?? 0));
                        return Row(children: [
                          _statTile('$chatsOpened', context.t('wallet.chatsOpened')),
                          _statTile('$earned', context.t('wallet.earned')),
                          _statTile('$bought', context.t('wallet.totalBought')),
                        ]);
                      },
                    ),
                    const SizedBox(height: 18),
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
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _profileService.userProfileStream(uid),
                      builder: (context, meSnap) {
                        final me = meSnap.data?.data() != null ? UserProfile.fromMap(uid, meSnap.data!.data()!) : null;
                        final boosted = me?.isBoosted ?? false;
                        final boostedUntil = me?.boostedUntil;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFE0E9), AppColors.safLight]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.rose.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            const Text('🚀', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(context.t('wallet.boostTitle'), style: AppText.headingSmall),
                              const SizedBox(height: 2),
                              Text(
                                boosted && boostedUntil != null
                                    ? context.t('wallet.boostActiveUntil', [_formatBoostRemaining(context, boostedUntil)])
                                    : (boosted ? context.t('wallet.boostActive') : context.t('wallet.boostDesc', [CreditService.boostCost])),
                                style: AppText.caption,
                              ),
                            ])),
                            if (!boosted)
                              GestureDetector(
                                onTap: _boosting ? null : _boost,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(100)),
                                  child: _boosting
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(context.t('wallet.boostCta'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                          ]),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/referral'),
                      child: Container(
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
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ]),
                      ),
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
          ),
        ],
      ),
    );
  }

  String _formatBoostRemaining(BuildContext context, DateTime until) {
    final remaining = until.difference(DateTime.now());
    if (remaining.inHours >= 1) {
      return context.isHindi ? '${remaining.inHours} घंटे बाकी' : '${remaining.inHours}h left';
    }
    final minutes = remaining.inMinutes.clamp(1, 59);
    return context.isHindi ? '$minutes मिनट बाकी' : '${minutes}m left';
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
