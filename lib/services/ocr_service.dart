import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> parseInvoiceImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String supplier = "مورد غير معروف";
    double total = 0.0;
    String date = DateTime.now().toIso8601String().split('T')[0];

    // Simple Parsing Logic for Demo
    // In a production app, we would use more complex regex or AI parsing
    final List<String> lines = recognizedText.text.split('\n');
    
    for (var line in lines) {
      // Look for currency symbols or "Total"
      if (line.contains(RegExp(r'Total|الإجمالي|الاجمالي|Sum', caseSensitive: false))) {
        final match = RegExp(r'(\d+[.,]\d+)').firstMatch(line);
        if (match != null) {
          total = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? total;
        }
      }

      // Look for date patterns (YYYY-MM-DD or DD/MM/YYYY)
      final dateMatch = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(line);
      if (dateMatch != null) {
        date = dateMatch.group(1)!;
      }
      
      // Assume the first or second long string is the supplier if it has many letters
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
      'raw_ocr_json': recognizedText.text,
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}
