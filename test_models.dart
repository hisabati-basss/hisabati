import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GOOGLE_API_KEY'];
  
  if (apiKey == null || apiKey.isEmpty) {
    print('No API key found');
    return;
  }

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    print('Available Models:');
    for (var model in models) {
      print('- \${model['name']} (supported methods: \${model['supportedGenerationMethods']?.join(', ')})');
    }
  } else {
    print('Failed: \${response.statusCode} - \${response.body}');
  }
}
