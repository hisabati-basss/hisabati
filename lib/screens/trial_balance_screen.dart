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
    final isBalanced = (_totalDebit - _totalCredit).abs() < 0.01;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('reports.trial_balance.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text(isBalanced ? tr('reports.trial_balance.balanced') : tr('reports.trial_balance.unbalanced'), style: TextStyle(
                color: isBalanced ? Colors.green : Colors.red, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            ])),
            GestureDetector(
              onTap: _exportPDF,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.picture_as_pdf, size: 14, color: Colors.black87),
                  SizedBox(width: 4),
                  Text("PDF", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        
        // Summary KPIs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            Expanded(child: _buildKPI(tr('reports.trial_balance.total_debit'), _totalDebit, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildKPI(tr('reports.trial_balance.total_credit'), _totalCredit, Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _buildKPI(tr('reports.trial_balance.difference'), (_totalDebit - _totalCredit).abs(), isBalanced ? Colors.green : Colors.red)),
          ]),
        ),
        const SizedBox(height: 8),
        
        // Table Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              SizedBox(width: 48, child: Text(tr('reports.trial_balance.code_col'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))),
              Expanded(flex: 2, child: Text(tr('reports.trial_balance.name_col'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))),
              Expanded(child: Text(tr('reports.trial_balance.type_col'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))),
              Expanded(child: Text(tr('reports.trial_balance.debit_col'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2, color: Colors.green))),
              Expanded(child: Text(tr('reports.trial_balance.credit_col'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2, color: Colors.red))),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        
        // Table Body
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _accounts.isEmpty
              ? Center(child: Text(tr('reports.trial_balance.no_accounts'), style: TextStyle(color: context.mutedText)))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.transparent : context.cardSurface.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.05))),
      ),
      child: Row(children: [
        SizedBox(width: 48, child: Text(acc['code']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold, color: _typeColor(type)))),
        Expanded(flex: 2, child: Text(acc['name']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 2), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: _typeColor(type).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
          child: Text(_typeLabel(type), style: TextStyle(fontSize: 9, color: _typeColor(type), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        )),
        Expanded(child: Text(debit > 0 ? debit.toStringAsFixed(2) : "-", style: TextStyle(fontSize: context.bodySize - 2, color: Colors.green))),
        Expanded(child: Text(credit > 0 ? credit.toStringAsFixed(2) : "-", style: TextStyle(fontSize: context.bodySize - 2, color: Colors.red))),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.mutedText, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        FittedBox(child: Text(value.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color))),
      ]),
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
