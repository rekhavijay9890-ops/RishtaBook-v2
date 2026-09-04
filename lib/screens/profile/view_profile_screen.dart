import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/moderation_service.dart';
import '../../i18n/strings.dart';
import '../../utils/portrait.dart';

const Color kBrandColor = AppColors.saffron;

/// Read-only, full-detail view of a profile - every field the person
/// filled in at signup (not just the shortened preview shown on the
/// Home tab card).
class ViewProfileScreen extends StatefulWidget {
  final UserProfile profile;
  /// Optional - passed by Home/Search, which have already computed these
  /// against the viewer's own preferences. Null when opened from a place
  /// that hasn't computed a score (e.g. straight from a chat thread).
  final int? matchScorePct;
  final int? kundaliScore;
  const ViewProfileScreen({super.key, required this.profile, this.matchScorePct, this.kundaliScore});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  UserProfile get profile => widget.profile;
  final _moderationService = ModerationService();

  @override
  void initState() {
    super.initState();
    _logView();
  }

  Future<void> _confirmBlock() async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('safety.block')),
        content: Text(context.t('safety.blockConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('safety.block')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _moderationService.blockUser(myUid, profile.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('safety.blocked')), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  void _openReportSheet() {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;
    String reason = 'fake_profile';
    final detailsCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.t('safety.reportTitle'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: reason,
              decoration: InputDecoration(hintText: context.t('safety.reportReasonHint')),
              items: [
                DropdownMenuItem(value: 'fake_profile', child: Text(context.t('safety.reason.fakeProfile'))),
                DropdownMenuItem(value: 'inappropriate', child: Text(context.t('safety.reason.inappropriate'))),
                DropdownMenuItem(value: 'harassment', child: Text(context.t('safety.reason.harassment'))),
                DropdownMenuItem(value: 'other', child: Text(context.t('safety.reason.other'))),
              ],
              onChanged: (v) => setSheetState(() => reason = v ?? 'fake_profile'),
            ),
            const SizedBox(height: 12),
            TextField(controller: detailsCtrl, maxLines: 3, decoration: InputDecoration(hintText: context.t('safety.reportDetailsHint'))),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                await _moderationService.fileReport(myUid, reportedUid: profile.uid, reason: reason, details: detailsCtrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('safety.reportSent')), backgroundColor: AppColors.success));
                }
              },
              child: Text(context.t('safety.reportSubmit')),
            ),
          ]),
        );
      }),
    );
  }

  /// Fire-and-forget: lets the viewed person know someone looked at their
  /// profile. Skipped for self-views and swallowed on any failure - a
  /// notification hiccup should never affect browsing.
  Future<void> _logView() async {
    try {
      final viewer = AuthService().currentUser;
      if (viewer == null || viewer.uid == profile.uid) return;
      final viewerDoc = await FirebaseFirestore.instance.collection('users').doc(viewer.uid).get();
      final viewerName = (viewerDoc.data()?['fullName'] as String?)?.trim();
      await NotificationService().notifyProfileViewed(
        profile.uid,
        viewerName: (viewerName?.isNotEmpty ?? false) ? viewerName! : 'Someone',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kBrandColor,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) => v == 'block' ? _confirmBlock() : _openReportSheet(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'report', child: Text(context.t('safety.report'))),
                  PopupMenuItem(value: 'block', child: Text(context.t('safety.block'))),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(Portrait.urlFor(profile), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kBrandColor)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
          Row(
            children: [
              Expanded(
                child: Text(profile.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
              if (profile.isVerified) const Icon(Icons.verified, color: kBrandColor, size: 22),
            ],
          ),
          if (profile.isFamilyManaged) ...[
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kBrandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  context.t('viewProfile.managedBy', [context.t('completeProfile.managedBy.${profile.managedBy}')]),
                  style: const TextStyle(fontSize: 11.5, color: kBrandColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          if (widget.matchScorePct != null || widget.kundaliScore != null || profile.isVerified) ...[
            const SizedBox(height: 16),
            Row(children: [
              if (widget.kundaliScore != null)
                Expanded(child: _StatCard(value: '${widget.kundaliScore}/36', label: context.t('kundali.title'))),
              if (widget.matchScorePct != null) ...[
                if (widget.kundaliScore != null) const SizedBox(width: 8),
                Expanded(child: _StatCard(value: '${widget.matchScorePct}%', label: context.t('match.title'))),
              ],
              if (widget.matchScorePct != null || widget.kundaliScore != null) const SizedBox(width: 8),
              Expanded(child: _StatCard(value: profile.isVerified ? '✓' : '—', label: context.t('common.verified'))),
            ]),
          ],
          const SizedBox(height: 24),
          _Section(title: context.t('viewProfile.personalInfo'), children: [
            _Row(Icons.calendar_today, context.t('viewProfile.dob'), profile.dob),
            _Row(Icons.people, context.t('viewProfile.gender'), profile.gender),
            _Row(Icons.menu_book, context.t('viewProfile.religion'), profile.religion),
            _Row(Icons.groups, context.t('viewProfile.category'), profile.category),
            if (profile.caste.isNotEmpty) _Row(Icons.account_tree, context.t('viewProfile.caste'), profile.caste),
            if (profile.gotra.isNotEmpty) _Row(Icons.spa, "Gotra", profile.gotra),
          ]),
          _Section(title: context.t('viewProfile.address'), children: [
            _Row(Icons.home, context.t('viewProfile.address'), profile.location),
          ]),
          _Section(title: context.t('viewProfile.occupationSection'), children: [
            _Row(Icons.work, context.t('viewProfile.occupation'), profile.occupation),
            if (profile.brothers.isNotEmpty)
              _Row(Icons.person, context.t('viewProfile.brothers'), profile.brothers),
            if (profile.sisters.isNotEmpty)
              _Row(Icons.person, context.t('viewProfile.sisters'), profile.sisters),
            _Row(Icons.family_restroom, context.t('viewProfile.familyDetails'), profile.familyDetails),
          ]),
          _Section(title: context.t('viewProfile.preferenceSection'), children: [
            _Row(Icons.list_alt, context.t('viewProfile.requirements'), profile.requirements),
          ]),
          if (profile.hasKundaliDetails)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.star_border),
                label: Text(context.t('viewProfile.viewKundali')),
                onPressed: () => Navigator.pushNamed(context, '/kundali', arguments: {
                  'otherUid': profile.uid,
                  'otherName': profile.fullName,
                }),
              ),
            ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kBrandColor)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: kBrandColor)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: kBrandColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? context.t('viewProfile.notAvailable') : value,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
