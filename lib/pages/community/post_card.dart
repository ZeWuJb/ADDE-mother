import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'create_post_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final currentMotherId = Supabase.instance.client.auth.currentUser?.id;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(post.fullName[0]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.fullName, style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          timeago.format(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (currentMotherId != null && post.motherId == currentMotherId)
                    PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePostScreen(post: post),
                            ),
                          );
                          await postProvider.fetchPosts(currentMotherId);
                        } else if (value == 'delete') {
                          await postProvider.deletePost(post.id);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : null,
                    ),
                    onPressed: currentMotherId != null
                        ? () async {
                            await postProvider.toggleLike(post.id, currentMotherId, post.isLiked);
                          }
                        : null,
                  ),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment),
                  const SizedBox(width: 8),
                  const Text('Comment'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}