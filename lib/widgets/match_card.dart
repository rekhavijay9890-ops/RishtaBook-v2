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
  final int? matchScorePct;
  final bool blurred;
  final bool boosted;
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
    this.matchScorePct,
    this.blurred = false,
    this.boosted = false,
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
          Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                // The heart/chat buttons used to sit INSIDE this same
                // InkWell's subtree (wrapping the whole Row) - taps on them
                // were getting captured by this InkWell's onOpen instead of
                // their own GestureDetectors, since Flutter's tap arena can
                // resolve to either recognizer when one is nested directly
                // inside the other. Restructured so onOpen's InkWell only
                // wraps the avatar/name area, and the icon buttons are a
                // sibling entirely outside its hit-test subtree - no more
                // ambiguity about which handler a tap on them reaches.
                Expanded(
                  child: InkWell(
                    onTap: widget.onOpen,
                    child: Row(
                      children: [
                        RbAvatar(initials: widget.initials, size: 52, color: widget.accentColor, photoUrl: widget.photoUrl, blurred: widget.blurred),
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
                      ],
                    ),
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
          Container(
            color: const Color(0xFFFDFAFC),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.boosted) RbBadge(text: '🚀 ${context.t('wallet.boostBadge')}', color: AppColors.rose),
                if (widget.matchScorePct != null)
                  RbBadge(text: context.t('match.scoreLabel', ['${widget.matchScorePct}']), color: AppColors.saffron),
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
      behavior: HitTestBehavior.opaque,
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
