import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import 'rb_avatar.dart';

/// Horizontal-scroll strip of the top-ranked matches, shown above the full
/// list on a "dashboard-first" Home page - the same ranked [entries] the
/// full list below uses, just the first few in compact card form.
class TopMatchesCarousel extends StatelessWidget {
  final List<TopMatchEntry> entries;
  const TopMatchesCarousel({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _TopMatchTile(entry: entries[i]),
      ),
    );
  }
}

class TopMatchEntry {
  final UserProfile profile;
  final int matchScorePct;
  final bool blurred;
  final VoidCallback onTap;
  const TopMatchEntry({required this.profile, required this.matchScorePct, required this.blurred, required this.onTap});
}

class _TopMatchTile extends StatelessWidget {
  final TopMatchEntry entry;
  const _TopMatchTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final p = entry.profile;
    final color = p.isFemale ? AppColors.rose : (p.isMale ? AppColors.teal : AppColors.saffron);
    return GestureDetector(
      onTap: entry.onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(children: [
          RbAvatar(
            initials: p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
            size: 40,
            color: color,
            photoUrl: p.primaryPhotoUrl,
            blurred: entry.blurred,
          ),
          const SizedBox(height: 6),
          Text(p.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text('${entry.matchScorePct}%', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron)),
        ]),
      ),
    );
  }
}
