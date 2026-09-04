import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/success_story_service.dart';
import '../theme/app_colors.dart';
import '../i18n/strings.dart';
import 'rb_section_label.dart';

/// Home section for admin-curated "Success Stories" - social proof that
/// real couples met through the app. Renders nothing at all (label
/// included) while empty, so a fresh install with no stories yet doesn't
/// show a dangling empty section.
class SuccessStoriesSection extends StatelessWidget {
  const SuccessStoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SuccessStoryService().storiesStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RbSectionLabel(title: context.t('home.successStories')),
            const SizedBox(height: 4),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  return _StoryCard(
                    names: data['names'] as String? ?? '',
                    quote: data['quote'] as String? ?? '',
                    weddingDate: data['weddingDate'] as String? ?? '',
                    photoUrl: data['photoUrl'] as String? ?? '',
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String names;
  final String quote;
  final String weddingDate;
  final String photoUrl;
  const _StoryCard({required this.names, required this.quote, required this.weddingDate, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.saffron.withOpacity(0.12),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty ? const Text('💍', style: TextStyle(fontSize: 16)) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(names, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              if (weddingDate.isNotEmpty)
                Text(weddingDate, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            '"$quote"',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontStyle: FontStyle.italic),
          ),
        ),
      ]),
    );
  }
}
