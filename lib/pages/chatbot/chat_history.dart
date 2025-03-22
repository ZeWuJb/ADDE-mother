import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatHistoryScreen extends StatelessWidget {
  final SupabaseClient supabase;

  const ChatHistoryScreen({super.key, required this.supabase});

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await supabase
        .from("chat_history")
        .select()
        .eq("user_id", userId)
        .order("timestamp", ascending: false); // Newest first
    return response;
  }

  // Clear all chat history
  Future<void> _clearAllHistory(BuildContext context) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from("chat_history").delete().eq("user_id", userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat history cleared")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error clearing history: $e")));
    }
  }

  // Delete individual chat entry
  Future<void> _deleteChatEntry(BuildContext context, int id) async {
    try {
      await supabase.from("chat_history").delete().eq("id", id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chat deleted")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting chat: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hiwot Chat History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              // Confirm before clearing all history
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Clear All History"),
                      content: const Text(
                        "Are you sure you want to delete all chat history? This cannot be undone.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await _clearAllHistory(context);
                Navigator.pop(context); // Refresh by popping and reopening
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading history"));
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return const Center(child: Text("No chat history yet."));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              DateTime? timestamp;
              try {
                timestamp =
                    entry["timestamp"] != null
                        ? DateTime.parse(entry["timestamp"])
                        : null;
              } catch (e) {
                timestamp = null;
              }
              return GestureDetector(
                onLongPress: () async {
                  // Confirm before deleting individual chat
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Delete Chat"),
                          content: const Text(
                            "Are you sure you want to delete this chat?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await _deleteChatEntry(context, entry["id"]);
                    Navigator.pop(context); // Refresh by popping and reopening
                  }
                },
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You: ${entry['message'] ?? 'No message'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Hiwot: ${entry['response'] ?? 'No response'}"),
                        Text(
                          timestamp != null
                              ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp)
                              : "Time unavailable",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
