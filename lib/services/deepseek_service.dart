import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String apiKey =
      "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"; // Reemplázalo con tu API Key
  static const String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "deepseek/deepseek-r1-zero:free",
        "messages":
            history +
            [
              {"role": "user", "content": message},
            ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data["choices"][0]["message"]["content"];
    } else {
      return "Error al conectar con DeepSeek";
    }
  }
}
