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
