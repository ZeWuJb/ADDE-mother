import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String? motherId;
  bool _isLoading = true;
  Future<void>? _fetchFuture; // Store the Future to prevent restarts

  @override
  void initState() {
    super.initState();
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
      setState(() {
        motherId = user.id;
        _isLoading = false;
        _fetchFuture = Provider.of<PostProvider>(context, listen: false).fetchPosts(motherId!);
      });
      print('Initiated fetch for motherId: $motherId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    if (_isLoading || motherId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _fetchFuture = postProvider.fetchPosts(motherId!);
          });
          await _fetchFuture;
        },
        child: FutureBuilder<void>(
          future: _fetchFuture,
          builder: (context, snapshot) {
            print('FutureBuilder state: ${snapshot.connectionState}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('FutureBuilder error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (postProvider.posts.isEmpty) {
              return const Center(child: Text('No posts available. Create one!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                print('Rendering post: ${post.title}');
                return PostCard(
                  post: post,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
          setState(() {
            _fetchFuture = postProvider.fetchPosts(motherId!);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}