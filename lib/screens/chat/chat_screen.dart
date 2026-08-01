import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

const Color kBrandColor = AppColors.primary;

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final ImagePicker _picker = ImagePicker();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Mark messages as seen when chat is opened
    _chatService.markSeen(widget.matchId, widget.currentUserId);
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("माइक की अनुमति नहीं मिली। / Mic permission unavailable.")));
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() => _messageController.text = result.recognizedWords);
          _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length));
        },
        localeId: 'hi_IN', // Hindi speech recognition
      );
    }
  }

  Future<void> _send({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    _messageController.clear();
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(
        matchId: widget.matchId,
        senderId: widget.currentUserId,
        text: text,
        imageUrl: imageUrl,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("संदेश नहीं भेजा जा सका। / Message could not be sent.")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70, maxWidth: 1200);
      if (picked == null) return;

      setState(() => _isSending = true);
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/${widget.matchId}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _send(imageUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("फ़ोटो अपलोड नहीं हो पाई।")));
      }
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (_isListening)
              const Text("🎙️ सुन रहा हूँ... / Listening...",
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.messagesStream(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kBrandColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("बात शुरू करें! / Start chatting! 👋",
                          style: TextStyle(color: Colors.grey)));
                }

                final messages =
                    snapshot.data!.docs.map((doc) => ChatMessage.fromDoc(doc)).toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                  // Mark seen whenever new messages arrive
                  _chatService.markSeen(widget.matchId, widget.currentUserId);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: message.imageUrl != null
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: isMe ? kBrandColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: message.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(message.imageUrl!,
                                    fit: BoxFit.cover, height: 200),
                              )
                            : Text(message.text,
                                style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Image attachment button
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: kBrandColor),
                    onPressed: _isSending ? null : _pickImage,
                    tooltip: "फ़ोटो भेजें / Send Photo",
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isListening ? "बोल रहे हैं... / Listening..." : "संदेश लिखें... / Type a message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  // Mic button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListening ? Colors.red : kBrandColor,
                    ),
                    onPressed: _speechAvailable ? _toggleListening : null,
                    tooltip: _isListening ? "रोकें / Stop" : "आवाज़ संदेश",
                  ),
                  // Send button
                  CircleAvatar(
                    backgroundColor: kBrandColor,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _send(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
