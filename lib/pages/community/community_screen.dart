import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/community/user_profile_screen.dart';
import 'package:adde/pages/community/create_post_screen.dart';
import 'package:adde/pages/community/post_detail_screen.dart';
import 'package:adde/pages/community/search_screen.dart';
import 'package:adde/pages/community/messages_screen.dart';
import 'package:adde/pages/community/post_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String? motherId;
  bool _isLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pleaseLogIn,
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
          _isLoading = false;
        });
        return;
      }
      motherId = user.id;
      print('Initialized motherId: $motherId');
      final motherData =
          await Supabase.instance.client
              .from('mothers')
              .select('profile_url')
              .eq('user_id', motherId!)
              .single();
      setState(() {
        _profileImageUrl = motherData['profile_url'] as String?;
        _isLoading = false;
      });
      await Provider.of<PostProvider>(
        context,
        listen: false,
      ).fetchPosts(motherId!);
    } catch (e) {
      print('Error initializing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorFetchingUser(e.toString()),
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
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    if (motherId != null) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.fetchPosts(motherId!);
      setState(() {
        print('UI refreshed for motherId: $motherId');
      });
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

  void _showReportDialog(String postId) {
    String? selectedReason;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.reportPostTitle),
            content: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: l10n.reportReasonHint,
                border: const OutlineInputBorder(),
              ),
              value: selectedReason,
              items: [
                DropdownMenuItem(
                  value: 'inappropriate',
                  child: Text(l10n.reasonInappropriate),
                ),
                DropdownMenuItem(value: 'spam', child: Text(l10n.reasonSpam)),
                DropdownMenuItem(
                  value: 'offensive',
                  child: Text(l10n.reasonOffensive),
                ),
                DropdownMenuItem(
                  value: 'misleading',
                  child: Text(l10n.reasonMisleading),
                ),
                DropdownMenuItem(
                  value: 'harassment',
                  child: Text(l10n.reasonHarassment),
                ),
                DropdownMenuItem(
                  value: 'copyright',
                  child: Text(l10n.reasonCopyright),
                ),
                DropdownMenuItem(value: 'other', child: Text(l10n.reasonOther)),
              ],
              onChanged: (value) {
                selectedReason = value;
              },
              validator:
                  (value) => value == null ? l10n.reportReasonRequired : null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.reportReasonRequired),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                    return;
                  }
                  try {
                    await Provider.of<PostProvider>(
                      context,
                      listen: false,
                    ).reportPost(
                      postId: postId,
                      reporterId: motherId!,
                      reason: selectedReason!,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.reportSubmitted),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorReportingPost(e.toString())),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                child: Text(l10n.submitButton),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(String postId) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deletePostTitle),
            content: Text(l10n.deletePostConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Provider.of<PostProvider>(
                      context,
                      listen: false,
                    ).deletePost(postId: postId, motherId: motherId!);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.deletePostSuccess),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );
                    await _refreshPosts();
                  } catch (e) {
                    Navigator.pop(context);
                    String errorMessage = l10n.errorDeletingPost(e.toString());
                    if (e.toString().contains('has associated comments')) {
                      errorMessage = l10n.errorDeletingPostWithComments;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                child: Text(l10n.deleteButton),
              ),
            ],
          ),
    );
  }

  ImageProvider? _getImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context, listen: true);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || motherId == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.pageTitleCommunity,
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color:
                  theme.brightness == Brightness.light
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            tooltip: l10n.searchPosts,
          ),
          IconButton(
            icon: Icon(
              Icons.message,
              color:
                  theme.brightness == Brightness.light
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessagesScreen(motherId: motherId!),
                ),
              );
            },
            tooltip: l10n.viewMessages,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: Semantics(
                  label: l10n.createNewPost,
                  child: GestureDetector(
                    onTap: _showCreatePostDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            backgroundImage: _getImageProvider(
                              _profileImageUrl,
                            ),
                            child:
                                _profileImageUrl == null ||
                                        _getImageProvider(_profileImageUrl) ==
                                            null
                                    ? Text(motherId![0].toUpperCase())
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.whatsOnYourMind,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child:
                  postProvider.posts.isEmpty
                      ? Center(
                        child: Semantics(
                          label: l10n.noPosts,
                          child: Text(
                            l10n.noPosts,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      : Column(
                        children:
                            postProvider.posts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final post = entry.value;
                              return AnimatedOpacity(
                                opacity: 1.0,
                                duration: Duration(
                                  milliseconds: 300 + index * 100,
                                ),
                                child: PostCard(
                                  motherId: motherId,
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
                                  onReport:
                                      motherId != post.motherId
                                          ? () => _showReportDialog(post.id)
                                          : null,
                                  onDelete:
                                      motherId == post.motherId
                                          ? () => _showDeleteDialog(post.id)
                                          : null,
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
