import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/tax_engine.dart';
import '../services/tax_service.dart';

class TaxesScreen extends StatefulWidget {
  const TaxesScreen({super.key});
  @override
  State<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends State<TaxesScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = true;

  // Tax summary
  Map<String, dynamic> _taxSummary = {};
  List<Map<String, dynamic>> _taxableInvoices = [];
  List<Map<String, dynamic>> _taxFilings = [];
  
  // Settings
  String _country = "السعودية";
  double _taxRate = 0.15;
  String _invoiceFilter = 'all';

  // Config from Engine
  final Map<String, TaxConfig> _allConfigs = TaxEngine.globalTaxConfigs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _taxSummary = await _db.getTaxSummary();
      _taxableInvoices = await _db.getTaxableInvoices(type: _invoiceFilter);
      _taxFilings = await _db.getTaxFilings();
      
      // Trigger Smart Alerts in background
      TaxService().checkAndTriggerTaxAlerts();
    } catch (e) { debugPrint("Tax load error: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = TaxEngine.getConfigForCountry(_country);
    final currency = _country == "USA" ? "\$" : (_country == "Saudi Arabia" ? "ر.س" : "AED"); // Simplified for demo; should be dynamic

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("نظام الضرائب الشامل", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                  Text("${config.taxName} ${config.standardRate}% • $_country", style: TextStyle(color: primaryOrange, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
                ])),
                _buildCountrySwitcher(context),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.black87,
              unselectedLabelColor: context.mutedText,
              indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: "الملخص"), Tab(text: "الفواتير"), Tab(text: "الإقرارات"), Tab(text: "الإعدادات")],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : TabBarView(controller: _tabController, children: [
                  _buildSummaryTab(currency),
                  _buildInvoicesTab(currency),
                  _buildFilingsTab(currency),
                  _buildSettingsTab(),
                ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 0: الملخص الضريبي
  // ═══════════════════════════════════════════════════
  Widget _buildSummaryTab(String currency) {
    final salesTax = (_taxSummary['sales_tax'] as num?)?.toDouble() ?? 0;
    final purchaseTax = (_taxSummary['purchase_tax'] as num?)?.toDouble() ?? 0;
    final netTax = salesTax - purchaseTax;
    final salesCount = (_taxSummary['sales_count'] as num?)?.toInt() ?? 0;
    final purchaseCount = (_taxSummary['purchase_count'] as num?)?.toInt() ?? 0;
    final totalSales = (_taxSummary['total_sales'] as num?)?.toDouble() ?? 0;
    final totalPurchases = (_taxSummary['total_purchases'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(children: [
            Expanded(child: _buildTaxKPI("ضريبة المبيعات\n(المحصّلة)", salesTax, currency, Icons.trending_up, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildTaxKPI("ضريبة المشتريات\n(المدفوعة)", purchaseTax, currency, Icons.trending_down, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildTaxKPI("صافي الضريبة\n(المستحقة)", netTax, currency, Icons.gavel, netTax > 0 ? Colors.red : Colors.green, isPrimary: true)),
          ]),
          const SizedBox(height: 16),

          // Detailed breakdown
          Text("تفاصيل الربع الحالي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 8),
          _buildDetailRow("إجمالي المبيعات", "${totalSales.toStringAsFixed(2)} $currency", "$salesCount فاتورة"),
          _buildDetailRow("إجمالي المشتريات", "${totalPurchases.toStringAsFixed(2)} $currency", "$purchaseCount فاتورة"),
          _buildDetailRow("نسبة الضريبة المطبقة", "${(_taxRate * 100).toInt()}%", _country),
          
          const SizedBox(height: 16),
          // Quick filing button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.upload_file, color: Colors.black87),
              label: const Text("تقديم إقرار ضريبي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              onPressed: () => _submitFiling(salesTax, purchaseTax, netTax),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: BorderSide(color: primaryOrange.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: Icon(Icons.picture_as_pdf, color: primaryOrange),
              label: Text("تصدير تقرير PDF", style: TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
              onPressed: () => _exportTaxPDF(salesTax, purchaseTax, netTax),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 1: الفواتير الضريبية
  // ═══════════════════════════════════════════════════
  Widget _buildInvoicesTab(String currency) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            _buildFilterChip("الكل", 'all'),
            const SizedBox(width: 8),
            _buildFilterChip("المبيعات", 'sales'),
            const SizedBox(width: 8),
            _buildFilterChip("المشتريات", 'purchase'),
            const Spacer(),
            Text("${_taxableInvoices.length} فاتورة", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _taxableInvoices.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.receipt_long, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text("لا توجد فواتير ضريبية", style: TextStyle(color: context.mutedText)),
              ]))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                itemCount: _taxableInvoices.length,
                itemBuilder: (_, i) {
                  final inv = _taxableInvoices[i];
                  final isSales = inv['inv_type'] == 'sales';
                  final tax = (inv['tax_amount'] as num?)?.toDouble() ?? 0;
                  final total = (inv['total'] as num?)?.toDouble() ?? 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.cardSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (isSales ? Colors.green : Colors.blue).withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: (isSales ? Colors.green : Colors.blue).withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(isSales ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: isSales ? Colors.green : Colors.blue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(isSales ? "فاتورة مبيعات" : "فاتورة مشتريات", style: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold)),
                        Text(inv['issue_date']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 3, color: context.mutedText)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text("${total.toStringAsFixed(2)} $currency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
                        Text("ضريبة: ${tax.toStringAsFixed(2)}", style: TextStyle(fontSize: context.bodySize - 3, color: primaryOrange)),
                      ]),
                    ]),
                  );
                },
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 2: سجل الإقرارات
  // ═══════════════════════════════════════════════════
  Widget _buildFilingsTab(String currency) {
    if (_taxFilings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.description, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text("لم يتم تقديم أي إقرارات بعد", style: TextStyle(color: context.mutedText)),
        const SizedBox(height: 8),
        Text("استخدم زر 'تقديم إقرار' في صفحة الملخص", style: TextStyle(color: context.mutedText, fontSize: 12)),
      ]));
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(context.sectionPadding),
      itemCount: _taxFilings.length,
      itemBuilder: (_, i) {
        final f = _taxFilings[i];
        final status = f['status']?.toString() ?? 'draft';
        final isDraft = status == 'draft';
        final net = (f['net_tax_due'] as num?)?.toDouble() ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDraft ? Colors.orange : Colors.green).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDraft ? Colors.orange : Colors.green).withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (isDraft ? Colors.orange : Colors.green).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.description, color: isDraft ? Colors.orange : Colors.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f['period_label']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
              Row(children: [
                Text("${f['start_date']} → ${f['end_date']}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${net.toStringAsFixed(2)} $currency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: (isDraft ? Colors.orange : Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(isDraft ? "مسودة" : "مقدم", style: TextStyle(color: isDraft ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 3: الإعدادات الضريبية
  // ═══════════════════════════════════════════════════
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("إعدادات الضريبة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 16),
          _buildSettingCard("الدولة", _country, Icons.flag, () {
            showDialog(context: context, builder: (ctx) => SimpleDialog(
              title: const Text("اختر الدولة"),
              children: _allConfigs.keys.map((c) => SimpleDialogOption(
                onPressed: () { 
                  setState(() { 
                    _country = c; 
                    _taxRate = _allConfigs[c]!.standardRate / 100; 
                  }); 
                  Navigator.pop(ctx); 
                  _loadData(); 
                },
                child: Text(c, style: const TextStyle(fontSize: 16)),
              )).toList(),
            ));
          }),
          _buildSettingCard("نسبة الضريبة", "${(_taxRate * 100).toInt()}%", Icons.percent, null),
          _buildSettingCard("العملة", _country == "Saudi Arabia" ? "ر.س" : "AED", Icons.monetization_on, null),
          _buildSettingCard("فترة التقديم", "ربع سنوي", Icons.date_range, null),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════
  
  Future<void> _submitFiling(double salesTax, double purchaseTax, double netTax) async {
    final now = DateTime.now();
    final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final quarterEnd = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0);
    
    await _db.saveTaxFiling({
      'id': const Uuid().v4(),
      'period_label': 'Q${((now.month - 1) ~/ 3) + 1} ${now.year}',
      'start_date': quarterStart.toIso8601String().substring(0, 10),
      'end_date': quarterEnd.toIso8601String().substring(0, 10),
      'country': _country,
      'tax_rate': _taxRate,
      'total_sales_tax': salesTax,
      'total_purchase_tax': purchaseTax,
      'net_tax_due': netTax,
      'status': 'filed',
      'filed_at': now.toIso8601String(),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم تقديم الإقرار الضريبي بنجاح"), backgroundColor: Colors.green));
    }
    _loadData();
  }

  Future<void> _exportTaxPDF(double salesTax, double purchaseTax, double netTax) async {
    try {
      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();
      final config = TaxEngine.getConfigForCountry(_country);
      final currency = _country == "Saudi Arabia" ? "ر.س" : "AED"; 

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4, textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text('تقرير الإقرار الضريبي', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange))),
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('$_country - ${config.taxName}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700))),
          pw.SizedBox(height: 20), pw.Divider(), pw.SizedBox(height: 20),
          pw.Text('ضريبة المبيعات (المحصّلة): ${salesTax.toStringAsFixed(2)} $currency', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('ضريبة المشتريات (المدفوعة): ${purchaseTax.toStringAsFixed(2)} $currency', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.Text('صافي الضريبة المستحقة: ${netTax.toStringAsFixed(2)} $currency', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: netTax > 0 ? PdfColors.red : PdfColors.green)),

          pw.SizedBox(height: 30),
          pw.Text('عدد فواتير المبيعات: ${_taxSummary['sales_count'] ?? 0}', style: pw.TextStyle(fontSize: 14)),
          pw.Text('عدد فواتير المشتريات: ${_taxSummary['purchase_count'] ?? 0}', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 30), pw.Divider(),
          pw.Text('تم التوليد بواسطة نظام حساباتي ERP - ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ]),
      ));

      await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'Tax_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  // ═══════════════════════════════════════════════════
  // Helper Widgets
  // ═══════════════════════════════════════════════════

  Widget _buildCountrySwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: context.cardBorder.withValues(alpha: 0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: ["Saudi Arabia", "UAE", "Egypt"].map((c) {
        bool sel = _country == c;
        return GestureDetector(
          onTap: () { 
            setState(() { 
              _country = c; 
              _taxRate = TaxEngine.getConfigForCountry(c).standardRate / 100; 
            }); 
            _loadData(); 
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sel ? primaryOrange : Colors.transparent, borderRadius: BorderRadius.circular(6)),
            child: Text(_allConfigs[c]?.countryCode ?? c, style: TextStyle(color: sel ? Colors.black87 : context.mutedText, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: context.bodySize - 3)),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildTaxKPI(String title, double value, String currency, IconData icon, Color color, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPrimary ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
          child: Text("${value.toStringAsFixed(2)} $currency", style: TextStyle(fontSize: context.bodySize + 3, fontWeight: FontWeight.bold, color: color)),
        ),
      ]),
    );
  }

  Widget _buildDetailRow(String label, String value, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cardBorder.withValues(alpha: 0.1))),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: context.bodySize - 1))),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(badge, style: TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final sel = _invoiceFilter == value;
    return GestureDetector(
      onTap: () { setState(() => _invoiceFilter = value); _loadData(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: sel ? primaryOrange : context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? primaryOrange : context.cardBorder.withValues(alpha: 0.2))),
        child: Text(label, style: TextStyle(color: sel ? Colors.black87 : context.mutedText, fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
      ),
    );
  }

  Widget _buildSettingCard(String title, String value, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder.withValues(alpha: 0.1))),
        child: Row(children: [
          Icon(icon, size: 20, color: primaryOrange),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: context.bodySize))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: context.mutedText, fontSize: context.bodySize - 1)),
          if (onTap != null) ...[const SizedBox(width: 6), Icon(Icons.arrow_forward_ios, size: 12, color: context.mutedText.withValues(alpha: 0.3))],
        ]),
      ),
    );
  }
}
