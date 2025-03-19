import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
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
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _statusText = "Toque para hablar";
  FlutterTts _flutterTts = FlutterTts();
  Timer? _silenceTimer;
  String _currentText = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _sendMessage() async {
    if (_isLoading) return;
    String userMessage = _currentText.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "content": userMessage});
    });
    _stopListening();

    String botResponse = await DeepSeekService().sendMessage(
      userMessage,
      _messages,
    );
    botResponse = botResponse.replaceAll(RegExp(r'\\boxed\{|\}'), '');

    setState(() {
      _messages.add({"role": "bot", "content": botResponse});
      _isLoading = false;
    });

    _speak(botResponse);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _statusText = "Escuchando...";
        _currentText = "";
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _currentText = result.recognizedWords;
          });
          _resetSilenceTimer();
        },
        onSoundLevelChange: (level) {
          _resetSilenceTimer();
        },
      );
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(Duration(seconds: 5), () {
      _sendMessage();
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _statusText = "Toque para hablar";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DeepSeek con Voz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue.shade600 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "Usuario" : "DeepSeek",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          msg["content"] ?? "",
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "DeepSeek está escribiendo...",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 5),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          _isListening ? Colors.redAccent : Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
