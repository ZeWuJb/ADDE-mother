class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  bool isSeen;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isSeen = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isSeen: map['is_seen'] ?? false,
    );
  }
}
