import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../i18n/strings.dart';
import '../utils/portrait.dart';

/// Horizontal-scroll strip of the top-ranked matches, shown above the full
/// list on a "dashboard-first" Home page - the same ranked [entries] the
/// full list below uses, just the first few in richer photo-forward cards.
class TopMatchesCarousel extends StatelessWidget {
  final List<TopMatchEntry> entries;
  const TopMatchesCarousel({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 248,
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
  final VoidCallback? onSend;
  const TopMatchEntry({
    required this.profile,
    required this.matchScorePct,
    required this.blurred,
    required this.onTap,
    this.onSend,
  });
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
        width: 176,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            SizedBox(
              height: 124,
              width: double.infinity,
              child: Image.network(
                Portrait.urlFor(p),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: color.withOpacity(0.2)),
              ),
            ),
            Positioned(
              left: 8, bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                child: Text('${entry.matchScorePct}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
            if (p.isVerified)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.saffron, borderRadius: BorderRadius.circular(100)),
                  child: Text(context.t('common.verified'), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('${entry.matchScorePct}% ${context.t('match.title')}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: entry.onTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: AppColors.saffron, width: 1.2),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 10.5)),
                  ),
                ),
                if (entry.onSend != null) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34, height: 30,
                    child: ElevatedButton(
                      onPressed: entry.onSend,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffron, padding: EdgeInsets.zero),
                      child: const Text('💌', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
