import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.post});

  final Post? post;

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? motherId;
  String? fullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
    }
    _fetchUserData();
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

  Future<void> _submit(BuildContext context) async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (motherId == null || fullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not loaded')),
      );
      return;
    }

    try {
      if (widget.post == null) {
        await postProvider.createPost(
          motherId!,
          fullName!,
          _titleController.text,
          _contentController.text,
        );
      } else {
        await postProvider.updatePost(
          widget.post!.id,
          _titleController.text,
          _contentController.text,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Create Post' : 'Edit Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _submit(context),
                    child: Text(widget.post == null ? 'Post' : 'Update'),
                  ),
                ],
              ),
            ),
    );
  }
}