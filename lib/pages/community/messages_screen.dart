import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/peer_chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatefulWidget {
  final String motherId;

  const MessagesScreen({super.key, required this.motherId});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final response = await Supabase.instance.client
          .from('communitymessages')
          .select(
            '*, sender:mothers!sender_id(full_name, profile_url, online_status), receiver:mothers!receiver_id(full_name, profile_url, online_status)',
          )
          .or(
            'sender_id.eq.${widget.motherId},receiver_id.eq.${widget.motherId}',
          )
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> conversationMap = {};
      for (var message in response) {
        final otherId =
            message['sender_id'] == widget.motherId
                ? message['receiver_id']
                : message['sender_id'];
        final otherName =
            message['sender_id'] == widget.motherId
                ? message['receiver']['full_name']
                : message['sender']['full_name'];
        final otherProfileUrl =
            message['sender_id'] == widget.motherId
                ? message['receiver']['profile_url']
                : message['sender']['profile_url'];
        final isOnline =
            message['sender_id'] == widget.motherId
                ? message['receiver']['online_status'] ?? false
                : message['sender']['online_status'] ?? false;
        final isSender = message['sender_id'] == widget.motherId;

        if (!conversationMap.containsKey(otherId)) {
          conversationMap[otherId] = {
            'otherId': otherId,
            'otherName': otherName,
            'profileUrl': otherProfileUrl,
            'lastMessage': message['content'],
            'messageType': message['message_type'] ?? 'text',
            'timestamp': DateTime.parse(message['created_at']),
            'isSeen': message['is_seen'] || isSender,
            'isPinned': message['is_pinned'] ?? false,
            'unreadCount': 0,
            'isOnline': isOnline,
            'isSender': isSender,
          };
        }

        // Increment unread count for unseen incoming messages
        if (!message['is_seen'] && !isSender) {
          conversationMap[otherId]!['unreadCount'] =
              (conversationMap[otherId]!['unreadCount'] as int) + 1;
        }
      }

      setState(() {
        _conversations =
            conversationMap.values.toList()..sort((a, b) {
              // Pinned conversations first, then by timestamp
              if (a['isPinned'] && !b['isPinned']) return -1;
              if (!a['isPinned'] && b['isPinned']) return 1;
              return b['timestamp'].compareTo(a['timestamp']);
            });
        _isLoading = false;
        print(
          'Fetched ${_conversations.length} conversations for motherId: ${widget.motherId}',
        );
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.errorFetchingConversations(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messagesTitle),
        backgroundColor: theme.colorScheme.primary,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _conversations.isEmpty
              ? Center(
                child: Text(
                  l10n.noConversations,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  final isUnread = conversation['unreadCount'] > 0;

                  return AnimatedListItem(
                    index: index,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            backgroundImage: _getImageProvider(
                              conversation['profileUrl'],
                            ),
                            child:
                                conversation['profileUrl'] == null ||
                                        _getImageProvider(
                                              conversation['profileUrl'],
                                            ) ==
                                            null
                                    ? Text(
                                      conversation['otherName'].isNotEmpty
                                          ? conversation['otherName'][0]
                                              .toUpperCase()
                                          : '?',
                                    )
                                    : null,
                          ),
                          if (conversation['isOnline'])
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.green,
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['otherName'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight:
                                    isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (conversation['isPinned'])
                            Icon(
                              Icons.push_pin,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (conversation['messageType'] != 'text') ...[
                            Icon(
                              _getMessageTypeIcon(conversation['messageType']),
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              _getMessagePreview(
                                conversation,
                                l10n,
                                conversation['isSender'],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight:
                                    isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeago.format(
                              conversation['timestamp'],
                              locale: l10n.localeName,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isUnread
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (conversation['unreadCount'] > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${conversation['unreadCount']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PeerChatScreen(
                                  currentMotherId: widget.motherId,
                                  otherMotherId: conversation['otherId'],
                                  otherMotherName: conversation['otherName'],
                                ),
                          ),
                        ).then(
                          (_) => _fetchConversations(),
                        ); // Refresh on return
                      },
                    ),
                  );
                },
              ),
    );
  }

  IconData _getMessageTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.description;
      default:
        return Icons.message;
    }
  }

  String _getMessagePreview(
    Map<String, dynamic> conversation,
    AppLocalizations l10n,
    bool isSender,
  ) {
    final type = conversation['messageType'];
    final content = conversation['lastMessage'];
    if (isSender) {
      return '${l10n.you}: ${_getContentForType(type, content, l10n)}';
    }
    return _getContentForType(type, content, l10n);
  }

  String _getContentForType(
    String type,
    String content,
    AppLocalizations l10n,
  ) {
    switch (type) {
      case 'image':
        return l10n.imageMessage;
      case 'video':
        return l10n.videoMessage;
      case 'document':
        return l10n.documentMessage;
      default:
        return content;
    }
  }
}

// Animation wrapper for list items
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOut,
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeOut,
          ),
        ),
        child: child,
      ),
    );
  }
}
