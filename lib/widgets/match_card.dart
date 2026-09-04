import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../i18n/strings.dart';
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: AppColors.saffron.withOpacity(0.08), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onOpen,
              child: SizedBox(
                width: 118,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                        ? Image.network(
                            widget.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackPhoto(),
                          )
                        : _fallbackPhoto(),
                    if (widget.blurred)
                      Container(color: Colors.black26, child: const Icon(Icons.lock_outline, color: Colors.white)),
                    if (widget.matchScorePct != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                          child: Text('${widget.matchScorePct}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: widget.onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name, style: AppText.headingLarge, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${widget.job} · ${widget.city}', style: AppText.bodySmall, overflow: TextOverflow.ellipsis),
                          Text(widget.caste, style: AppText.caption, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (widget.boosted) RbBadge(text: '🚀 ${context.t('wallet.boostBadge')}', color: AppColors.rose),
                        if (widget.kundaliScore != null)
                          GestureDetector(
                            onTap: widget.onKundali,
                            child: RbBadge(text: '⭐ ${widget.kundaliScore}/36', color: AppColors.gold),
                          ),
                        if (widget.verified) RbBadge(text: context.t('common.verified'), color: AppColors.teal),
                        if (widget.premium) RbBadge(text: context.t('common.premium'), color: AppColors.gold),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onLike,
                            child: Container(
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.liked ? AppColors.roseLight : AppColors.safLight,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(widget.liked ? '❤️ ${context.t('common.sent')}' : '🤍 ${context.t('common.sendInterest')}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onChat,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealLight),
                            child: const Center(child: Text('💬', style: TextStyle(fontSize: 14))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPhoto() {
    return Container(
      color: AppColors.safLight,
      alignment: Alignment.center,
      child: Text(widget.initials, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: widget.accentColor)),
    );
  }
}
