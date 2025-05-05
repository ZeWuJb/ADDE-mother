import 'package:adde/l10n/arb/app_localizations.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final currentMotherId = Supabase.instance.client.auth.currentUser?.id;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: Semantics(
        label: l10n.postBy(widget.post.fullName),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.02,
              vertical: screenHeight * 0.01,
            ),
            child: Card(
              color: theme.colorScheme.surfaceContainer,
              elevation: theme.cardTheme.elevation,
              shape:
                  theme.cardTheme.shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
              child: Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Semantics(
                          label: l10n.profileOf(widget.post.fullName),
                          child: GestureDetector(
                            onTap: widget.onProfileTap,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              child: Text(
                                widget.post.fullName.isNotEmpty
                                    ? widget.post.fullName[0]
                                    : '?',
                              ),
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
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                timeago.format(widget.post.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentMotherId != null &&
                            widget.post.motherId == currentMotherId)
                          PopupMenuButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            itemBuilder:
                                (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(
                                      l10n.editPost,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      l10n.deletePost,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (_) =>
                                          CreatePostScreen(post: widget.post),
                                ).then(
                                  (_) =>
                                      postProvider.fetchPosts(currentMotherId),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
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
                              (_, __, ___) => Icon(
                                Icons.broken_image,
                                size: 50,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Semantics(
                              label:
                                  widget.post.isLiked
                                      ? l10n.unlikePost
                                      : l10n.likePost,
                              child: IconButton(
                                icon: Icon(
                                  widget.post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      widget.post.isLiked
                                          ? Colors.red
                                          : theme.colorScheme.onSurfaceVariant,
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
                            ),
                            Text(
                              '${widget.post.likesCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          label: l10n.commentOnPost,
                          child: TextButton(
                            onPressed: widget.onTap,
                            style: theme.textButtonTheme.style?.copyWith(
                              foregroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              l10n.commentPost,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
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
      ),
    );
  }
}
