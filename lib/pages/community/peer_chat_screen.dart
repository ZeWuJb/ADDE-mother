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
    String message = 'Unable to load chat. Please try again.';
    if (error.toString().contains(
      'relation "public.communitymessages" does not exist',
    )) {
      message = 'Chat service unavailable. Contact support.';
    } else if (error.toString().contains('User not authenticated')) {
      message = 'Please log in to access chat.';
    } else if (error is PostgrestException) {
      message = 'Database error: ${error.message}';
    } else if (error.toString().contains('network')) {
      message = 'Network error. Check your connection.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Retry', onPressed: _initializeChat),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null)
      return;

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
          content: Text('Failed to send message: ${e.toString()}'),
          duration: const Duration(seconds: 3),
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
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Unable to load chat',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatProvider.messages.isEmpty) {
      return Center(
        child: Text(
          'Start chatting with ${widget.receiverName}',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
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
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSender ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.createdAt),
                  style: TextStyle(
                    color: isSender ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isSender && message.isSeen)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                hintText: _hasError ? 'Chat unavailable' : 'Type a message...',
                hintStyle: TextStyle(
                  color: _hasError ? Colors.grey[700] : Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _hasError ? Colors.grey[300] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _hasError ? Colors.grey : const Color(0xFFf7a1c4),
            ),
            onPressed: _hasError ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<ChatProvider>(
                builder:
                    (context, chatProvider, _) => _buildChatBody(chatProvider),
              ),
    );
  }
}
