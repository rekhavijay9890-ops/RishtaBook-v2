import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/credit_service.dart';
import '../../services/moderation_service.dart';
import '../../i18n/strings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rb_avatar.dart';

class ChatPage extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String otherUserId;
  final String currentUserId;

  const ChatPage({super.key, required this.matchId, required this.otherUserName, required this.otherUserId, required this.currentUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final CreditService _creditService = CreditService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _picker = ImagePicker();
  final ModerationService _moderationService = ModerationService();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isSending = false;
  bool? _unlocked;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkUnlocked();
  }

  Future<void> _checkUnlocked() async {
    final ok = await _creditService.isChatUnlocked(widget.matchId, widget.currentUserId);
    if (mounted) setState(() => _unlocked = ok);
    if (ok) _chatService.markSeen(widget.matchId, widget.currentUserId);
  }

  Future<void> _unlock() async {
    setState(() => _unlocking = true);
    final ok = await _creditService.unlockChatIfNeeded(widget.matchId, widget.currentUserId, otherName: widget.otherUserName);
    if (!mounted) return;
    setState(() { _unlocking = false; _unlocked = ok; });
    if (ok) {
      _chatService.markSeen(widget.matchId, widget.currentUserId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('chat.insufficientCredits'))));
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(onError: (e) => debugPrint('Speech error: $e'));
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechAvailable) return;
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() => _messageController.text = result.recognizedWords);
          _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
        },
      );
    }
  }

  Future<void> _send({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    _messageController.clear();
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(matchId: widget.matchId, senderId: widget.currentUserId, text: text, imageUrl: imageUrl);
      _scrollToBottom();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error'))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
      if (picked == null) return;
      setState(() => _isSending = true);
      final ref = FirebaseStorage.instance.ref().child('chat_images/${widget.matchId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _send(imageUrl: url);
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('common.error'))));
      }
    }
  }

  Future<void> _confirmBlock() async {
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
    await _moderationService.blockUser(widget.currentUserId, widget.otherUserId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('safety.blocked')), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  void _openReportSheet() {
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
                await _moderationService.fileReport(widget.currentUserId, reportedUid: widget.otherUserId, reason: reason, details: detailsCtrl.text.trim());
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Widget _header() {
    return Container(
      width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            RbAvatar(initials: widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?', size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                if (_isListening) Text(context.isHindi ? '🎙️ सुन रहा हूँ...' : '🎙️ Listening...', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ]),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) => v == 'block' ? _confirmBlock() : _openReportSheet(),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'report', child: Text(context.t('safety.report'))),
                PopupMenuItem(value: 'block', child: Text(context.t('safety.block'))),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == null) {
      return Scaffold(backgroundColor: AppColors.pageBg, body: Column(children: [_header(), const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.saffron)))]));
    }

    if (_unlocked == false) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Column(children: [
          _header(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('👛', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(context.t('chat.unlockNotice', [CreditService.chatUnlockCost]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _unlocking ? null : _unlock,
                      child: _unlocking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(context.t('chat.unlockCta', [CreditService.chatUnlockCost])),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          _header(),
          StreamBuilder<int>(
            stream: _creditService.creditsStream(widget.currentUserId),
            builder: (context, snap) {
              return Container(
                color: AppColors.goldLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Row(children: [
                  const Text('👛', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(context.t('chat.creditsUsed', [CreditService.chatUnlockCost, snap.data ?? 0]), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold)),
                ]),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.messagesStream(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
                }
                final messages = (snapshot.data?.docs ?? []).map((d) => ChatMessage.fromDoc(d)).toList();
                if (messages.isEmpty) {
                  return Center(child: Text(context.t('chat.startPrompt'), style: const TextStyle(color: AppColors.muted)));
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  _chatService.markSeen(widget.matchId, widget.currentUserId);
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: m.imageUrl != null ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          gradient: isMe ? const LinearGradient(colors: [AppColors.saffron, AppColors.safDark]) : null,
                          color: isMe ? null : AppColors.cardBg,
                          border: isMe ? null : Border.all(color: AppColors.borderColor),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                        child: m.imageUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(m.imageUrl!, fit: BoxFit.cover, height: 200))
                            : Text(m.text, style: TextStyle(color: isMe ? Colors.white : AppColors.ink, fontSize: 12)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              color: AppColors.cardBg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.attach_file_rounded, color: AppColors.ghost), onPressed: _isSending ? null : _pickImage),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(hintText: context.t('chat.typeMessage')),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, color: _isListening ? AppColors.rose : AppColors.saffron),
                  onPressed: _speechAvailable ? _toggleListening : null,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _isSending ? null : () => _send(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.saffron, AppColors.safDark])),
                    child: _isSending
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
