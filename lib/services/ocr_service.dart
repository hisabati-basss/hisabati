import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ai_service.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final GeminiAiBrain _ai = GeminiAiBrain();

  Future<Map<String, dynamic>> parseInvoiceImage(File image) async {
    // Default values
    String supplier = "مورد غير معروف";
    double total = 0.0;
    String date = DateTime.now().toIso8601String().split('T')[0];

    // Priority: AI Vision (More accurate & Works on Windows)
    if (_ai.getApiKey().isNotEmpty) {
      try {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final prompt = """
حلل هذه الفاتورة واستخرج البيانات التالية بصيغة JSON فقط:
{
  "supplier_name": "اسم المورد",
  "total_amount": 0.0,
  "date": "YYYY-MM-DD"
}
""";
        
        final response = await _ai.processUserCommand(prompt, fileAttachments: [
          {
            "mime_type": "image/jpeg",
            "data": base64Image
          }
        ]);

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final aiParsed = jsonDecode(jsonMatch.group(0)!);
          return {
            'supplier_name': aiParsed['supplier_name'] ?? supplier,
            'total_amount': (aiParsed['total_amount'] as num?)?.toDouble() ?? total,
            'date': aiParsed['date'] ?? date,
            'status': 'pending',
            'attachment_path': image.path,
            'raw_ocr_json': response,
          };
        }
      } catch (e) {
        debugPrint("AI Vision OCR Parsing failed: $e");
      }
    }

    // Fallback: Local ML Kit OCR (Only if not Windows)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final inputImage = InputImage.fromFile(image);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        String rawText = recognizedText.text;

        // Simple Regex Parsing for local fallback
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
      } catch (e) {
        debugPrint("Local ML Kit OCR failed: $e");
      }
    }

    // Ultimate fallback: Manual entry placeholder
    return {
      'supplier_name': supplier,
      'total_amount': total,
      'date': date,
      'status': 'pending',
      'attachment_path': image.path,
      'raw_ocr_json': 'Manual / No OCR',
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
