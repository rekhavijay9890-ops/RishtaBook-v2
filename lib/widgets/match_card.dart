import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../i18n/strings.dart';
import 'rb_avatar.dart';
import 'rb_badge.dart';

class MatchCard extends StatefulWidget {
  final String name;
  final String dob;
  final String job;
  final String city;
  final String caste;
  final int? kundaliScore;
  final bool verified;
  final bool premium;
  final bool liked;
  final String initials;
  final String? photoUrl;
  final Color accentColor;
  final VoidCallback onLike;
  final VoidCallback onChat;
  final VoidCallback onKundali;
  final VoidCallback onOpen;

  const MatchCard({
    super.key,
    required this.name,
    required this.dob,
    required this.job,
    required this.city,
    required this.caste,
    this.kundaliScore,
    this.verified = false,
    this.premium = false,
    this.liked = false,
    required this.initials,
    this.photoUrl,
    this.accentColor = AppColors.saffron,
    required this.onLike,
    required this.onChat,
    required this.onKundali,
    required this.onOpen,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: widget.onOpen,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  RbAvatar(initials: widget.initials, size: 52, color: widget.accentColor, photoUrl: widget.photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.name}', style: AppText.headingMedium, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${widget.job} · ${widget.city}', style: AppText.bodySmall, overflow: TextOverflow.ellipsis),
                        Text(widget.caste, style: AppText.caption, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _iconBtn(icon: widget.liked ? '❤️' : '🤍', bg: widget.liked ? AppColors.roseLight : const Color(0xFFF5F0F4), onTap: widget.onLike),
                      const SizedBox(height: 7),
                      _iconBtn(icon: '💬', bg: AppColors.tealLight, onTap: widget.onChat),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFDFAFC),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.kundaliScore != null)
                  GestureDetector(
                    onTap: widget.onKundali,
                    child: RbBadge(text: '⭐ ${widget.kundaliScore}/36', color: AppColors.gold),
                  ),
                if (widget.verified) RbBadge(text: context.t('common.verified'), color: AppColors.teal),
                if (widget.premium) RbBadge(text: context.t('common.premium'), color: AppColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required String icon, required Color bg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
      ),
    );
  }
}
