// lib/pages/community/chat_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_model.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  List<Message> get messages => _messages;
  RealtimeChannel? _subscription;

  Future<void> fetchMessages(String currentUserId, String otherUserId) async {
    try {
      final response = await Supabase.instance.client
          .from('communitymessages')
          .select()
          .or(
            'sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId,sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId',
          )
          .order('created_at', ascending: true);

      _messages = response.map<Message>((map) => Message.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response =
          await Supabase.instance.client
              .from('communitymessages')
              .insert({
                'sender_id': senderId,
                'receiver_id': receiverId,
                'content': content,
              })
              .select()
              .single();

      _messages.add(Message.fromMap(response));
      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markAsSeen(String messageId) async {
    try {
      await Supabase.instance.client
          .from('communitymessages')
          .update({'is_seen': true})
          .eq('id', messageId);

      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index].isSeen = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking message as seen: $e');
    }
  }

  void subscribeToMessages(String currentUserId, String otherUserId) {
    _subscription =
        Supabase.instance.client
            .channel('communitymessages')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'communitymessages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'sender_id',
                value: otherUserId,
              ),
              callback: (payload) {
                final message = Message.fromMap(payload.newRecord);
                if (message.receiverId == currentUserId) {
                  _messages.add(message);
                  markAsSeen(message.id);
                  notifyListeners();
                }
              },
            )
            .subscribe();
  }

  void unsubscribe() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
      _subscription = null;
    }
  }
}
