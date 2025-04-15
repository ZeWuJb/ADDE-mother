import 'package:adde/pages/community/comment_model.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  String? motherId;
  String? fullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchComments();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in')));
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name')
              .eq('user_id', user.id)
              .single();
      setState(() {
        motherId = user.id;
        fullName = response['full_name']?.toString() ?? 'Unknown';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('*, mothers(full_name)')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);

      setState(() {
        _comments =
            response
                .map<Comment>(
                  (map) => Comment.fromMap(
                    map,
                    map['mothers']['full_name'] ?? 'Unknown',
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Error fetching comments: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching comments: $e')));
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty ||
        motherId == null ||
        fullName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty')));
      return;
    }

    try {
      final response =
          await Supabase.instance.client
              .from('comments')
              .insert({
                'post_id': widget.post.id,
                'mother_id': motherId,
                'content': _commentController.text,
              })
              .select('*, mothers(full_name)')
              .single();

      setState(() {
        _comments.add(Comment.fromMap(response, fullName!));
        _commentController.clear();
      });
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId);
      setState(() {
        _comments.removeWhere((comment) => comment.id == commentId);
      });
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post'), backgroundColor: Colors.white),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      child: Text(
                                        widget.post.fullName.isNotEmpty
                                            ? widget.post.fullName[0]
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.post.fullName.isNotEmpty
                                                ? widget.post.fullName
                                                : 'Unknown',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleLarge,
                                          ),
                                          Text(
                                            timeago.format(
                                              widget.post.createdAt,
                                            ),
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.post.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.post.content,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (widget.post.imageUrl != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.post.imageUrl!,
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${widget.post.likesCount} Likes',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_comments.length} Comments',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final comment = _comments[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    child: Text(
                                      comment.fullName.isNotEmpty
                                          ? comment.fullName[0]
                                          : '?',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                comment.fullName.isNotEmpty
                                                    ? comment.fullName
                                                    : 'Unknown',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(fontSize: 16),
                                              ),
                                              if (comment.motherId == motherId)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed:
                                                      () => _deleteComment(
                                                        comment.id,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            comment.content,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeago.format(comment.createdAt),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }, childCount: _comments.length),
                        ),
                        if (_comments.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text('No comments yet')),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFf7a1c4),
                          ),
                          onPressed: _addComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
