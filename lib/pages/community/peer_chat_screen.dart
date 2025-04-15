import 'package:adde/pages/community/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PeerChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const PeerChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _PeerChatScreenState createState() => _PeerChatScreenState();
}

class _PeerChatScreenState extends State<PeerChatScreen> {
  final _messageController = TextEditingController();
  String? currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in')));
        setState(() {
          _isLoading = false;
        });
        return;
      }
      currentUserId = user.id;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.fetchMessages(currentUserId!, widget.receiverId);
      chatProvider.subscribeToMessages(currentUserId!, widget.receiverId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing chat: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).unsubscribe();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || currentUserId == null) return;

    try {
      await Provider.of<ChatProvider>(context, listen: false).sendMessage(
        senderId: currentUserId!,
        receiverId: widget.receiverId,
        content: _messageController.text,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      reverse: true, // Newest messages at bottom
                      padding: const EdgeInsets.all(16),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];
                        final isSender = message.senderId == currentUserId;
                        return Align(
                          alignment:
                              isSender
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isSender
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        isSender
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeago.format(message.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            isSender
                                                ? Colors.white70
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    if (isSender && message.isSeen)
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFf7a1c4),
                          ),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
