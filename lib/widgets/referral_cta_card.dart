import 'package:flutter/material.dart';

import '../services/credit_service.dart';
import '../i18n/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Promo card for the referral flow — drop this into any screen (Home,
/// Profile, ...) to surface "Invite & Earn" without duplicating the copy
/// or the current (admin-configurable) bonus amount lookup.
class ReferralCtaCard extends StatelessWidget {
  const ReferralCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/referral'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.roseLight, AppColors.safLight], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.saffron.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Text('🎁', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('referral.ctaTitle'), style: AppText.headingSmall),
              const SizedBox(height: 2),
              FutureBuilder<int>(
                future: CreditService().getReferralBonusAmount(),
                builder: (context, snap) => Text(
                  context.t('referral.ctaDesc', [snap.data ?? CreditService.referralBonus]),
                  style: AppText.caption,
                ),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.saffron, AppColors.safDark]), borderRadius: BorderRadius.circular(100)),
            child: Text(context.t('referral.ctaButton'), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
