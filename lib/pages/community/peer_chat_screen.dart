import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/message_model.dart';

class PeerChatScreen extends StatefulWidget {
  final String currentMotherId;
  final String otherMotherId;
  final String otherMotherName;

  const PeerChatScreen({
    super.key,
    required this.currentMotherId,
    required this.otherMotherId,
    required this.otherMotherName,
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
  bool _isTyping = false;
  String? _otherProfileImageBase64;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_onTyping);
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      _currentUserId = user.id;
      if (_currentUserId != widget.currentMotherId) {
        throw Exception('Current user ID does not match mother ID');
      }

      final motherData =
          await Supabase.instance.client
              .from('mothers')
              .select('profile_url')
              .eq('user_id', widget.otherMotherId)
              .single();

      final chatProvider = context.read<ChatProvider>();
      await chatProvider.fetchMessages(
        widget.currentMotherId,
        widget.otherMotherId,
      );
      chatProvider.subscribeToMessages(
        widget.currentMotherId,
        widget.otherMotherId,
      );

      setState(() {
        _otherProfileImageBase64 = motherData['profile_url'] as String?;
        _isLoading = false;
        _hasError = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _displayError(e);
    }
  }

  void _onTyping() {
    setState(() => _isTyping = _messageController.text.isNotEmpty);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.sendMessage(
        senderId: widget.currentMotherId,
        receiverId: widget.otherMotherId,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    context.read<ChatProvider>().unsubscribe();
    _messageController.removeListener(_onTyping);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Widget _buildChatBody(ChatProvider chatProvider) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadChat,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeChat,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child:
              chatProvider.messages.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.startChatting(widget.otherMotherName),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        chatProvider.messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == chatProvider.messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                  backgroundImage: _getImageProvider(
                                    _otherProfileImageBase64,
                                  ),
                                  child:
                                      _otherProfileImageBase64 == null ||
                                              _getImageProvider(
                                                    _otherProfileImageBase64,
                                                  ) ==
                                                  null
                                          ? Text(
                                            widget.otherMotherName.isNotEmpty
                                                ? widget.otherMotherName[0]
                                                    .toUpperCase()
                                                : '?',
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('...'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final messageIndex = _isTyping ? index : index;
                      final message = chatProvider.messages[messageIndex];
                      final isSender =
                          message.senderId == widget.currentMotherId;
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
    final isRecent = DateTime.now().difference(message.createdAt).inMinutes < 1;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSender)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  backgroundImage: _getImageProvider(_otherProfileImageBase64),
                  child:
                      _otherProfileImageBase64 == null ||
                              _getImageProvider(_otherProfileImageBase64) ==
                                  null
                          ? Text(
                            message.senderName.isNotEmpty
                                ? message.senderName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondary,
                            ),
                          )
                          : null,
                ),
              ),
            Flexible(
              child: Semantics(
                label:
                    isSender
                        ? '${AppLocalizations.of(context)!.sentMessage}: ${message.content}'
                        : '${AppLocalizations.of(context)!.receivedMessage}: ${message.content}',
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSender
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft:
                          isSender
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                      topRight:
                          isSender
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                    ),
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
                        isSender
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isSender
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeago.format(
                              message.createdAt,
                              locale: AppLocalizations.of(context)!.localeName,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isSender
                                      ? theme.colorScheme.onPrimary.withOpacity(
                                        0.7,
                                      )
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isSender && isRecent)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                message.isSeen ? Icons.done_all : Icons.done,
                                size: 16,
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.7,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    _hasError ? l10n.chatUnavailableHint : l10n.typeMessageHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _messageController.text.trim().isEmpty || _hasError
                      ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: theme.colorScheme.onPrimary,
              onPressed:
                  _messageController.text.trim().isEmpty || _hasError
                      ? null
                      : _sendMessage,
              tooltip: l10n.sendMessageTooltip,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              backgroundImage: _getImageProvider(_otherProfileImageBase64),
              child:
                  _otherProfileImageBase64 == null ||
                          _getImageProvider(_otherProfileImageBase64) == null
                      ? Text(
                        widget.otherMotherName.isNotEmpty
                            ? widget.otherMotherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: theme.colorScheme.onSecondary),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.otherMotherName,
                style: theme.appBarTheme.titleTextStyle?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
