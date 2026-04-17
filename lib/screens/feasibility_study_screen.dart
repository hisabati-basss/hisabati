import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class FeasibilityStudyScreen extends StatefulWidget {
  const FeasibilityStudyScreen({super.key});
  @override
  State<FeasibilityStudyScreen> createState() => _FeasibilityStudyScreenState();
}

class _FeasibilityStudyScreenState extends State<FeasibilityStudyScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: "السعودية");
  final _capitalCtrl = TextEditingController();
  final _monthlyCostCtrl = TextEditingController();
  final _monthlyRevenueCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: "5");
  final _discountRateCtrl = TextEditingController(text: "10");

  // Results
  Map<String, dynamic>? _results;
  List<Map<String, dynamic>> _savedStudies = [];
  
  // Scenarios
  String _selectedScenario = 'moderate';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedStudies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _sectorCtrl.dispose(); _countryCtrl.dispose();
    _capitalCtrl.dispose(); _monthlyCostCtrl.dispose(); _monthlyRevenueCtrl.dispose();
    _yearsCtrl.dispose(); _discountRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedStudies() async {
    try { _savedStudies = await _db.getFeasibilityStudies(); } catch (e) { debugPrint("Load studies: $e"); }
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════
  // Financial Calculations
  // ═══════════════════════════════════════════════════

  Map<String, dynamic> _calculate(double capital, double monthlyCost, double monthlyRevenue, int years, double discountRate, String scenario) {
    // Scenario multipliers
    double revenueMultiplier = 1.0;
    double costMultiplier = 1.0;
    switch (scenario) {
      case 'optimistic': revenueMultiplier = 1.2; costMultiplier = 0.9; break;
      case 'pessimistic': revenueMultiplier = 0.75; costMultiplier = 1.15; break;
      default: break;
    }

    final adjRevenue = monthlyRevenue * revenueMultiplier;
    final adjCost = monthlyCost * costMultiplier;
    final monthlyNetCashFlow = adjRevenue - adjCost;
    final annualNetCashFlow = monthlyNetCashFlow * 12;
    final totalMonths = years * 12;

    // NPV: Net Present Value
    double npv = -capital;
    for (int y = 1; y <= years; y++) {
      npv += annualNetCashFlow / pow(1 + discountRate, y);
    }

    // IRR: Internal Rate of Return (Newton-Raphson approximation)
    double irr = _calculateIRR(capital, annualNetCashFlow, years);

    // Payback Period
    int paybackMonths = monthlyNetCashFlow > 0 ? (capital / monthlyNetCashFlow).ceil() : totalMonths + 1;
    if (paybackMonths > totalMonths) paybackMonths = -1; // Never pays back

    // ROI
    double totalProfit = (annualNetCashFlow * years) - capital;
    double roi = capital > 0 ? (totalProfit / capital) * 100 : 0;

    // Success rate (heuristic)
    double successRate = 50;
    if (npv > 0) successRate += 20;
    if (irr > discountRate) successRate += 15;
    if (paybackMonths > 0 && paybackMonths <= 24) successRate += 10;
    if (roi > 30) successRate += 5;
    successRate = successRate.clamp(0, 99);

    // Cash flow projections
    List<Map<String, dynamic>> cashFlows = [];
    double cumulative = -capital;
    for (int y = 0; y <= years; y++) {
      if (y == 0) {
        cashFlows.add({'year': 0, 'inflow': 0.0, 'outflow': capital, 'net': -capital, 'cumulative': cumulative});
      } else {
        cumulative += annualNetCashFlow;
        cashFlows.add({'year': y, 'inflow': adjRevenue * 12, 'outflow': adjCost * 12, 'net': annualNetCashFlow, 'cumulative': cumulative});
      }
    }

    return {
      'npv': npv, 'irr': irr, 'roi': roi,
      'payback_months': paybackMonths,
      'monthly_net': monthlyNetCashFlow,
      'annual_net': annualNetCashFlow,
      'total_profit': totalProfit,
      'success_rate': successRate,
      'cash_flows': cashFlows,
      'scenario': scenario,
    };
  }

  double _calculateIRR(double investment, double annualCashFlow, int years) {
    if (annualCashFlow <= 0) return -1;
    double low = -0.5, high = 5.0;
    for (int iter = 0; iter < 100; iter++) {
      double mid = (low + high) / 2;
      double npv = -investment;
      for (int y = 1; y <= years; y++) { npv += annualCashFlow / pow(1 + mid, y); }
      if (npv.abs() < 0.01) return mid;
      if (npv > 0) { low = mid; } else { high = mid; }
    }
    return (low + high) / 2;
  }

  void _generateStudy() {
    final capital = double.tryParse(_capitalCtrl.text) ?? 0;
    final monthlyCost = double.tryParse(_monthlyCostCtrl.text) ?? 0;
    final monthlyRevenue = double.tryParse(_monthlyRevenueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final discountRate = (double.tryParse(_discountRateCtrl.text) ?? 10) / 100;

    if (capital <= 0 || _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال اسم المشروع ورأس المال"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      final results = _calculate(capital, monthlyCost, monthlyRevenue, years, discountRate, _selectedScenario);
      if (mounted) setState(() { _results = results; _isLoading = false; _tabController.animateTo(1); });
    });
  }

  Future<void> _saveStudy() async {
    if (_results == null) return;
    final capital = double.tryParse(_capitalCtrl.text) ?? 0;
    final monthlyCost = double.tryParse(_monthlyCostCtrl.text) ?? 0;
    final monthlyRevenue = double.tryParse(_monthlyRevenueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final discountRate = (double.tryParse(_discountRateCtrl.text) ?? 10) / 100;

    await _db.saveFeasibilityStudy({
      'id': const Uuid().v4(),
      'project_name': _nameCtrl.text,
      'sector': _sectorCtrl.text,
      'country': _countryCtrl.text,
      'capital': capital,
      'monthly_costs': monthlyCost,
      'monthly_revenue': monthlyRevenue,
      'study_years': years,
      'discount_rate': discountRate,
      'npv': _results!['npv'],
      'irr': _results!['irr'],
      'payback_months': _results!['payback_months'],
      'success_rate': _results!['success_rate'],
      'scenario': _selectedScenario,
    });
    
    await _loadSavedStudies();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حفظ الدراسة بنجاح"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("برنامج دراسات الجدوى", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("تحليل مالي بـ NPV / IRR / ROI", style: TextStyle(color: const Color(0xFF9A66FF), fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            ])),
            if (_results != null) GestureDetector(
              onTap: _saveStudy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.save, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text("حفظ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
          child: TabBar(
            controller: _tabController, isScrollable: false,
            labelColor: Colors.black87, unselectedLabelColor: context.mutedText,
            indicator: BoxDecoration(color: const Color(0xFF9A66FF), borderRadius: BorderRadius.circular(8)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: "معطيات الدراسة"), Tab(text: "النتائج"), Tab(text: "الدراسات المحفوظة")],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _buildFormTab(),
          _buildResultsTab(),
          _buildSavedTab(),
        ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 0: معطيات الدراسة
  // ═══════════════════════════════════════════════════
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF9A66FF).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9A66FF).withValues(alpha: 0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF9A66FF)),
              const SizedBox(width: 8),
              Text("بيانات المشروع", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
            ]),
            const SizedBox(height: 16),
            _buildInput(_nameCtrl, "اسم المشروع *"),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildInput(_sectorCtrl, "القطاع (تقنية، مطاعم...)")),
              const SizedBox(width: 10),
              Expanded(child: _buildInput(_countryCtrl, "الدولة / المدينة")),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.monetization_on, color: Color(0xFF9A66FF), size: 18),
              const SizedBox(width: 8),
              Text("البيانات المالية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            ]),
            const SizedBox(height: 10),
            _buildInput(_capitalCtrl, "رأس المال المبدئي *", isNumber: true),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildInput(_monthlyCostCtrl, "التكاليف الشهرية", isNumber: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput(_monthlyRevenueCtrl, "الإيرادات الشهرية المتوقعة", isNumber: true)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildInput(_yearsCtrl, "سنوات الدراسة", isNumber: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildInput(_discountRateCtrl, "معدل الخصم %", isNumber: true)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        
        // Scenario selector
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("اختر السيناريو", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            const SizedBox(height: 8),
            Row(children: [
              _buildScenarioChip("متفائل", 'optimistic', Colors.green),
              const SizedBox(width: 8),
              _buildScenarioChip("معتدل", 'moderate', Colors.blue),
              const SizedBox(width: 8),
              _buildScenarioChip("متشائم", 'pessimistic', Colors.red),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A66FF), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.analytics, color: Colors.white),
          label: Text(_isLoading ? "جاري التحليل..." : "تشغيل دراسة الجدوى", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          onPressed: _isLoading ? null : _generateStudy,
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 1: النتائج
  // ═══════════════════════════════════════════════════
  Widget _buildResultsTab() {
    if (_results == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.analytics, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text("أدخل بيانات المشروع ثم اضغط 'تشغيل'", style: TextStyle(color: context.mutedText)),
      ]));
    }

    final npv = (_results!['npv'] as double);
    final irr = (_results!['irr'] as double);
    final roi = (_results!['roi'] as double);
    final payback = (_results!['payback_months'] as int);
    final successRate = (_results!['success_rate'] as double);
    final cashFlows = (_results!['cash_flows'] as List<Map<String, dynamic>>);
    final isFeasible = npv > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Verdict
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isFeasible ? Colors.green : Colors.red).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isFeasible ? Colors.green : Colors.red).withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Icon(isFeasible ? Icons.check_circle : Icons.cancel, color: isFeasible ? Colors.green : Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isFeasible ? "المشروع مجدٍ اقتصادياً ✓" : "المشروع غير مجدٍ حالياً ✗", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isFeasible ? Colors.green : Colors.red)),
              Text("نسبة النجاح: ${successRate.toInt()}% • سيناريو: ${_selectedScenario == 'optimistic' ? 'متفائل' : _selectedScenario == 'pessimistic' ? 'متشائم' : 'معتدل'}", style: TextStyle(color: context.mutedText, fontSize: 12)),
            ])),
            GestureDetector(
              onTap: () => _tabController.animateTo(0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: primaryOrange.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                child: Text("تعديل", style: TextStyle(color: primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // KPI Row
        Row(children: [
          Expanded(child: _buildMetricCard("NPV", npv.toStringAsFixed(0), "صافي القيمة الحالية", npv > 0 ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricCard("IRR", "${(irr * 100).toStringAsFixed(1)}%", "معدل العائد الداخلي", irr > 0 ? const Color(0xFF9A66FF) : Colors.red)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildMetricCard("ROI", "${roi.toStringAsFixed(1)}%", "العائد على الاستثمار", roi > 0 ? Colors.blue : Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricCard("فترة الاسترداد", payback > 0 ? "$payback شهر" : "لا يسترد", "Payback Period", payback > 0 && payback <= 24 ? Colors.green : Colors.orange)),
        ]),
        const SizedBox(height: 16),

        // Cash Flow Table
        Text("التدفقات النقدية المتوقعة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF9A66FF).withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(children: [
                const Expanded(child: Text("السنة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Expanded(child: Text("التدفق السنوي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Expanded(child: Text("التراكمي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ]),
            ),
            ...cashFlows.map((cf) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.05)))),
              child: Row(children: [
                Expanded(child: Text(cf['year'] == 0 ? "استثمار" : "السنة ${cf['year']}", style: TextStyle(fontSize: 12))),
                Expanded(child: Text("${(cf['net'] as double).toStringAsFixed(0)}", style: TextStyle(fontSize: 12, color: (cf['net'] as double) >= 0 ? Colors.green : Colors.red))),
                Expanded(child: Text("${(cf['cumulative'] as double).toStringAsFixed(0)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (cf['cumulative'] as double) >= 0 ? Colors.green : Colors.red))),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Export buttons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: BorderSide(color: const Color(0xFF9A66FF).withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF9A66FF)),
            label: const Text("تصدير PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A66FF))),
            onPressed: () => _exportFeasibilityPDF(npv, irr, roi, payback, successRate, cashFlows),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.save, color: Colors.white, size: 16),
            label: const Text("حفظ الدراسة", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: _saveStudy,
          )),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 2: الدراسات المحفوظة
  // ═══════════════════════════════════════════════════
  Widget _buildSavedTab() {
    if (_savedStudies.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text("لا توجد دراسات محفوظة", style: TextStyle(color: context.mutedText)),
      ]));
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.sectionPadding),
      itemCount: _savedStudies.length,
      itemBuilder: (_, i) {
        final s = _savedStudies[i];
        final npv = (s['npv'] as num?)?.toDouble() ?? 0;
        final success = (s['success_rate'] as num?)?.toDouble() ?? 0;
        final isFeasible = npv > 0;
        
        return Dismissible(
          key: Key(s['id']?.toString() ?? '$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          onDismissed: (_) async {
            await _db.deleteFeasibilityStudy(s['id']);
            _loadSavedStudies();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isFeasible ? Colors.green : Colors.red).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isFeasible ? Colors.green : Colors.red).withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF9A66FF).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.analytics, size: 18, color: Color(0xFF9A66FF)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['project_name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                Text("${s['sector'] ?? ''} • ${s['country'] ?? ''} • ${s['created_at']?.toString().substring(0, 10) ?? ''}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(isFeasible ? "مجدٍ ✓" : "غير مجدٍ ✗", style: TextStyle(color: isFeasible ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                Text("نجاح: ${success.toInt()}%", style: TextStyle(color: context.mutedText, fontSize: 11)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _exportFeasibilityPDF(double npv, double irr, double roi, int payback, double success, List<Map<String, dynamic>> cashFlows) async {
    try {
      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4, textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text('دراسة الجدوى الاقتصادية', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple))),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Text(_nameCtrl.text, style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700))),
          pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 16),
          pw.Text('القطاع: ${_sectorCtrl.text}   |   الدولة: ${_countryCtrl.text}', style: pw.TextStyle(fontSize: 13)),
          pw.Text('رأس المال: ${_capitalCtrl.text}   |   سنوات الدراسة: ${_yearsCtrl.text}', style: pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 16),
          pw.Text('نتائج التحليل المالي', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('صافي القيمة الحالية (NPV): ${npv.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, color: npv > 0 ? PdfColors.green : PdfColors.red)),
          pw.Text('معدل العائد الداخلي (IRR): ${(irr * 100).toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14)),
          pw.Text('العائد على الاستثمار (ROI): ${roi.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14)),
          pw.Text('فترة الاسترداد: ${payback > 0 ? "$payback شهر" : "لا يسترد"}', style: pw.TextStyle(fontSize: 14)),
          pw.Text('نسبة النجاح المتوقعة: ${success.toInt()}%', style: pw.TextStyle(fontSize: 14, color: PdfColors.deepPurple)),
          pw.SizedBox(height: 20),
          pw.Text('التدفقات النقدية:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['السنة', 'التدفق السنوي', 'التراكمي'],
            data: cashFlows.map((cf) => [
              cf['year'] == 0 ? 'استثمار' : 'السنة ${cf['year']}',
              (cf['net'] as double).toStringAsFixed(0),
              (cf['cumulative'] as double).toStringAsFixed(0),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            cellStyle: pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 30), pw.Divider(),
          pw.Text('حساباتي ERP - ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ]),
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'Feasibility_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  // ═══════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════

  Widget _buildInput(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: context.textColor),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: context.mutedText, fontSize: 13),
        filled: true, fillColor: context.cardSurface.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 8),
        FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
          child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color))),
        Text(subtitle, style: TextStyle(color: context.mutedText, fontSize: 10)),
      ]),
    );
  }

  Widget _buildScenarioChip(String label, String value, Color color) {
    final sel = _selectedScenario == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedScenario = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : context.cardBorder),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : context.mutedText, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
