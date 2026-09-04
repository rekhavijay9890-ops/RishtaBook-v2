import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/rb_gradient_app_bar.dart';
import '../../services/success_story_service.dart';
import '../../i18n/strings.dart';

/// Lets a user submit their own success story for admin review - see
/// SuccessStoryService's class doc. Submitting never makes it public by
/// itself; an admin has to approve it first.
class ShareSuccessStoryScreen extends StatefulWidget {
  final String uid;
  const ShareSuccessStoryScreen({super.key, required this.uid});

  @override
  State<ShareSuccessStoryScreen> createState() => _ShareSuccessStoryScreenState();
}

class _ShareSuccessStoryScreenState extends State<ShareSuccessStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SuccessStoryService();
  final _namesController = TextEditingController();
  final _quoteController = TextEditingController();
  final _weddingDateController = TextEditingController();
  final _photoUrlController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_namesController, _quoteController, _weddingDateController, _photoUrlController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _service.submitStory(
        widget.uid,
        names: _namesController.text.trim(),
        quote: _quoteController.text.trim(),
        weddingDate: _weddingDateController.text.trim(),
        photoUrl: _photoUrlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('successStory.submitted')), backgroundColor: AppColors.success));
        _namesController.clear();
        _quoteController.clear();
        _weddingDateController.clear();
        _photoUrlController.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved': return context.t('successStory.statusApproved');
      case 'rejected': return context.t('successStory.statusRejected');
      default: return context.t('successStory.statusPending');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: RbGradientAppBar(title: Text(context.t('successStory.title'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t('successStory.subtitle'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(
                    controller: _namesController,
                    decoration: InputDecoration(hintText: context.t('successStory.namesHint')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? context.t('basicDetails.fullNameRequired') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quoteController,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: context.t('successStory.quoteHint')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? context.t('basicDetails.fullNameRequired') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weddingDateController,
                    decoration: InputDecoration(hintText: context.t('successStory.weddingDateHint')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _photoUrlController,
                    decoration: InputDecoration(hintText: context.t('successStory.photoUrlHint')),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(context.t('successStory.submit')),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Text(context.t('successStory.mySubmissions'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffron, fontSize: 14)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.myPendingStream(widget.uid),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return const SizedBox.shrink();
                  return Column(children: docs.map((doc) {
                    final data = doc.data();
                    final status = data['status'] as String? ?? 'pending';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
                      child: Row(children: [
                        Expanded(child: Text(data['names'] as String? ?? '', style: const TextStyle(fontSize: 13))),
                        Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                      ]),
                    );
                  }).toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
