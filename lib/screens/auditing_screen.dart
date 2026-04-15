import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class AuditingScreen extends StatefulWidget {
  const AuditingScreen({super.key});
  @override
  State<AuditingScreen> createState() => _AuditingScreenState();
}

class _AuditingScreenState extends State<AuditingScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _auditSummary = {};
  final Map<int, bool> _checklist = {
    0: false, 1: false, 2: false, 3: false, 4: false, 5: false,
  };
  final List<String> _checklistLabels = [
    "مراجعة القيود اليدوية والتأكد من المرفقات",
    "مطابقة الحسابات البنكية مع الكشوفات",
    "التحقق من أرصدة المخزون والجرد الفعلي",
    "مراجعة فواتير المشتريات المكررة",
    "التأكد من توازن كافة القيود المحاسبية",
    "مراجعة تقارير الميزانية مقابل الفعلي",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _auditSummary = await _db.getAuditSummary();
    } catch (e) { debugPrint("Audit load error: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final issues = (_auditSummary['total_issues'] as int?) ?? 0;
    final score = (_auditSummary['safety_score'] as double?) ?? 100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("برنامج تدقيق الحسابات", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                Text(issues == 0 ? "✅ لا يوجد مخالفات" : "⚠️ $issues مخالفات تحتاج مراجعة", 
                  style: TextStyle(color: issues == 0 ? Colors.green : Colors.orange, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
              ])),
              _buildScoreBadge(score),
            ]),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController, isScrollable: false,
              labelColor: Colors.black87, unselectedLabelColor: context.mutedText,
              indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: "لوحة المخاطر"), Tab(text: "الفحوصات"), Tab(text: "المهام"), Tab(text: "التقرير")],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : TabBarView(controller: _tabController, children: [
                  _buildRiskDashboard(),
                  _buildInspectionsTab(),
                  _buildChecklistTab(),
                  _buildReportTab(),
                ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 0: لوحة المخاطر
  // ═══════════════════════════════════════════════════
  Widget _buildRiskDashboard() {
    final unbalanced = (_auditSummary['unbalanced_entries'] as List?)?.length ?? 0;
    final duplicates = (_auditSummary['duplicate_payments'] as List?)?.length ?? 0;
    final overruns = (_auditSummary['budget_overruns'] as List?)?.length ?? 0;
    final largeTransactions = (_auditSummary['large_transactions'] as List?) ?? [];
    final totalEntries = (_auditSummary['total_entries'] as int?) ?? 0;
    final recentEntries = (_auditSummary['recent_entries'] as int?) ?? 0;
    final score = (_auditSummary['safety_score'] as double?) ?? 100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPI Row
        Row(children: [
          Expanded(child: _buildRiskCard("قيود غير متوازنة", "$unbalanced", Icons.warning, unbalanced > 0 ? Colors.red : Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard("مدفوعات مكررة", "$duplicates", Icons.copy, duplicates > 0 ? Colors.orange : Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard("تجاوزات ميزانية", "$overruns", Icons.trending_up, overruns > 0 ? Colors.red : Colors.green)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildRiskCard("إجمالي القيود", "$totalEntries", Icons.list_alt, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard("قيود آخر 30 يوم", "$recentEntries", Icons.date_range, Colors.purple)),
          const SizedBox(width: 8),
          Expanded(child: _buildRiskCard("نسبة الأمان", "${score.toInt()}%", Icons.security, score >= 90 ? Colors.green : score >= 70 ? Colors.orange : Colors.red)),
        ]),
        
        if (largeTransactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text("عمليات كبيرة (أعلى من 10,000)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 8),
          ...largeTransactions.take(5).map((t) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.attach_money, size: 14, color: Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['description']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text("${t['account_name']} • ${t['date']}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
              ])),
              Text("${((t['debit'] as num?)?.toDouble() ?? (t['credit'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize, color: Colors.orange)),
            ]),
          )),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 1: الفحوصات التلقائية
  // ═══════════════════════════════════════════════════
  Widget _buildInspectionsTab() {
    final unbalanced = (_auditSummary['unbalanced_entries'] as List?) ?? [];
    final duplicates = (_auditSummary['duplicate_payments'] as List?) ?? [];
    final overruns = (_auditSummary['budget_overruns'] as List?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Unbalanced Entries
        _buildInspectionSection("القيود غير المتوازنة", "قيود محاسبية حيث المدين ≠ الدائن", Icons.warning, Colors.red, unbalanced, (e) =>
          "القيد: ${e['id']?.toString().substring(0, 8) ?? ''} | فرق: ${((e['imbalance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} | ${e['date'] ?? ''}"),
        const SizedBox(height: 12),
        
        // Duplicate Payments
        _buildInspectionSection("مدفوعات مكررة محتملة", "فواتير بنفس المبلغ والتاريخ والمورد", Icons.copy, Colors.orange, duplicates, (e) =>
          "المورد: ${e['supplier_name']} | المبلغ: ${e['total']} | التكرار: ${e['occurrence_count']}×"),
        const SizedBox(height: 12),
        
        // Budget Overruns
        _buildInspectionSection("تجاوزات الميزانية", "حسابات تجاوز فعليها الميزانية المحددة", Icons.trending_up, Colors.deepOrange, overruns, (e) =>
          "${e['account_name']} | الميزانية: ${e['budget_amount']} | الفعلي: ${e['actual_amount']} | تجاوز: ${e['overrun']}"),
      ]),
    );
  }

  Widget _buildInspectionSection(String title, String desc, IconData icon, Color color, List items, String Function(Map<String, dynamic>) formatter) {
    final hasIssues = items.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (hasIssues ? color : Colors.green).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (hasIssues ? color : Colors.green).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (hasIssues ? color : Colors.green).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(hasIssues ? icon : Icons.check_circle, size: 16, color: hasIssues ? color : Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            Text(desc, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: (hasIssues ? color : Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(hasIssues ? "${items.length} مشكلة" : "سليم ✓", style: TextStyle(color: hasIssues ? color : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (hasIssues) ...[
          const SizedBox(height: 10),
          ...items.take(5).map((e) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(6)),
            child: Text(formatter(e), style: TextStyle(fontSize: context.bodySize - 2)),
          )),
          if (items.length > 5) Text("...و ${items.length - 5} أخرى", style: TextStyle(color: context.mutedText, fontSize: 11)),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 2: قائمة مهام المدقق
  // ═══════════════════════════════════════════════════
  Widget _buildChecklistTab() {
    final completed = _checklist.values.where((v) => v).length;
    final total = _checklist.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("قائمة مهام المدقق", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("$completed / $total مكتملة", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
          ),
        ]),
        const SizedBox(height: 4),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(value: total > 0 ? completed / total : 0, minHeight: 6, backgroundColor: context.cardSurface, valueColor: const AlwaysStoppedAnimation(primaryOrange)),
        ),
        const SizedBox(height: 16),
        
        ...List.generate(_checklist.length, (i) {
          bool isChecked = _checklist[i] ?? false;
          return GestureDetector(
            onTap: () => setState(() => _checklist[i] = !isChecked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isChecked ? Colors.green.withValues(alpha: 0.06) : context.cardSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isChecked ? Colors.green.withValues(alpha: 0.3) : context.cardBorder.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300), width: 24, height: 24,
                  decoration: BoxDecoration(color: isChecked ? Colors.green : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isChecked ? Colors.green : context.mutedText, width: 1.5)),
                  child: isChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_checklistLabels[i], style: TextStyle(fontSize: context.bodySize, color: isChecked ? context.textColor : context.textColor.withValues(alpha: 0.7), decoration: isChecked ? TextDecoration.lineThrough : null))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 3: التقرير
  // ═══════════════════════════════════════════════════
  Widget _buildReportTab() {
    final score = (_auditSummary['safety_score'] as double?) ?? 100;
    final unbalanced = (_auditSummary['unbalanced_entries'] as List?)?.length ?? 0;
    final duplicates = (_auditSummary['duplicate_payments'] as List?)?.length ?? 0;
    final overruns = (_auditSummary['budget_overruns'] as List?)?.length ?? 0;
    final completed = _checklist.values.where((v) => v).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Score indicator
        Center(child: Column(children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 120, height: 120, child: CircularProgressIndicator(value: score / 100, strokeWidth: 8, backgroundColor: context.cardSurface, valueColor: AlwaysStoppedAnimation(score >= 90 ? Colors.green : score >= 70 ? Colors.orange : Colors.red))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text("${score.toInt()}%", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: score >= 90 ? Colors.green : score >= 70 ? Colors.orange : Colors.red)),
              Text("نسبة الأمان", style: TextStyle(fontSize: 11, color: context.mutedText)),
            ]),
          ]),
          const SizedBox(height: 12),
          Text(score >= 90 ? "الوضع المالي ممتاز" : score >= 70 ? "يحتاج مراجعة بسيطة" : "يحتاج تدخل عاجل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 1)),
        ])),
        const SizedBox(height: 20),

        // Summary table
        _buildReportRow("القيود غير المتوازنة", "$unbalanced", unbalanced == 0 ? Colors.green : Colors.red),
        _buildReportRow("مدفوعات مكررة", "$duplicates", duplicates == 0 ? Colors.green : Colors.orange),
        _buildReportRow("تجاوزات الميزانية", "$overruns", overruns == 0 ? Colors.green : Colors.red),
        _buildReportRow("مهام المدقق المكتملة", "$completed / ${_checklist.length}", completed == _checklist.length ? Colors.green : Colors.orange),
        
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
          label: const Text("تصدير تقرير التدقيق PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          onPressed: () => _exportAuditPDF(score, unbalanced, duplicates, overruns),
        )),
      ]),
    );
  }

  Future<void> _exportAuditPDF(double score, int unbalanced, int duplicates, int overruns) async {
    try {
      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4, textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text('تقرير التدقيق المالي', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange))),
          pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 20),
          pw.Text('نسبة الأمان المالي: ${score.toInt()}%', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: score >= 90 ? PdfColors.green : PdfColors.red)),
          pw.SizedBox(height: 16),
          pw.Text('قيود غير متوازنة: $unbalanced', style: pw.TextStyle(fontSize: 14)),
          pw.Text('مدفوعات مكررة محتملة: $duplicates', style: pw.TextStyle(fontSize: 14)),
          pw.Text('تجاوزات ميزانية: $overruns', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Text('حالة مهام المدقق:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ...List.generate(_checklist.length, (i) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('${_checklist[i] == true ? "✓" : "✗"} ${_checklistLabels[i]}', style: pw.TextStyle(fontSize: 12, color: _checklist[i] == true ? PdfColors.green : PdfColors.red)),
          )),
          pw.SizedBox(height: 30), pw.Divider(),
          pw.Text('حساباتي ERP - ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ]),
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  // ═══════════════════════════════════════════════════
  // Helper Widgets
  // ═══════════════════════════════════════════════════

  Widget _buildScoreBadge(double score) {
    final color = score >= 90 ? Colors.green : score >= 70 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.security, size: 16, color: color),
        const SizedBox(width: 6),
        Text("${score.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ]),
    );
  }

  Widget _buildRiskCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: context.bodySize + 6, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: context.bodySize))),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: context.bodySize)),
      ]),
    );
  }
}
