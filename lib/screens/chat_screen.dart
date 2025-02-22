import 'package:flutter/material.dart';
import '../providers/ai_chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AIChatService _aiChatService = AIChatService();
  final TextEditingController _controller = TextEditingController();

  List<Map<String, String>> messages = []; // Stores chat history

  void _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'text': userMessage});
    });

    _controller.clear();

    String aiResponse = await _aiChatService.sendMessage(userMessage);

    setState(() {
      messages.add({'role': 'ai', 'text': aiResponse});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Container(
                  alignment: msg['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: EdgeInsets.all(10),
                  child: Text(msg['text']!,
                      style: TextStyle(
                          color: msg['role'] == 'user'
                              ? Colors.blue
                              : Colors.black)),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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
