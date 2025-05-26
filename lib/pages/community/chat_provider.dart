import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/pages/community/message_model.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  RealtimeChannel? _channel;

  List<Message> get messages => _messages;

  Future<void> fetchMessages(
    String currentMotherId,
    String otherMotherId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('communitymessages')
          .select(
            '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
          )
          .or(
            'and(sender_id.eq.$currentMotherId,receiver_id.eq.$otherMotherId),'
            'and(sender_id.eq.$otherMotherId,receiver_id.eq.$currentMotherId)',
          )
          .order('created_at', ascending: true);

      _messages = response.map<Message>((map) => Message.fromMap(map)).toList();
      notifyListeners();
      print(
        'Fetched ${_messages.length} messages for $currentMotherId ↔ $otherMotherId',
      );

      // Mark messages as seen for the current user
      await _markMessagesAsSeen(currentMotherId, otherMotherId);
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<void> _markMessagesAsSeen(
    String currentMotherId,
    String otherMotherId,
  ) async {
    try {
      await Supabase.instance.client
          .from('communitymessages')
          .update({'is_seen': true})
          .eq('receiver_id', currentMotherId)
          .eq('sender_id', otherMotherId)
          .eq('is_seen', false);
      print('Marked messages as seen for $currentMotherId from $otherMotherId');
    } catch (e) {
      print('Error marking messages as seen: $e');
      // Optionally notify user via UI, but don't rethrow to avoid breaking message display
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
                'is_seen': false,
              })
              .select(
                '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
              )
              .single();

      _messages.add(Message.fromMap(response));
      notifyListeners();
      print('Sent message from $senderId to $receiverId');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  void subscribeToMessages(String currentMotherId, String otherMotherId) {
    // Use unique channel name to avoid conflicts
    final channelName = 'messages:$currentMotherId:$otherMotherId';
    _channel = Supabase.instance.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'communitymessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentMotherId,
          ),
          callback: (payload) async {
            try {
              final response =
                  await Supabase.instance.client
                      .from('communitymessages')
                      .select(
                        '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
                      )
                      .eq('id', payload.newRecord['id'])
                      .single();
              final message = Message.fromMap(response);
              // Only add messages between currentMotherId and otherMotherId
              if ((message.senderId == currentMotherId &&
                      message.receiverId == otherMotherId) ||
                  (message.senderId == otherMotherId &&
                      message.receiverId == currentMotherId)) {
                _messages.add(message);
                notifyListeners();
                print('New message added via subscription: ${message.id}');

                // Mark message as seen if this user is the receiver
                if (message.receiverId == currentMotherId) {
                  await _markMessagesAsSeen(currentMotherId, otherMotherId);
                }
              }
            } catch (e) {
              print('Error in message subscription: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('Subscription status: $status for $channelName');
          if (status == 'CHANNEL_ERROR') {
            print('Message subscription error: $error');
          } else if (status == 'SUBSCRIBED') {
            print(
              'Subscribed to messages for $currentMotherId ↔ $otherMotherId',
            );
          }
        });
  }

  void unsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      print('Unsubscribed from message channel');
    }
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
