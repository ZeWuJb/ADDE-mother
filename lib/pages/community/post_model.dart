class Post {
  final String id;
  final String motherId;
  final String fullName;
  final String title;
  final String content;
  int likesCount;
  final DateTime createdAt;
  bool isLiked;

  Post({
    required this.id,
    required this.motherId,
    required this.fullName,
    required this.title,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Post.fromMap(Map<String, dynamic> map, String fullName) {
    return Post(
      id: map['id'],
      motherId: map['mother_id'],
      fullName: fullName,
      title: map['title'],
      content: map['content'],
      likesCount: map['likes_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}