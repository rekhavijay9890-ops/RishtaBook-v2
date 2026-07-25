import 'package:cloud_firestore/cloud_firestore.dart';

/// One message inside `matches/{matchId}/messages/{messageId}`.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}
