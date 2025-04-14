class Post {
  final String id;
  final String motherId;
  final String fullName;
  final String title;
  final String content;
  final String? imageUrl;
       int likesCount;
  final DateTime createdAt;
  bool isLiked;

  Post({
    required this.id,
    required this.motherId,
    required this.fullName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Post.fromMap(Map<String, dynamic> map, String fullName) {
    print('Mapping post with id: ${map['id']}');
    return Post(
      id: map['id']?.toString() ?? '',
      motherId: map['mother_id']?.toString() ?? '',
      fullName: fullName,
      title: map['title']?.toString() ?? 'Untitled',
      content: map['content']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
      likesCount: map['likes_count'] is int ? map['likes_count'] : 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}