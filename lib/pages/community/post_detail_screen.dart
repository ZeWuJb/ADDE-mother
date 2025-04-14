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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final response = await Supabase.instance.client
          .from('mothers')
          .select('full_name')
          .eq('user_id', user.id)
          .single();
      setState(() {
        motherId = user.id;
        fullName = response['full_name'];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
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
        _comments = response
            .map<Comment>((map) => Comment.fromMap(map, map['mothers']['full_name'] ?? 'Unknown'))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching comments: $e')),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || motherId == null || fullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.from('comments').insert({
        'post_id': widget.post.id,
        'mother_id': motherId,
        'content': _commentController.text,
      }).select('*, mothers(full_name)').single();

      setState(() {
        _comments.add(Comment.fromMap(response, fullName!));
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await Supabase.instance.client.from('comments').delete().eq('id', commentId);
      setState(() {
        _comments.removeWhere((comment) => comment.id == commentId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              child: Text(widget.post.fullName[0]),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.post.fullName,
                                    style: Theme.of(context).textTheme.titleLarge),
                                Text(
                                  timeago.format(widget.post.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.post.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(widget.post.content,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text('Comments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No comments yet'),
                          ),
                        ..._comments.map((comment) => ListTile(
                              leading: CircleAvatar(child: Text(comment.fullName[0])),
                              title: Text(comment.fullName),
                              subtitle: Text(comment.content),
                              trailing: comment.motherId == motherId
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteComment(comment.id),
                                    )
                                  : null,
                            )),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
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