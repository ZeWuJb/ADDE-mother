import 'package:adde/pages/chatbot/chat_history.dart';
import 'package:adde/pages/chatbot/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'config.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic>? _motherData; // Store data from 'mothers' table
  List<Map<String, dynamic>> _healthMetrics =
      []; // Store data from 'health_metrics'

  // Dynamic system prompt incorporating mother and health data
  String getSystemPrompt() {
    String bioInfo =
        _motherData != null
            ? "The user's name is ${_motherData!['full_name'] ?? 'unknown'}, age ${_motherData!['age'] ?? 'unknown'}, ${_motherData!['pregnancy_weeks'] ?? 0} weeks pregnant (started ${_motherData!['pregnancy_start_date'] ?? 'unknown'}). Baseline weight: ${_motherData!['weight'] ?? 0} ${_motherData!['weight_unit'] ?? 'kg'}, baseline BP: ${_motherData!['blood_pressure'] ?? 'unknown'} mmHg."
            : "No biography data available for the user.";

    String healthInfo =
        _healthMetrics.isNotEmpty
            ? "Latest health metrics (recorded ${_healthMetrics.last['created_at'] ?? 'unknown'}): BP ${_healthMetrics.last['bp_systolic']}/${_healthMetrics.last['bp_diastolic']} mmHg, HR ${_healthMetrics.last['heart_rate']} bpm, Temp ${_healthMetrics.last['body_temp']}°C, Weight ${_healthMetrics.last['weight']} kg."
            : "No recent health metrics available.";

    return """
You are Adde, a friendly and knowledgeable assistant specializing in pregnancy and child care. Provide accurate, supportive advice on topics like prenatal health, nutrition, baby milestones, postpartum care, and parenting tips. Keep responses concise, empathetic, and tailored to the user's needs. Use the following user data to personalize your responses:
- $bioInfo
- $healthInfo
""";
  }

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: Config.geminiApiKey);
    _fetchMotherData(); // Fetch data on initialization
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _saveCurrentChatOnExit();
    _controller.dispose();
    super.dispose();
  }

  // Fetch mother data from 'mothers' and 'health_metrics' tables
  Future<void> _fetchMotherData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch from 'mothers' table
      final motherResponse =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', userId)
              .maybeSingle(); // Assumes one row per user

      // Fetch from 'health_metrics' table
      final healthResponse = await supabase
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      setState(() {
        _motherData =
            motherResponse != null
                ? Map<String, dynamic>.from(motherResponse)
                : null;
        _healthMetrics = List<Map<String, dynamic>>.from(healthResponse);
      });
    } catch (e) {
      debugPrint("Error fetching mother data: $e");
    }
  }

  // Add a welcome message from Hiwot
  void _addWelcomeMessage() {
    setState(() {
      String welcomeText =
          _motherData != null
              ? "Hello ${_motherData!['full_name'] ?? ''}! I’m Adde, your pregnancy and child care companion. You’re ${_motherData!['pregnancy_weeks'] ?? 0} weeks along—how can I assist you today?"
              : "Hello! I’m Adde, your pregnancy and child care companion. How can I assist you today?";
      _messages.add(
        ChatMessage(
          text: welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
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
          TextPart(getSystemPrompt()), // Updated system prompt with data
          TextPart("User: $userInput"),
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
        title: const Text("Adde - Your Pregnancy Companion"),
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
                                ? DateFormat('HH:mm').format(message.timestamp)
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
                    "Adde is typing...",
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
                      hintText: "Ask Adde anything...",
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
