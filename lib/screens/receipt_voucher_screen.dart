import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';

class ReceiptVoucherScreen extends StatefulWidget {
  const ReceiptVoucherScreen({super.key});

  @override
  State<ReceiptVoucherScreen> createState() => _ReceiptVoucherScreenState();
}

class _ReceiptVoucherScreenState extends State<ReceiptVoucherScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  bool _isSaving = false;
  String? _selectedClientId;
  String _paymentMethod = 'cash';
  String? _selectedBankId;
  String _currency = 'SAR';
  
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _vouchers = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final db = await _db.database;
      
      // Self-healing: ensure clients table has all needed columns
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients (
          id TEXT PRIMARY KEY, name TEXT, phone TEXT, email TEXT,
          tax_id TEXT, address TEXT, balance REAL DEFAULT 0,
          sync_status INTEGER DEFAULT 0, updated_at TEXT,
          device_id TEXT, is_deleted INTEGER DEFAULT 0
        )
      ''');
      // Add missing columns to existing table
      try { await db.execute('ALTER TABLE clients ADD COLUMN phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN email TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}
      
      // Seed default client if empty
      final clientCheck = await db.query('clients', limit: 1);
      if (clientCheck.isEmpty) {
        await db.insert('clients', {
          'id': 'CL_DEFAULT',
          'name': 'عميل عام / مشتري نقدي',
          'sync_status': 0,
          'is_deleted': 0,
        });
      }
      
      final clients = await db.query('clients', where: 'is_deleted = 0', orderBy: 'name ASC');
      final banks = await db.query('accounts', where: "type = 'asset'");
      final vouchers = await db.query('receipt_vouchers', orderBy: 'created_at DESC');
      
      final companyContext = await _db.getCurrentCompanyContext();
      
      if (mounted) {
        setState(() {
          _clients = clients;
          _banks = banks;
          _vouchers = vouchers;
          _currency = companyContext['currency']?.toString().toUpperCase() ?? 'SAR';
          if (clients.isNotEmpty) _selectedClientId = clients.first['id']?.toString();
          if (banks.isNotEmpty) _selectedBankId = banks.first['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading receipt vouchers: $e");
      if (mounted) {
        setState(() { _clients = []; _banks = []; _vouchers = []; });
      }
    }
  }



  Future<void> _saveVoucher() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_amount'))));
      return;
    }
    
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_client'))));
      return;
    }

    if (_paymentMethod == 'bank' && _selectedBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_bank'))));
      return;
    }

    setState(() => _isSaving = true);
    
    final clientName = _clients.firstWhere((c) => c['id'] == _selectedClientId)['name'];

    final res = await _engine.processReceiptVoucher(
      clientId: _selectedClientId!,
      clientName: clientName,
      amount: amount,
      paymentMethod: _paymentMethod,
      bankAccountId: _selectedBankId,
      notes: _notesCtrl.text,
    );

    setState(() => _isSaving = false);

    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.save_success')), backgroundColor: Colors.green));
      _amountCtrl.clear();
      _notesCtrl.clear();
      _loadInitialData();
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.save_error')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(110 + context.headerSize),
                child: Container(
                  padding: EdgeInsets.fromLTRB(context.cardPadding, 8, context.cardPadding, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('accounting_module.tabs.financial_position'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                              Text(tr('vouchers.receipt.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                            ],
                          ),
                          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: context.mutedText)),
                        ],
                      ),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.greenAccent, labelColor: Colors.greenAccent, unselectedLabelColor: context.mutedText,
                        indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
                        labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: tr('vouchers.receipt.new_tab'), height: 28),
                          Tab(text: tr('vouchers.receipt.history_tab'), height: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewVoucherTab(isDark),
                  _buildHistoryTab(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewVoucherTab(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.cardPadding),
            child: Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: context.cardSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(context.cardRadius),
                border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('vouchers.receipt.details_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                  const SizedBox(height: 16),
                  
                  // Client
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClientId,
                          decoration: InputDecoration(
                            labelText: tr('vouchers.receipt.client_label'),
                            labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          dropdownColor: context.bgSurface,
                          items: _clients.map((c) => DropdownMenuItem<String>(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedClientId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Navigate to Client Management
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.add_client_hint'))));
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    decoration: InputDecoration(
                      labelText: tr('vouchers.receipt.amount_label'),
                      labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      prefixIcon: const Icon(Icons.payments_outlined, color: Colors.greenAccent),
                      suffixText: _currency,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(tr('vouchers.receipt.payment_cash')),
                          value: 'cash',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(tr('vouchers.receipt.payment_bank')),
                          value: 'bank',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_paymentMethod == 'bank') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBankId,
                      decoration: InputDecoration(
                        labelText: tr('vouchers.receipt.bank_account'),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: context.bgSurface,
                      items: _banks.map((b) => DropdownMenuItem<String>(
                        value: b['id']?.toString(),
                        child: Text(b['name']?.toString() ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedBankId = v),
                    ),
                  ],

                  const SizedBox(height: 16),
                  
                  // Notes
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: tr('vouchers.receipt.notes_label'),
                      labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                      prefixIcon: const Icon(Icons.notes, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomSummary(isDark),
      ],
    );
  }

  Widget _buildBottomSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border(top: BorderSide(color: context.cardBorder.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveVoucher,
            icon: _isSaving ? const SizedBox() : const Icon(Icons.save_alt),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(tr('vouchers.receipt.issue_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    if (_vouchers.isEmpty) {
      return Center(child: Text(tr('vouchers.receipt.no_vouchers'), style: TextStyle(color: context.mutedText)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(context.cardPadding),
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final v = _vouchers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${tr('vouchers.receipt.voucher_prefix')} ${v['id'].toString().split('_').last}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(v['date'])), style: TextStyle(color: context.mutedText, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text("${tr('vouchers.receipt.from')}: ${v['client_name']}", style: TextStyle(color: context.mutedText, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${tr('vouchers.receipt.method')}: ${v['payment_method'] == 'cash' ? tr('vouchers.receipt.payment_cash') : tr('vouchers.receipt.payment_bank')} \n${tr('vouchers.receipt.entry')}: ${v['journal_entry_id']}", style: TextStyle(color: context.mutedText, fontSize: 10)),
                  Text("${v['amount']} $_currency", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
