import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'create_post_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onProfileTap,
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final currentMotherId = Supabase.instance.client.auth.currentUser?.id;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onProfileTap,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          child: Text(
                            widget.post.fullName.isNotEmpty
                                ? widget.post.fullName[0]
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.fullName.isNotEmpty
                                  ? widget.post.fullName
                                  : 'Unknown',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.black),
                            ),
                            Text(
                              timeago.format(widget.post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (currentMotherId != null &&
                          widget.post.motherId == currentMotherId)
                        PopupMenuButton(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.grey,
                          ),
                          itemBuilder:
                              (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder:
                                    (_) => CreatePostScreen(post: widget.post),
                              ).then(
                                (_) => postProvider.fetchPosts(currentMotherId),
                              );
                            } else if (value == 'delete') {
                              await postProvider.deletePost(widget.post.id);
                              print('Deleted post ID: ${widget.post.id}');
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.post.content,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.post.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              widget.post.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  widget.post.isLiked
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                            onPressed:
                                currentMotherId != null
                                    ? () async {
                                      print(
                                        'Toggling like for post ID: ${widget.post.id}, isLiked: ${widget.post.isLiked}',
                                      );
                                      await postProvider.toggleLike(
                                        widget.post.id,
                                        currentMotherId,
                                        widget.post.isLiked,
                                      );
                                    }
                                    : null,
                          ),
                          Text(
                            '${widget.post.likesCount}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black87),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: widget.onTap,
                        child: Text(
                          'Comment',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
