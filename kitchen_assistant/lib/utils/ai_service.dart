import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kitchen_assistant/config.dart';

class AIService {
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  static Future<String> ask(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful cooking assistant."},
            {"role": "user", "content": prompt},
          ],
        }),
      );

      //  UTF-8 karakterleri
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);

      //  Hatalı yanıt durumu
      if (response.statusCode != 200) {
        return ' API Error: ${data['error']?['message'] ?? 'Unknown error'}';
      }

      final choices = data['choices'];
      if (choices == null || choices.isEmpty) {
        return ' No response: Empty reply from AI';
      }

      final content = choices[0]['message']?['content'];
      if (content == null) {
        return ' No content received from AI.';
      }

      return content.trim();
    } catch (e) {
      return ' Failed to get AI response: $e';
    }
  }
}
