import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

class ExportService {
  /// Exports a list of maps (table data) to a CSV file.
  /// Automatically handles Arabic characters using UTF-8 BOM.
  static Future<void> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      // 1. Prepare Data
      List<List<dynamic>> csvData = [headers, ...rows];
      
      // 2. Convert to CSV String
      String csvContent = const ListToCsvConverter().convert(csvData);
      
      // 3. Add UTF-8 BOM (Essential for Excel to recognize Arabic)
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      final List<int> csvBytes = utf8.encode(csvContent);
      final List<int> combinedBytes = [...bom, ...csvBytes];

      if (kIsWeb) {
        // Handle web export (Share fallback)
        await Printing.sharePdf(
          bytes: Uint8List.fromList(combinedBytes),
          filename: '$fileName.csv',
        );
      } else {
        // 4. Save to temporary directory and share
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/$fileName.csv";
        final file = File(path);
        
        await file.writeAsBytes(combinedBytes);
        
        // Use share dialogue for cross-platform support
        await Printing.sharePdf(
          bytes: Uint8List.fromList(combinedBytes),
          filename: '$fileName.csv',
        );
      }
    } catch (e) {
      debugPrint("Error exporting CSV: $e");
    }
  }

  /// Specialized export for specific accounting data
  static Future<void> exportFinancialReport(String reportName, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;

    List<String> headers = data.first.keys.toList();
    List<List<dynamic>> rows = data.map((map) => map.values.toList()).toList();

    await exportToCsv(
      fileName: "${reportName}_${DateTime.now().millisecondsSinceEpoch}",
      headers: headers,
      rows: rows,
    );
  }
}
