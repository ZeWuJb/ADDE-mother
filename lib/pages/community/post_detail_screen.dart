import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/comment_model.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];
  String? motherId;
  String? fullName;
  bool _isLoading = true;
  RealtimeChannel? _commentChannel;
  RealtimeChannel? _likeChannel;
  String? _errorMessage;
  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _subscribeToComments();
    _subscribeToLikes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
    _fetchComments();
  }

  Future<void> _fetchUserData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id}');
      if (user == null) {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseLogIn,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() {
          _errorMessage = l10n.pleaseLogIn;
          _isLoading = false;
        });
        return;
      }

      final response =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name')
              .eq('user_id', user.id)
              .maybeSingle();
      print('Mothers response: $response');

      if (response == null) {
        print('No mother record found for user_id: ${user.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorFetchingUserData('No user profile found'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() {
          motherId = user.id;
          fullName = 'Unknown';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        motherId = user.id;
        fullName = response['full_name']?.toString() ?? 'Unknown';
        _isLoading = false;
        print('Fetched user data: motherId=$motherId, fullName=$fullName');
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorFetchingUserData(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() {
        _errorMessage = l10n.errorFetchingUserData(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('*, mothers(full_name, profile_url)')
          .eq('post_id', _currentPost.id)
          .order('created_at', ascending: false);

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
        print(
          'Fetched ${_comments.length} comments for post ID: ${_currentPost.id}',
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error fetching comments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorFetchingComments(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() => _comments = []);
    }
  }

  void _subscribeToComments() {
    _commentChannel = Supabase.instance.client
        .channel('comments:${_currentPost.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: _currentPost.id,
          ),
          callback: (payload) {
            print('Comment change detected: ${payload.eventType}');
            _fetchComments();
            _refreshPost();
          },
        )
        .subscribe((status, [error]) {
          print('Comment subscription status: $status');
          if (status == 'CHANNEL_ERROR') {
            print('Comment subscription error: $error');
          } else if (status == 'SUBSCRIBED') {
            print(
              'Successfully subscribed to comments for post: ${_currentPost.id}',
            );
          }
        });
  }

  void _subscribeToLikes() {
    _likeChannel = Supabase.instance.client
        .channel('likes:${_currentPost.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: _currentPost.id,
          ),
          callback: (payload) {
            print('Like change detected: ${payload.eventType}');
            _refreshPost();
          },
        )
        .subscribe((status, [error]) {
          print('Like subscription status: $status');
          if (status == 'CHANNEL_ERROR') {
            print('Like subscription error: $error');
          } else if (status == 'SUBSCRIBED') {
            print(
              'Successfully subscribed to likes for post: ${_currentPost.id}',
            );
          }
        });
  }

  Future<void> _addComment() async {
    final l10n = AppLocalizations.of(context)!;
    if (_commentController.text.trim().isEmpty ||
        motherId == null ||
        fullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.commentCannotBeEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      final response =
          await Supabase.instance.client
              .from('comments')
              .insert({
                'post_id': _currentPost.id,
                'mother_id': motherId,
                'content': _commentController.text.trim(),
              })
              .select('*, mothers(full_name, profile_url)')
              .single();

      setState(() {
        _comments.insert(0, Comment.fromMap(response, fullName!));
        _commentController.clear();
        print('Added comment to post ID: ${_currentPost.id}');
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      await _refreshPost();
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorAddingComment(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('mother_id', motherId!);
      setState(() {
        _comments.removeWhere((comment) => comment.id == commentId);
        print('Deleted comment ID: $commentId');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.commentDeletedSuccessfully,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      await _refreshPost();
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorDeletingComment(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _refreshPost() async {
    try {
      final post = await Provider.of<PostProvider>(
        context,
        listen: false,
      ).fetchPost(_currentPost.id, motherId ?? '');
      setState(() {
        _currentPost = post;
        print(
          'Refreshed post ID: ${_currentPost.id}, likes: ${_currentPost.likesCount}, comments: ${_currentPost.commentCount}',
        );
      });
    } catch (e) {
      print('Error refreshing post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorFetchingPost,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  ImageProvider? _getImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    if (_commentChannel != null) {
      Supabase.instance.client.removeChannel(_commentChannel!);
    }
    if (_likeChannel != null) {
      Supabase.instance.client.removeChannel(_likeChannel!);
    }
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.postDetailTitle,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
              color:
                  theme.brightness == Brightness.light
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
          ),
          backgroundColor:
              theme.brightness == Brightness.light
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
          elevation: theme.appBarTheme.elevation,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.postDetailTitle,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
              color:
                  theme.brightness == Brightness.light
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
          ),
          backgroundColor:
              theme.brightness == Brightness.light
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
          elevation: theme.appBarTheme.elevation,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchUserData();
                  _fetchComments();
                },
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.postDetailTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color:
                theme.brightness == Brightness.light
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
          ),
        ),
        backgroundColor:
            theme.brightness == Brightness.light
                ? theme.colorScheme.primary
                : theme.colorScheme.onPrimary,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.all(screenHeight * 0.02),
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
                                      label: l10n.profileOf(
                                        _currentPost.fullName,
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            theme.colorScheme.secondary,
                                        foregroundColor:
                                            theme.colorScheme.onSecondary,
                                        backgroundImage: _getImageProvider(
                                          _currentPost.profileImageUrl,
                                        ),
                                        child:
                                            _currentPost.profileImageUrl ==
                                                        null ||
                                                    _getImageProvider(
                                                          _currentPost
                                                              .profileImageUrl,
                                                        ) ==
                                                        null
                                                ? Text(
                                                  _currentPost
                                                          .fullName
                                                          .isNotEmpty
                                                      ? _currentPost.fullName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _currentPost.fullName.isNotEmpty
                                                ? _currentPost.fullName
                                                : 'Unknown',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSurface,
                                                ),
                                          ),
                                          Text(
                                            timeago.format(
                                              _currentPost.createdAt,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentPost.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentPost.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (_currentPost.imageUrl != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _currentPost.imageUrl!,
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Semantics(
                                          label:
                                              _currentPost.isLiked
                                                  ? l10n.unlikePost
                                                  : l10n.likePost,
                                          child: IconButton(
                                            icon: Icon(
                                              _currentPost.isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  _currentPost.isLiked
                                                      ? Colors.red
                                                      : theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                            ),
                                            onPressed:
                                                motherId == null
                                                    ? null
                                                    : () async {
                                                      try {
                                                        await postProvider
                                                            .likePost(
                                                              _currentPost.id,
                                                              motherId!,
                                                              !_currentPost
                                                                  .isLiked,
                                                            );
                                                        await _refreshPost();
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              l10n.errorLikingPost(
                                                                e.toString(),
                                                              ),
                                                              style: theme
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color:
                                                                        theme
                                                                            .colorScheme
                                                                            .onError,
                                                                  ),
                                                            ),
                                                            backgroundColor:
                                                                theme
                                                                    .colorScheme
                                                                    .error,
                                                          ),
                                                        );
                                                      }
                                                    },
                                            tooltip:
                                                _currentPost.isLiked
                                                    ? l10n.unlikePost
                                                    : l10n.likePost,
                                          ),
                                        ),
                                        Text(
                                          l10n.likesCountText(
                                            _currentPost.likesCount,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      l10n.commentsCountText(
                                        _currentPost.commentCount,
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final comment = _comments[_comments.length - 1 - index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenHeight * 0.02,
                            vertical: screenHeight * 0.01,
                          ),
                          child: Semantics(
                            label: l10n.commentBy(comment.fullName),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                  backgroundImage: _getImageProvider(
                                    comment.profileUrl,
                                  ),
                                  child:
                                      comment.profileUrl == null ||
                                              _getImageProvider(
                                                    comment.profileUrl,
                                                  ) ==
                                                  null
                                          ? Text(
                                            comment.fullName.isNotEmpty
                                                ? comment.fullName[0]
                                                    .toUpperCase()
                                                : '?',
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
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
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontSize: 16,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                            ),
                                            if (comment.motherId == motherId)
                                              Semantics(
                                                label: l10n.deleteCommentBy(
                                                  comment.fullName,
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                  onPressed:
                                                      () => _deleteComment(
                                                        comment.id,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          comment.content,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeago.format(comment.createdAt),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: _comments.length),
                    ),
                    if (_comments.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(screenHeight * 0.02),
                          child: Center(
                            child: Text(
                              l10n.noCommentsYet,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
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
                  color: theme.colorScheme.surfaceContainer,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
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
                          hintText: l10n.addCommentHint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: l10n.sendCommentTooltip,
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _addComment,
                        tooltip: l10n.sendCommentTooltip,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
