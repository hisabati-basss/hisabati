import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});
  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _accounts = [];
  double _totalDebit = 0;
  double _totalCredit = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      final endDate = DateTime.now().toIso8601String().split('T')[0];
      
      // Get trial balance: for each account, sum(debit) and sum(credit) from journal_entry_lines
      final accounts = await db.rawQuery('''
        SELECT a.id, a.code, a.name, a.type, a.balance,
          COALESCE((SELECT SUM(jl.debit) FROM journal_entry_lines jl WHERE jl.account_id = a.id), 0) as total_debit,
          COALESCE((SELECT SUM(jl.credit) FROM journal_entry_lines jl WHERE jl.account_id = a.id), 0) as total_credit
        FROM accounts a
        ORDER BY a.code ASC
      ''');
      
      double totalDebit = 0;
      double totalCredit = 0;
      for (var acc in accounts) {
        final bal = (acc['balance'] as num?)?.toDouble() ?? 0;
        if (bal > 0 && (acc['type'] == 'asset' || acc['type'] == 'expense')) {
          totalDebit += bal.abs();
        } else if (bal > 0 && (acc['type'] == 'liability' || acc['type'] == 'revenue')) {
          totalCredit += bal.abs();
        } else if (bal < 0) {
          totalCredit += bal.abs();
        }
      }

      if (mounted) setState(() {
        _accounts = accounts.map((a) => Map<String, dynamic>.from(a)).toList();
        _totalDebit = totalDebit;
        _totalCredit = totalCredit;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Trial balance error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isBalanced = (_totalDebit - _totalCredit).abs() < 0.01;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Ultra Slim Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr('reports.trial_balance.title'),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 14),
                      ],
                    ),
                    Text(
                      isBalanced ? tr('reports.trial_balance.balanced') : tr('reports.trial_balance.unbalanced'),
                      style: TextStyle(color: isBalanced ? Colors.green : Colors.red, fontSize: 9),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: _exportPDF,
                  constraints: const BoxConstraints(maxHeight: 24, maxWidth: 24),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.picture_as_pdf_outlined, color: primaryOrange, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Compact Summary KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _buildKPI(tr('reports.trial_balance.total_debit'), _totalDebit, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildKPI(tr('reports.trial_balance.total_credit'), _totalCredit, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildKPI(tr('reports.trial_balance.difference'), (_totalDebit - _totalCredit).abs(), isBalanced ? Colors.green : Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        
        // Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryOrange.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(6)
            ),
            child: Row(children: [
              SizedBox(width: 40, child: Text(tr('reports.trial_balance.code_col'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
              Expanded(flex: 3, child: Text(tr('reports.trial_balance.name_col'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
              Expanded(child: Text(tr('reports.trial_balance.debit_col'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.green))),
              Expanded(child: Text(tr('reports.trial_balance.credit_col'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.red))),
            ]),
          ),
        ),
        const SizedBox(height: 2),
        
        // Table Body
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _accounts.isEmpty
              ? Center(child: Text(tr('reports.trial_balance.no_accounts'), style: TextStyle(color: context.mutedText)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _accounts.length + 1, // +1 for totals
                  itemBuilder: (_, i) {
                    if (i == _accounts.length) return _buildTotalRow();
                    return _buildAccountRow(_accounts[i], i);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> acc, int index) {
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0;
    final type = acc['type']?.toString() ?? '';
    final isDebitNature = type == 'asset' || type == 'expense';
    final debit = isDebitNature && balance > 0 ? balance : (balance < 0 ? balance.abs() : 0.0);
    final credit = !isDebitNature && balance > 0 ? balance : (isDebitNature && balance < 0 ? balance.abs() : 0.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), // 📉 Reduced padding
      decoration: BoxDecoration(
        color: index.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(children: [
        SizedBox(width: 40, child: Text(acc['code']?.toString() ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _typeColor(type)))),
        Expanded(flex: 3, child: Text(acc['name']?.toString() ?? '', style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(child: Text(debit > 0 ? debit.toStringAsFixed(2) : "-", style: const TextStyle(fontSize: 10, color: Colors.green))),
        Expanded(child: Text(credit > 0 ? credit.toStringAsFixed(2) : "-", style: const TextStyle(fontSize: 10, color: Colors.red))),
      ]),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryOrange.withValues(alpha: 0.3))),
      child: Row(children: [
        const SizedBox(width: 48),
        Expanded(flex: 2, child: Text(tr('reports.trial_balance.total_label'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
        const Expanded(child: SizedBox()),
        Expanded(child: Text(_totalDebit.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize, color: Colors.green))),
        Expanded(child: Text(_totalCredit.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize, color: Colors.red))),
      ]),
    );
  }

  Widget _buildKPI(String title, double value, Color color) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: TextStyle(color: context.mutedText, fontSize: 9)),
          const SizedBox(height: 2),
          FittedBox(child: Text(value.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
        ],
      ),
    );
  }

  Future<void> _exportPDF() async {
    try {
      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();
      
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4, textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text(tr('reports.trial_balance.title'), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange))),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Text('${DateTime.now().toString().substring(0, 10)}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600))),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              tr('reports.trial_balance.code_col'),
              tr('reports.trial_balance.name_col'),
              tr('reports.trial_balance.type_col'),
              tr('reports.trial_balance.debit_col'),
              tr('reports.trial_balance.credit_col')
            ],
            data: _accounts.map((acc) {
              final balance = (acc['balance'] as num?)?.toDouble() ?? 0;
              final type = acc['type']?.toString() ?? '';
              final isDebitNature = type == 'asset' || type == 'expense';
              final debit = isDebitNature && balance > 0 ? balance : 0.0;
              final credit = !isDebitNature && balance > 0 ? balance : 0.0;
              return [
                acc['code']?.toString() ?? '',
                acc['name']?.toString() ?? '',
                _typeLabel(type),
                debit > 0 ? debit.toStringAsFixed(2) : '-',
                credit > 0 ? credit.toStringAsFixed(2) : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('${tr('reports.trial_balance.total_debit')}: ${_totalDebit.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green, fontSize: 12)),
            pw.Text('${tr('reports.trial_balance.total_credit')}: ${_totalCredit.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red, fontSize: 12)),
          ]),
          pw.SizedBox(height: 20), pw.Divider(),
          pw.Text('حساباتي ERP - ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ]),
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: 'Trial_Balance_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Color _typeColor(String type) {
    switch (type) { case 'asset': return Colors.blue; case 'liability': return Colors.red; case 'revenue': return Colors.green; case 'expense': return Colors.orange; default: return Colors.purple; }
  }
  String _typeLabel(String type) {
    switch (type) {
      case 'asset': return tr('accounts.types.asset');
      case 'liability': return tr('accounts.types.liability');
      case 'revenue': return tr('accounts.types.revenue');
      case 'expense': return tr('accounts.types.expense');
      case 'equity': return tr('accounts.types.equity');
      default: return type;
    }
  }
}
