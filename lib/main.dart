import 'package:flutter/material.dart';
import 'services/deepseek_service.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: ChatScreen());
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _isLoading = true;
    });
    _controller.clear();

    String botResponse = await DeepSeekService().sendMessage(
      userMessage,
      _messages,
    );
    botResponse = botResponse.replaceAll(
      RegExp(r'\\boxed\{|\}'),
      '',
    ); 

    setState(() {
      _messages.add({"role": "bot", "content": botResponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeepSeek"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "Usuario:" : "DeepSeek:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          msg["content"] ?? "",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
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
