import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';

class ReportingService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Fetches the Trial Balance with hierarchy levels
  Future<List<Map<String, dynamic>>> getTrialBalanceReport({int level = 3, bool includePartners = false}) async {
    final db = await _db.database;
    final accounts = await db.query('accounts', orderBy: 'code ASC');
    
    List<Map<String, dynamic>> filtered = [];
    for (var acc in accounts) {
      String code = acc['code']?.toString() ?? '';
      if (level == 1 && code.length <= 1) {
        filtered.add(acc);
      } else if (level == 2 && code.length <= 2) {
        filtered.add(acc);
      } else if (level >= 3) {
        filtered.add(acc);
      }
    }
    
    return filtered;
  }

  /// Calculates Profit & Loss for a specific period, optionally filtered by cost center.
  Future<Map<String, double>> getPNLReport(String startDate, String endDate, {String? costCenterId}) async {
    final db = await _db.database;

    final revRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'revenue'
    ''');
    double totalRevenue = ((revRes.first['total'] as num?)?.toDouble() ?? 0).abs();

    final expRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'expense'
    ''');
    double totalExpense = (expRes.first['total'] as num?)?.toDouble() ?? 0;

    return { 'revenue': totalRevenue, 'expenses': totalExpense, 'net_profit': totalRevenue - totalExpense };
  }

  Future<List<Map<String, dynamic>>> getCostCenterPerformance(String startDate, String endDate) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT jel.cost_center_id, COALESCE(SUM(jel.debit), 0) as total_expenses
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'expense' AND je.date >= ? AND je.date <= ? AND jel.cost_center_id IS NOT NULL
      GROUP BY jel.cost_center_id
    ''', [startDate, endDate]);
  }

  /// AR Aging Report: Categorizes unpaid invoices by age.
  Future<List<Map<String, dynamic>>> getAgingReport() async {
    final db = await _db.database;
    final invoices = await db.query('invoices', where: "status != 'paid'"); // Assuming status exists
    
    DateTime now = DateTime.now();
    Map<String, Map<String, double>> agingByClient = {};

    for (var inv in invoices) {
      String client = inv['client_id']?.toString() ?? 'Unknown';
      DateTime date = DateTime.tryParse(inv['issue_date']?.toString() ?? '') ?? now;
      int days = now.difference(date).inDays;
      double amount = (inv['total'] as num?)?.toDouble() ?? 0;

      agingByClient.putIfAbsent(client, () => {'0-30': 0, '31-60': 0, '61-90': 0, '90+': 0, 'total': 0});
      
      if (days <= 30) agingByClient[client]!['0-30'] = agingByClient[client]!['0-30']! + amount;
      else if (days <= 60) agingByClient[client]!['31-60'] = agingByClient[client]!['31-60']! + amount;
      else if (days <= 90) agingByClient[client]!['61-90'] = agingByClient[client]!['61-90']! + amount;
      else agingByClient[client]!['90+'] = agingByClient[client]!['90+']! + amount;
      
      agingByClient[client]!['total'] = agingByClient[client]!['total']! + amount;
    }

    return agingByClient.entries.map((e) => {'client': e.key, ...e.value}).toList();
  }

  /// Flexible Professional PDF Report Generator
  /// Supports both legacy List<Map> records and new Map data parameters.
  Future<void> generateFinancialPDF({
    String? reportType,
    String? title,
    List<Map<String, dynamic>>? records,
    String? period,
    Map<String, dynamic>? data,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.tajawalMedium();
    final String finalTitle = title ?? reportType ?? "تقرير مالي";
    final String finalPeriod = period ?? "الفترة الحالية";

    // Scenario A: Trial Balance (Specialized Layout)
    if ((reportType != null && (reportType.contains('trial') || reportType.contains('ميزان'))) || finalTitle.contains('ميزان')) {
      final reportData = records ?? await getTrialBalanceReport();
      await generateTrialBalancePDF(
        data: reportData,
        period: finalPeriod,
      );
      return;
    }

    // Scenario B: Standard Table Report
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(finalTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text("تاريخ التقرير: ${DateTime.now().toIso8601String().split('T')[0]}"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("الفترة: $finalPeriod", style: const pw.TextStyle(color: PdfColors.grey700)),
                pw.SizedBox(height: 30),
                if (records != null && records.isNotEmpty)
                  pw.Table.fromTextArray(
                    headers: ['البند', 'القيمة'],
                    data: records.map((r) => [r['label']?.toString() ?? r['name']?.toString() ?? '-', r['value']?.toString() ?? r['balance']?.toString() ?? '0']).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    cellHeight: 25,
                  )
                else
                  pw.Center(child: pw.Text("لا توجد بيانات تفصيلية متوفرة لهذا التقرير حالياً.", style: const pw.TextStyle(color: PdfColors.grey600))),
                
                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text("صُدر آلياً بواسطة نظام حساباتي الذكي", style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Generates a Professional PDF Report for Trial Balance with Logo and Table.
  Future<void> generateTrialBalancePDF({
    required List<Map<String, dynamic>> data,
    required String period,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.tajawalMedium();
    final arabicFontBold = await PdfGoogleFonts.tajawalBold();
    
    final company = {
      'name': 'Hisabati ERP',
      'vat_number': '---',
      'address': 'الرياض',
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company['name'] ?? 'Hisabati ERP', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                    pw.Text("رقم الضريبة: ${company['vat_number'] ?? '-'}", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("ميزان المراجعة", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.Text("الفترة: $period", style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.orange),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['الكود', 'وصف الحساب', 'مدين (Debit)', 'دائن (Credit)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              cellHeight: 25,
              data: data.map((acc) {
                double bal = (acc['balance'] as num?)?.toDouble() ?? 0.0;
                return [acc['code'] ?? '-', acc['name'] ?? '-', bal > 0 ? bal.abs().toStringAsFixed(2) : "-", bal < 0 ? bal.abs().toStringAsFixed(2) : "-"];
              }).toList(),
            ),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Center(child: pw.Text("صُدر بواسطة نظام حساباتي", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Exports data to Excel format with professional columns.
  Future<void> exportTrialBalanceExcel({
    required List<Map<String, dynamic>> data,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['TrialBalance'];
    excel.delete('Sheet1');

    sheetObject.appendRow([TextCellValue("كود الحساب"), TextCellValue("اسم الحساب"), TextCellValue("مدين"), TextCellValue("دائن"), TextCellValue("الرصيد")]);

    for (var acc in data) {
      double bal = (acc['balance'] as num?)?.toDouble() ?? 0.0;
      sheetObject.appendRow([TextCellValue(acc['code']?.toString() ?? ''), TextCellValue(acc['name']?.toString() ?? ''), DoubleCellValue(bal > 0 ? bal : 0.0), DoubleCellValue(bal < 0 ? bal.abs() : 0.0), DoubleCellValue(bal)]);
    }

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/trial_balance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes);
      await Printing.sharePdf(bytes: Uint8List.fromList(fileBytes), filename: 'trial_balance.xlsx');
    }
  }

  Future<void> generateAndShareReport(String reportType, {Map<String, dynamic>? params}) async {
    await generateFinancialPDF(
      reportType: reportType, 
      data: params,
      title: reportType,
      period: "الفترة الحالية",
    );
  }
}
