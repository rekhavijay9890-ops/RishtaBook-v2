import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

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
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _StatTile(stat: stats[i])),
        ],
      ],
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
        child: Column(children: [
          Text(stat.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.saffron)),
          const SizedBox(height: 2),
          Text(stat.label, textAlign: TextAlign.center, style: AppText.label),
        ]),
      ),
    );
  }
}
