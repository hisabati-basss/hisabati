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
    String ccFilter = costCenterId != null ? "AND jel.cost_center_id = '$costCenterId'" : "";

    final revRes = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.credit - jel.debit), 0) as total 
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'revenue' 
        AND date(je.date) >= date(?) AND date(je.date) <= date(?)
        AND je.is_deleted = 0
        AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND je.id NOT LIKE 'DEMO_%'
        $ccFilter
    ''', [startDate, endDate]);
    double totalRevenue = (revRes.first['total'] as num?)?.toDouble() ?? 0;

    final expRes = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.debit - jel.credit), 0) as total 
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'expense' 
        AND date(je.date) >= date(?) AND date(je.date) <= date(?)
        AND je.is_deleted = 0
        AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND je.id NOT LIKE 'DEMO_%'
        $ccFilter
    ''', [startDate, endDate]);
    double totalExpense = (expRes.first['total'] as num?)?.toDouble() ?? 0;

    return { 'revenue': totalRevenue, 'expenses': totalExpense, 'net_profit': totalRevenue - totalExpense };
  }

  Future<List<Map<String, dynamic>>> getCostCenterPerformance(String startDate, String endDate) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT 
        cc.name,
        COALESCE(SUM(CASE WHEN a.type = 'revenue' THEN jel.credit - jel.debit ELSE 0 END), 0) as revenue,
        COALESCE(SUM(CASE WHEN a.type = 'expense' THEN jel.debit - jel.credit ELSE 0 END), 0) as expenses,
        COALESCE(SUM(CASE WHEN a.type = 'revenue' THEN jel.credit - jel.debit ELSE 0 END) - SUM(CASE WHEN a.type = 'expense' THEN jel.debit - jel.credit ELSE 0 END), 0) as profit
      FROM cost_centers cc
      JOIN journal_entry_lines jel ON cc.id = jel.cost_center_id
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE date(je.date) >= date(?) AND date(je.date) <= date(?)
        AND je.is_deleted = 0
        AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND je.id NOT LIKE 'DEMO_%'
      GROUP BY cc.id
      HAVING revenue != 0 OR expenses != 0
    ''', [startDate, endDate]);
  }

  /// AR Aging Report: Categorizes unpaid credit invoices by age with client names.
  Future<List<Map<String, dynamic>>> getAgingReport() async {
    final db = await _db.database;
    
    final results = await db.rawQuery('''
      SELECT 
        COALESCE(c.name, i.client_id, 'Unknown') as client_name,
        i.issue_date,
        i.total,
        i.id as invoice_id
      FROM invoices i
      LEFT JOIN clients c ON i.client_id = c.id
      WHERE i.payment_type = 'credit' 
        AND i.status != 'paid' 
        AND i.is_deleted = 0 
        AND COALESCE(i.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND i.id NOT LIKE 'DEMO_%'
    ''');
    
    DateTime now = DateTime.now();
    Map<String, Map<String, dynamic>> agingByClient = {};

    for (var inv in results) {
      String clientName = inv['client_name']?.toString() ?? 'Unknown';
      DateTime date = DateTime.tryParse(inv['issue_date']?.toString() ?? '') ?? now;
      int days = now.difference(date).inDays;
      double amount = (inv['total'] as num?)?.toDouble() ?? 0;

      agingByClient.putIfAbsent(clientName, () => {
        'client': clientName,
        '0-30': 0.0,
        '31-60': 0.0,
        '61-90': 0.0,
        '90+': 0.0,
        'total': 0.0
      });
      
      if (days <= 30) agingByClient[clientName]!['0-30'] = agingByClient[clientName]!['0-30']! + amount;
      else if (days <= 60) agingByClient[clientName]!['31-60'] = agingByClient[clientName]!['31-60']! + amount;
      else if (days <= 90) agingByClient[clientName]!['61-90'] = agingByClient[clientName]!['61-90']! + amount;
      else agingByClient[clientName]!['90+'] = agingByClient[clientName]!['90+']! + amount;
      
      agingByClient[clientName]!['total'] = agingByClient[clientName]!['total']! + amount;
    }

    return agingByClient.values.toList();
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

  /// 🏭 Production/Manufacturing Report (Summarized for Analysis)
  Future<Map<String, dynamic>> getProductionReport(String startDate, String endDate) async {
    final db = await _db.database;
    final res = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_orders,
        SUM(total_cost) as total_cost,
        SUM(actual_material_cost) as mat_cost,
        SUM(actual_overhead_cost) as overhead_cost
      FROM manufacturing_orders 
      WHERE date(created_at) BETWEEN date(?) AND date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
    ''', [startDate, endDate]);

    if (res.isEmpty || res.first['total_orders'] == 0) return {'total_orders': 0};
    
    return {
      'total_orders': res.first['total_orders'],
      'total_cost': res.first['total_cost'],
      'mat_cost': res.first['mat_cost'],
      'overhead_cost': res.first['overhead_cost'],
    };
  }

  /// 🕵️ Sales Agent Performance
  Future<List<Map<String, dynamic>>> getAgentPerformanceReport() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT u.name, SUM(i.total) as total_sales, COUNT(i.id) as invoice_count
      FROM invoices i
      JOIN users u ON i.sales_agent_id = u.id
      WHERE i.is_deleted = 0 AND COALESCE(i.device_id, '') NOT IN ('system_seed', 'onboarding_init')
      GROUP BY u.id
      ORDER BY total_sales DESC
    ''');
  }

  /// 🤝 Supplier Performance
  Future<List<Map<String, dynamic>>> getSupplierPerformanceReport() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT s.name, SUM(pi.total) as total_purchases, COUNT(pi.id) as order_count
      FROM purchase_invoices pi
      JOIN suppliers s ON pi.supplier_id = s.id
      WHERE pi.is_deleted = 0 AND COALESCE(pi.device_id, '') NOT IN ('system_seed', 'onboarding_init')
      GROUP BY s.id
      ORDER BY total_purchases DESC
    ''');
  }

  /// 💵 Branch Liquidity
  Future<List<Map<String, dynamic>>> getBranchLiquidityReport() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT b.name, SUM(a.balance) as balance
      FROM accounts a
      JOIN branches b ON a.branch_id = b.id
      WHERE a.type IN ('asset_cash', 'asset_bank') AND COALESCE(a.device_id, '') NOT IN ('system_seed', 'onboarding_init')
      GROUP BY b.id
    ''');
  }

  /// 🔮 Predicted Cash Flow (AI/Trend based)
  Future<List<Map<String, dynamic>>> getPredictedCashFlow(int months) async {
    final currentFlow = await getCashFlowData();
    if (currentFlow.isEmpty) return [];
    
    // Simple average projection for now
    double avgIncome = 0;
    double avgExpense = 0;
    for (var f in currentFlow) {
      avgIncome += (f['income'] as num?)?.toDouble() ?? 0;
      avgExpense += (f['expense'] as num?)?.toDouble() ?? 0;
    }
    avgIncome /= currentFlow.length;
    avgExpense /= currentFlow.length;

    List<Map<String, dynamic>> predictions = [];
    DateTime lastDate = DateTime.now();
    for (int i = 1; i <= months; i++) {
      DateTime next = DateTime(lastDate.year, lastDate.month + i);
      predictions.add({
        'month': "${next.year}-${next.month.toString().padLeft(2, '0')}",
        'income': avgIncome * (1 + (i * 0.05)), // 5% growth projection
        'expense': avgExpense * (1 + (i * 0.02)),
      });
    }
    return predictions;
  }

  /// 💰 Cheque Report PDF
  Future<void> generateChequeReportPDF({required List cheques, required String period}) async {
    await generateFinancialPDF(
      title: "تقرير الشيكات",
      records: cheques.map((c) => {
        'label': "شيك #${c['cheque_number']} - ${c['bank_name']}",
        'value': "${c['amount']} - ${c['status']}"
      }).toList(),
      period: period,
    );
  }

  /// 📊 Monthly Cash Flow (Supporting Method)
  Future<List<Map<String, dynamic>>> getCashFlowData() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', je.date) as month, 
        SUM(CASE WHEN a.type = 'revenue' THEN jel.credit - jel.debit ELSE 0 END) as income,
        SUM(CASE WHEN a.type = 'expense' THEN jel.debit - jel.credit ELSE 0 END) as expense
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE je.is_deleted = 0 
        AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND je.id NOT LIKE 'DEMO_%'
      GROUP BY month
      ORDER BY month ASC
    ''');
  }

  /// 🌍 Global Tax & Zakat Compliance Report (RESTORED)
  Future<Map<String, dynamic>> getGlobalTaxReport(String startDate, String endDate) async {
    final vat = await getVatReport(startDate, endDate);
    final zakatDetails = await _db.calculateZakatEstimate();
    return {
      'vat_summary': vat,
      'zakat_base': zakatDetails['zakat_pool'] ?? 0.0,
      'estimated_zakat': zakatDetails['zakat_due'] ?? 0.0,
      'liquid_assets': zakatDetails['liquid_assets'] ?? 0.0,
      'liabilities': zakatDetails['liabilities'] ?? 0.0,
      'period': '$startDate to $endDate'
    };
  }

  Future<Map<String, double>> getVatReport(String startDate, String endDate) async {
    final db = await _db.database;
    
    // 🛡️ Robust Date Filtering: Ensure we catch the full end day by checking date only or appending time
    final salesRes = await db.rawQuery('''
      SELECT COALESCE(SUM(tax_amount), 0) as total_tax, COALESCE(SUM(subtotal), 0) as total_sales, COALESCE(SUM(total), 0) as total_gross
      FROM invoices 
      WHERE date(issue_date) >= date(?) AND date(issue_date) <= date(?) AND is_deleted = 0
    ''', [startDate, endDate]);
    
    final purchaseRes = await db.rawQuery('''
      SELECT COALESCE(SUM(tax_amount), 0) as total_tax, COALESCE(SUM(total), 0) as total_purchases
      FROM purchase_invoices 
      WHERE date(issue_date) >= date(?) AND date(issue_date) <= date(?) AND is_deleted = 0
    ''', [startDate, endDate]);

    double outputVat = (salesRes.first['total_tax'] as num?)?.toDouble() ?? 0;
    double inputVat = (purchaseRes.first['total_tax'] as num?)?.toDouble() ?? 0;
    double sales = (salesRes.first['total_sales'] as num?)?.toDouble() ?? 0;
    double purchases = (purchaseRes.first['total_purchases'] as num?)?.toDouble() ?? 0;
    double gross = (salesRes.first['total_gross'] as num?)?.toDouble() ?? 0;
    
    return {
      'total_tax': outputVat - inputVat, 
      'total_sales': sales, 
      'total_purchases': purchases,
      'total_gross': gross,
      'output_vat': outputVat,
      'input_vat': inputVat
    };
  }
}
