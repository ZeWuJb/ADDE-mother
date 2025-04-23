import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/community/user_profile_screen.dart';
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
  Future<void>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
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
      motherId = user.id;
      print('Initialized motherId: $motherId');
      setState(() {
        _isLoading = false;
        _fetchFuture ??= Provider.of<PostProvider>(
          context,
          listen: false,
        ).fetchPosts(motherId!);
      });
    } catch (e) {
      print('Error initializing: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    if (motherId != null) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      setState(() {
        _fetchFuture = postProvider.fetchPosts(motherId!);
      });
      await _fetchFuture;
      print('Refreshed posts for motherId: $motherId');
    }
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostScreen(),
    ).then((_) => _refreshPosts());
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: true);

    if (_isLoading || motherId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print('Search icon pressed');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: _showCreatePostDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          child: Text(motherId![0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "What's on your mind?",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<void>(
                future: _fetchFuture,
                builder: (context, snapshot) {
                  print('FutureBuilder state: ${snapshot.connectionState}');
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      postProvider.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('FutureBuilder error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (postProvider.posts.isEmpty) {
                    return const Center(
                      child: Text('No posts available. Create one!'),
                    );
                  }
                  return Column(
                    children:
                        postProvider.posts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final post = entry.value;
                          return AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(milliseconds: 300 + index * 100),
                            child: PostCard(
                              post: post,
                              onTap: () {
                                print('Tapped post ID: ${post.id}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PostDetailScreen(post: post),
                                  ),
                                );
                              },
                              onProfileTap: () {
                                print(
                                  'Tapped profile for motherId: ${post.motherId}',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UserProfileScreen(
                                          motherId: post.motherId,
                                          fullName: post.fullName,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
