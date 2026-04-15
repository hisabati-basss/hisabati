import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class BankReconciliationScreen extends StatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class BankStatementItem {
  final DateTime date;
  final String description;
  final double amount;
  String? matchedLineId;
  bool isReconciled;

  BankStatementItem({
    required this.date,
    required this.description,
    required this.amount,
    this.matchedLineId,
    this.isReconciled = false,
  });
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  String? _selectedAccountId;
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _systemTransactions = [];
  List<BankStatementItem> _importedTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    final db = await _db.database;
    final accs = await db.query('accounts', where: "type = 'asset' AND (name LIKE '%بنك%' OR name LIKE '%Bank%' OR name LIKE '%bank%')");
    setState(() {
      _bankAccounts = accs;
      if (accs.isNotEmpty) _selectedAccountId = accs.first['id'] as String?;
    });
    if (_selectedAccountId != null) _loadSystemTransactions();
  }

  Future<void> _loadSystemTransactions() async {
    if (_selectedAccountId == null) return;
    setState(() => _isLoading = true);
    final txs = await _db.getAccountTransactions(_selectedAccountId!);
    setState(() {
      _systemTransactions = txs;
      _isLoading = false;
    });
    _autoMatch();
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      
      List<BankStatementItem> items = [];
      
      // Basic assumption: Sheet 1, Col 0: Date, Col 1: Desc, Col 2: Amount
      for (var table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        for (int i = 1; i < rows.length; i++) { // Skip header
          final row = rows[i];
          if (row.length < 3) continue;
          
          try {
            final dateStr = row[0]?.value?.toString() ?? '';
            final desc = row[1]?.value?.toString() ?? '';
            final amount = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0;
            
            if (dateStr.isNotEmpty) {
              items.add(BankStatementItem(
                date: DateTime.tryParse(dateStr) ?? DateTime.now(),
                description: desc,
                amount: amount,
              ));
            }
          } catch (_) {}
        }
        break; // Process first sheet only
      }

      setState(() {
        _importedTransactions = items;
      });
      _autoMatch();
    }
  }

  void _autoMatch() {
    if (_importedTransactions.isEmpty || _systemTransactions.isEmpty) return;

    for (var imported in _importedTransactions) {
      if (imported.matchedLineId != null) continue;

      // Match by amount + date (exact)
      final match = _systemTransactions.firstWhere(
        (sys) {
          final sysAmount = (sys['debit'] as num).toDouble() - (sys['credit'] as num).toDouble();
          final sysDate = DateTime.parse(sys['date']);
          return sysAmount == imported.amount && 
                 sysDate.year == imported.date.year &&
                 sysDate.month == imported.date.month &&
                 sysDate.day == imported.date.day &&
                 sys['reconciled'] == 0;
        },
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        setState(() {
          imported.matchedLineId = match['line_id'];
        });
      }
    }
  }

  Future<void> _reconcile(BankStatementItem item) async {
    if (item.matchedLineId == null) return;
    
    await _db.markAsReconciled(item.matchedLineId!, 1);
    setState(() {
      item.isReconciled = true;
    });
    _loadSystemTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Scaffold(
          backgroundColor: context.obsidianGlass,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80 + context.headerSize),
            child: Container(
              padding: EdgeInsets.fromLTRB(context.cardPadding, 8, context.cardPadding, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('bank_reconciliation.tools_label'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                      Text(tr('bank_reconciliation.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                    ],
                  ),
                  Row(
                    children: [
                       IconButton(
                        onPressed: _importFile,
                        icon: const Icon(Icons.file_upload_outlined, color: primaryOrange),
                        tooltip: tr('bank_reconciliation.import_tooltip'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: context.mutedText),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
      body: Column(
        children: [
          _buildAccountHeader(),
          Expanded(
            child: _importedTransactions.isEmpty 
              ? _buildEmptyState()
              : _buildReconList(),
          ),
        ],
      ),
    )));
  }

  Widget _buildAccountHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: primaryOrange, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedAccountId,
              isExpanded: true,
              underline: const SizedBox(),
              style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
              dropdownColor: context.cardSurface,
              items: _bankAccounts.map((acc) => DropdownMenuItem(
                value: acc['id'] as String?,
                child: Text("${acc['name']} (${acc['balance']})"),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedAccountId = val);
                _loadSystemTransactions();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 60, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(tr('bank_reconciliation.empty_state'), style: TextStyle(color: context.mutedText)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _importFile,
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black),
            child: Text(tr('bank_reconciliation.pick_file_btn')),
          ),
        ],
      ),
    );
  }

  Widget _buildReconList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _importedTransactions.length,
      itemBuilder: (context, index) {
        final item = _importedTransactions[index];
        bool isMatched = item.matchedLineId != null;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMatched ? Colors.green.withValues(alpha: 0.3) : context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(DateFormat('yyyy-MM-dd').format(item.date), style: TextStyle(color: context.mutedText, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item.amount}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: item.amount > 0 ? Colors.green : Colors.redAccent)),
                  if (item.isReconciled)
                    Text(tr('bank_reconciliation.status_reconciled'), style: const TextStyle(fontSize: 10, color: Colors.green))
                  else if (isMatched)
                    TextButton(
                      onPressed: () => _reconcile(item),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                      child: Text(tr('bank_reconciliation.match_btn'), style: const TextStyle(fontSize: 10, color: Colors.green)),
                    )
                  else
                    Text(tr('bank_reconciliation.need_match'), style: const TextStyle(fontSize: 10, color: Colors.orange)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
