import 'package:adde/pages/chatbot/chat_history.dart';
import 'package:adde/pages/chatbot/chat_message.dart'; // Ensure this path matches your project structure
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // For Gemini API
import 'config.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  // System prompt with "Hiwot"
  final String systemPrompt = """
You are Hiwot, a friendly and knowledgeable assistant specializing in pregnancy and child care. Provide accurate, supportive advice on topics like prenatal health, nutrition, baby milestones, postpartum care, and parenting tips. Keep responses concise, empathetic, and tailored to the user's needs.
""";

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: Config.geminiApiKey);
    _addWelcomeMessage(); // Only add welcome message, no history loading
  }

  @override
  void dispose() {
    _saveCurrentChatOnExit();
    _controller.dispose();
    super.dispose();
  }

  // Add a welcome message from Hiwot
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I’m Hiwot, your pregnancy and child care companion. How can I assist you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  // Load chat history from Supabase (kept for potential future use, not called automatically)
  Future<void> _loadChatHistory() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from("chat_history")
          .select()
          .eq("user_id", userId)
          .order("timestamp", ascending: true);

      setState(() {
        _messages.clear();
        for (var msg in response) {
          DateTime? parsedTimestamp;
          try {
            parsedTimestamp =
                msg["timestamp"] != null
                    ? DateTime.parse(msg["timestamp"])
                    : DateTime.now();
          } catch (e) {
            parsedTimestamp = DateTime.now();
          }

          _messages.add(
            ChatMessage(
              text: msg["message"] ?? "No message",
              isUser: true,
              timestamp: parsedTimestamp,
            ),
          );
          _messages.add(
            ChatMessage(
              text: msg["response"] ?? "No response",
              isUser: false,
              timestamp: parsedTimestamp,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Error loading chat history: $e");
    }
  }

  // Send message asynchronously with streaming
  Future<void> _sendMessage(String userInput) async {
    if (userInput.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(text: userInput, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    // Add a placeholder for the streaming response
    int streamMessageIndex = _messages.length;
    _messages.add(
      ChatMessage(text: "", isUser: false, timestamp: DateTime.now()),
    );

    StringBuffer responseBuffer = StringBuffer();
    await for (final chunk in _getGeminiResponse(userInput)) {
      setState(() {
        responseBuffer.write(chunk);
        _messages[streamMessageIndex] = ChatMessage(
          text: responseBuffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }

    setState(() {
      _isLoading = false;
    });

    _saveToSupabase(userInput, responseBuffer.toString());
    _controller.clear();
  }

  // Gemini API call using promptStream
  Stream<String> _getGeminiResponse(String userInput) async* {
    try {
      final stream = Gemini.instance.promptStream(
        parts: [
          TextPart(systemPrompt), // System prompt as a TextPart
          TextPart("User: $userInput"), // User input as a TextPart
        ],
      );
      await for (final response in stream) {
        final content = response?.content;
        if (content == null || content.parts!.isEmpty) {
          yield "Error: No response content from Gemini";
          return;
        }
        final text = content.parts!
            .map((part) => part is TextPart ? part.text ?? "" : part.toString())
            .join(" ");
        if (text.isEmpty) {
          yield "Error: Empty response from Gemini";
          return;
        }
        yield text;
      }
    } catch (e) {
      debugPrint("Gemini error: $e");
      yield "Error: Failed to get response - $e";
    }
  }

  // Save chat to Supabase
  Future<void> _saveToSupabase(String userMessage, String botResponse) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      await supabase.from("chat_history").insert({
        "user_id": userId,
        "message": userMessage,
        "response": botResponse,
        "timestamp": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase save error: $e");
    }
  }

  // Save current chat when exiting
  Future<void> _saveCurrentChatOnExit() async {
    for (int i = 0; i < _messages.length - 1; i += 2) {
      if (_messages[i].isUser && !_messages[i + 1].isUser) {
        await _saveToSupabase(_messages[i].text, _messages[i + 1].text);
      }
    }
  }

  // Clear chat
  void _clearChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hiwot - Your Pregnancy Companion"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatHistoryScreen(supabase: supabase),
                  ),
                ),
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _clearChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Align(
                    alignment:
                        message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color:
                            message.isUser
                                ? Colors.pink[100]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.text),
                          Text(
                            message.timestamp != null
                                ? DateFormat('HH:mm').format(message.timestamp!)
                                : "Time unavailable",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Text(
                    "Hiwot is typing...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask Hiwot anything...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed:
                      _isLoading ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
