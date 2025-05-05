import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_provider.dart';
import 'message_model.dart';

class PeerChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const PeerChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<PeerChatScreen> createState() => _PeerChatScreenState();
}

class _PeerChatScreenState extends State<PeerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      print('Initializing chat with receiver: ${widget.receiverId}');
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.id.isEmpty) {
        print('Authentication error: No user logged in');
        throw Exception('User not authenticated');
      }
      _currentUserId = user.id;
      print('Authenticated user ID: $_currentUserId');

      final chatProvider = context.read<ChatProvider>();
      print(
        'Fetching messages for user $_currentUserId and receiver ${widget.receiverId}',
      );
      await chatProvider.fetchMessages(_currentUserId!, widget.receiverId);
      print('Fetched ${chatProvider.messages.length} messages');
      chatProvider.subscribeToMessages(_currentUserId!, widget.receiverId);
      print('Subscribed to real-time message updates');

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (e) {
      print('Chat initialization error: $e, Type: ${e.runtimeType}');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _displayError(e);
    }
  }

  void _displayError(dynamic error) {
    final l10n = AppLocalizations.of(context)!;
    String message = l10n.unableToLoadChat;
    if (error.toString().contains(
      'relation "public.communitymessages" does not exist',
    )) {
      message = l10n.chatServiceUnavailable;
    } else if (error.toString().contains('User not authenticated')) {
      message = l10n.pleaseLogInChat;
    } else if (error is PostgrestException) {
      message = l10n.databaseError(error.message);
    } else if (error.toString().contains('network')) {
      message = l10n.networkError;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: l10n.retryButton,
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: _initializeChat,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    try {
      print('Sending message: "${_messageController.text}"');
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.sendMessage(
        senderId: _currentUserId!,
        receiverId: widget.receiverId,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
      print('Message sent successfully');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Message send error: $e, Type: ${e.runtimeType}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToSendMessage(e.toString()),
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

  @override
  void dispose() {
    print('Disposing chat screen');
    context.read<ChatProvider>().unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildChatBody(ChatProvider chatProvider) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.unableToLoadChat,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              style: theme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.primary,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.onPrimary,
                ),
              ),
              child: Text(
                l10n.retryButton,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (chatProvider.messages.isEmpty) {
      return Center(
        child: Text(
          l10n.startChatting(widget.receiverName),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
            itemCount: chatProvider.messages.length,
            itemBuilder: (context, index) {
              final message = chatProvider.messages[index];
              final isSender = message.senderId == _currentUserId;
              if (index == 0) {
                print(
                  'Displaying messages: ${chatProvider.messages.map((m) => "${m.content} @ ${m.createdAt}")}',
                );
              }
              return _buildMessageBubble(message, isSender);
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isSender) {
    final theme = Theme.of(context);
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label:
            isSender
                ? 'Sent message: ${message.content}'
                : 'Received message: ${message.content}',
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSender
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSender
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeago.format(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isSender
                              ? theme.colorScheme.onPrimary.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (isSender && message.isSeen)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 14,
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              controller: _messageController,
              enabled: !_hasError,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    _hasError ? l10n.chatUnavailableHint : l10n.typeMessageHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      _hasError
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    _hasError
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.send,
              color:
                  _hasError
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
            ),
            onPressed: _hasError ? null : _sendMessage,
            tooltip: l10n.sendMessageTooltip,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: theme.appBarTheme.elevation,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
              : Consumer<ChatProvider>(
                builder:
                    (context, chatProvider, _) => _buildChatBody(chatProvider),
              ),
    );
  }
}
