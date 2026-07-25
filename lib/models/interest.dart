import 'package:cloud_firestore/cloud_firestore.dart';

/// One "interest" - a user expressing intent to connect with another.
/// Lives in the top-level `interests` collection. When the receiver
/// accepts, a [MatchRecord] is created and the two can chat.
class Interest {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String toName;

  /// pending | accepted | rejected
  final String status;
  final DateTime? createdAt;

  const Interest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.toName,
    required this.status,
    required this.createdAt,
  });

  factory Interest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Interest(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      fromName: data['fromName'] ?? 'Someone',
      toName: data['toName'] ?? 'Someone',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A confirmed match between two users, created once an interest is
/// accepted. The document id is the two uids sorted and joined with
/// `_`, so it doubles as the chat thread id.
class MatchRecord {
  final String id;
  final List<String> participants;
  final DateTime? createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;

  const MatchRecord({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory MatchRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MatchRecord(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  String otherUid(String myUid) =>
      participants.firstWhere((id) => id != myUid, orElse: () => '');
}
