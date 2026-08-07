import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A row of small stat tiles (value + label) used to open Home and Wallet
/// in a "dashboard" style - your own numbers before the browsing feed.
/// Every value passed in must be real data already tracked elsewhere in
/// the app (credits, interests received, unread chats, boost status) -
/// no invented metrics.
class RbStatStrip extends StatelessWidget {
  final List<RbStat> stats;
  const RbStatStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [for (final s in stats) _StatTile(stat: s)],
    );
  }
}

class RbStat {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const RbStat({required this.value, required this.label, this.onTap});
}

class _StatTile extends StatelessWidget {
  final RbStat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: stat.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(stat.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.saffron)),
          const SizedBox(height: 4),
          Text(stat.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.ghost)),
        ]),
      ),
    );
  }
}
