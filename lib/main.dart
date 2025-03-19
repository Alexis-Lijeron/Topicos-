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
    if (_isLoading) return; // Evitar envíos dobles
    String userMessage = _currentText.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "content": userMessage});
    });
    _stopListening(); // Detener escucha antes de enviar

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
        title: Text("DeepSeek con Voz"),
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
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
