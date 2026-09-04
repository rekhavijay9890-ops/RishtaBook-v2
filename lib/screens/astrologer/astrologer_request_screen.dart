import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/rb_gradient_app_bar.dart';
import '../../services/astrologer_service.dart';
import '../../i18n/strings.dart';

/// Requests a callback from an astrologer - not a live booking/scheduling
/// system (see AstrologerService's doc comment). Submits contact details
/// + preferred time; an admin follows up manually.
class AstrologerRequestScreen extends StatefulWidget {
  final String uid;
  const AstrologerRequestScreen({super.key, required this.uid});

  @override
  State<AstrologerRequestScreen> createState() => _AstrologerRequestScreenState();
}

class _AstrologerRequestScreenState extends State<AstrologerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AstrologerService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_nameController, _phoneController, _timeController, _notesController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await _service.requestConsultation(
        widget.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        preferredTime: _timeController.text.trim(),
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('astrologer.requestSent')), backgroundColor: AppColors.success));
        _nameController.clear();
        _phoneController.clear();
        _timeController.clear();
        _notesController.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: RbGradientAppBar(title: Text(context.t('astrologer.title'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.t('astrologer.subtitle'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: context.t('astrologer.nameHint')),
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.t('basicDetails.fullNameRequired') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(hintText: context.t('astrologer.phoneHint')),
                  validator: (v) => (v == null || v.trim().length < 10) ? context.t('basicDetails.mobileRequired') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(hintText: context.t('astrologer.timeHint')),
                  validator: (v) => (v == null || v.trim().isEmpty) ? context.t('basicDetails.fullNameRequired') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: context.t('astrologer.notesHint')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(context.t('astrologer.submit')),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Text(context.t('astrologer.myRequests'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffron, fontSize: 14)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.myRequestsStream(widget.uid),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const SizedBox.shrink();
                return Column(children: docs.map((doc) {
                  final data = doc.data();
                  final contacted = data['status'] == 'contacted';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
                    child: Row(children: [
                      Expanded(child: Text(data['preferredTime'] ?? '', style: const TextStyle(fontSize: 13))),
                      Text(
                        contacted ? context.t('astrologer.statusContacted') : context.t('astrologer.statusPending'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: contacted ? AppColors.success : AppColors.gold),
                      ),
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
