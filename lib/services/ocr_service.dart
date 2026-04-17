import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ai_service.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final GeminiAiBrain _ai = GeminiAiBrain();

  Future<Map<String, dynamic>> parseInvoiceImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String rawText = recognizedText.text;
    
    // Default values
    String supplier = "مورد غير معروف";
    double total = 0.0;
    String date = DateTime.now().toIso8601String().split('T')[0];

    // Try AI Parsing if possible
    if (_ai.getApiKey().isNotEmpty) {
      try {
        final aiParsed = await _parseWithAI(rawText);
        if (aiParsed != null) {
          return {
            'supplier_name': aiParsed['supplier_name'] ?? supplier,
            'total_amount': (aiParsed['total_amount'] as num?)?.toDouble() ?? total,
            'date': aiParsed['date'] ?? date,
            'status': 'pending',
            'attachment_path': image.path,
            'raw_ocr_json': rawText,
          };
        }
      } catch (e) {
        debugPrint("AI OCR Parsing failed, falling back to regex: $e");
      }
    }

    // Fallback: Simple Regex Parsing
    final List<String> lines = rawText.split('\n');
    for (var line in lines) {
      if (line.contains(RegExp(r'Total|الإجمالي|الاجمالي|Sum', caseSensitive: false))) {
        final match = RegExp(r'(\d+[.,]\d+)').firstMatch(line);
        if (match != null) {
          total = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? total;
        }
      }
      final dateMatch = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(line);
      if (dateMatch != null) date = dateMatch.group(1)!;
      if (supplier == "مورد غير معروف" && line.length > 5 && !line.contains(RegExp(r'\d'))) {
        supplier = line.trim();
      }
    }

    return {
      'supplier_name': supplier,
      'total_amount': total,
      'date': date,
      'status': 'pending',
      'attachment_path': image.path,
      'raw_ocr_json': rawText,
    };
  }

  Future<Map<String, dynamic>?> _parseWithAI(String text) async {
    final prompt = """
حلل النص التالي المستخرج من فاتورة مشتريات واستخرج البيانات التالية بصيغة JSON فقط:
{
  "supplier_name": "اسم المورد",
  "total_amount": 0.0,
  "date": "YYYY-MM-DD"
}
النص المستخرج:
$text
""";

    try {
      final response = await _ai.processUserCommand(prompt);
      // Extract JSON from response (Gemini might wrap it in markdown)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
    } catch (e) {
      debugPrint("Gemini Parse Error: $e");
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
