import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final apiKey = 'AIzaSyBXvo4ieifCanuBeFBfOEUhCs7U5ryw32o';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=\$apiKey';

  final body = jsonEncode({
    "contents": [{"parts":[{"text": "Hello"}]}]
  });

  try {
    final response = await http.post(
      Uri.parse(url.replaceAll('\\\$', '\$')),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print("Status: " + response.statusCode.toString());
    print("Body: " + response.body);
  } catch (e) {
    print("Exception: " + e.toString());
  }
}
