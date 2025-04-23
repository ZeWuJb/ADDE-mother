import 'package:adde/pages/community/peer_chat_screen.dart';
import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_detail_screen.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  final String motherId;
  final String fullName;

  const UserProfileScreen({
    super.key,
    required this.motherId,
    required this.fullName,
  });

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  Future<void> _fetchUserPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, mothers(full_name)')
          .eq('mother_id', widget.motherId)
          .order('created_at', ascending: false);

      setState(() {
        _userPosts =
            response.map<Post>((map) {
              return Post.fromMap(map, widget.fullName)..isLiked = false;
            }).toList();
        _isLoading = false;
        print(
          'Fetched ${_userPosts.length} posts for motherId: ${widget.motherId}',
        );
      });
    } catch (e) {
      print('Error fetching user posts: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.fullName),
        backgroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            child: Text(
                              widget.fullName.isNotEmpty
                                  ? widget.fullName[0]
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.fullName,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          if (currentUserId != widget.motherId)
                            ElevatedButton.icon(
                              onPressed: () {
                                print(
                                  'Navigating to chat with receiverId: ${widget.motherId}',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PeerChatScreen(
                                          receiverId: widget.motherId,
                                          receiverName: widget.fullName,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Posts',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                  if (_userPosts.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No posts yet')),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = _userPosts[index];
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 300 + index * 100),
                          child: PostCard(
                            post: post,
                            onTap: () {
                              print('Tapped post ID: ${post.id} from profile');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                            onProfileTap: () {}, // Prevent recursive navigation
                          ),
                        );
                      }, childCount: _userPosts.length),
                    ),
                ],
              ),
    );
  }
}
