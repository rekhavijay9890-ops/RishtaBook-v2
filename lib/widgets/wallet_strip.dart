import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../i18n/strings.dart';
import '../services/credit_service.dart';

class WalletStrip extends StatelessWidget {
  final int credits;
  final VoidCallback onTap;

  const WalletStrip({super.key, required this.credits, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.safDark, AppColors.saffron], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('👛', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$credits Credits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(
                  context.t('home.wallet.remaining', [credits ~/ CreditService.chatUnlockCost]),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(context.t('home.addCredits'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
