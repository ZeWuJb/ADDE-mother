class Comment {
  final String id;
  final String postId;
  final String motherId;
  final String fullName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.motherId,
    required this.fullName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String fullName) {
    return Comment(
      id: map['id'],
      postId: map['post_id'],
      motherId: map['mother_id'],
      fullName: fullName,
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
