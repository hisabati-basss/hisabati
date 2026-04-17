import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';

class PaymentVoucherScreen extends StatefulWidget {
  const PaymentVoucherScreen({super.key});

  @override
  State<PaymentVoucherScreen> createState() => _PaymentVoucherScreenState();
}

class _PaymentVoucherScreenState extends State<PaymentVoucherScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  bool _isSaving = false;
  String? _selectedSupplierId;
  String _paymentMethod = 'cash';
  String? _selectedBankId;
  String _currency = 'SAR';
  
  List<Map<String, dynamic>> _suppliers = [];
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
      
      // Seed default supplier if empty
      final supCheck = await db.query('suppliers', limit: 1);
      if (supCheck.isEmpty) {
        await db.insert('suppliers', {
          'id': 'SUP_DEFAULT',
          'name': 'مورد عام / مشتريات نقدية',
          'contact_info': '-',
          'balance': 0,
          'sync_status': 0,
          'is_deleted': 0,
        });
      }
      
      final suppliers = await db.query('suppliers', where: 'is_deleted = 0', orderBy: 'name ASC');
      final banks = await db.query('accounts', where: "type = 'asset'");
      final vouchers = await db.query('payment_vouchers', orderBy: 'created_at DESC');
      
      final companyContext = await _db.getCurrentCompanyContext();
      
      debugPrint('📊 Payment Voucher Data: ${suppliers.length} suppliers, ${banks.length} banks');
      
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _banks = banks;
          _vouchers = vouchers;
          _currency = companyContext['currency']?.toString().toUpperCase() ?? 'SAR';
          if (suppliers.isNotEmpty) _selectedSupplierId = suppliers.first['id']?.toString();
          if (banks.isNotEmpty) _selectedBankId = banks.first['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading payment vouchers: $e");
      if (mounted) {
        setState(() {
          _suppliers = [];
          _banks = [];
          _vouchers = [];
        });
      }
    }
  }

  Future<void> _saveVoucher() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_amount'))));
      return;
    }
    
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_client'))));
      return;
    }

    if (_paymentMethod == 'bank' && _selectedBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.error_bank'))));
      return;
    }

    setState(() => _isSaving = true);
    
    final supplierName = _suppliers.firstWhere((s) => s['id'] == _selectedSupplierId)['name'];

    final res = await _engine.processPaymentVoucher(
      supplierId: _selectedSupplierId!,
      supplierName: supplierName,
      amount: amount,
      paymentMethod: _paymentMethod,
      bankAccountId: _selectedBankId,
      notes: _notesCtrl.text,
    );

    setState(() => _isSaving = false);

    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.payment.save_success')), backgroundColor: Colors.green));
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
    
    // Using a reddish shade to differentiate Payment from Receipt
    Color primaryVoucherColor = Colors.redAccent;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Scaffold(
          backgroundColor: context.obsidianGlass,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(100 + context.headerSize),
            child: Container(
              padding: EdgeInsets.fromLTRB(context.cardPadding, 8, context.cardPadding, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('accounting_module.tabs.financial_position'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                          Text(tr('vouchers.payment.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: primaryVoucherColor)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: context.mutedText),
                      ),
                    ],
                  ),
              TabBar(
                controller: _tabController,
                indicatorColor: primaryVoucherColor,
                labelColor: primaryVoucherColor,
                unselectedLabelColor: context.mutedText,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: tr('vouchers.payment.new_tab'), height: 28),
                  Tab(text: tr('vouchers.payment.history_tab'), height: 28),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewVoucherTab(isDark, primaryVoucherColor),
          _buildHistoryTab(isDark, primaryVoucherColor),
        ],
      ),
    )));
  }

  Widget _buildNewVoucherTab(bool isDark, Color primaryColor) {
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
                  Text(tr('vouchers.payment.details_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                  const SizedBox(height: 16),
                  
                  // Supplier
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSupplierId,
                          decoration: InputDecoration(
                            labelText: tr('vouchers.payment.payee_label'),
                            labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.business_center_outlined),
                          ),
                          dropdownColor: context.bgSurface,
                          items: _suppliers.map((s) => DropdownMenuItem<String>(
                            value: s['id']?.toString(),
                            child: Text(s['name']?.toString() ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedSupplierId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Navigate to Supplier Management
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يمكنك إضافة موردين جدد من قسم المشتريات > الموردين")));
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                    decoration: InputDecoration(
                      labelText: tr('vouchers.payment.amount_label'),
                      labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.payments_outlined, color: primaryColor),
                      suffixText: _currency,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(tr('vouchers.payment.payment_cash')),
                          value: 'cash',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          activeColor: primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(tr('vouchers.payment.payment_bank')),
                          value: 'bank',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          activeColor: primaryColor,
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
                        labelText: tr('vouchers.payment.bank_account'),
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
                      labelText: tr('vouchers.payment.notes_label'),
                      labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomSummary(isDark, primaryColor),
      ],
    );
  }

  Widget _buildBottomSummary(bool isDark, Color primaryColor) {
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
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(tr('vouchers.payment.issue_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark, Color primaryColor) {
    if (_vouchers.isEmpty) {
      return Center(child: Text(tr('vouchers.payment.no_vouchers'), style: TextStyle(color: context.mutedText)));
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
              Text("${tr('vouchers.payment.to')}: ${v['supplier_name']}", style: TextStyle(color: context.mutedText, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${tr('vouchers.receipt.method')}: ${v['payment_method'] == 'cash' ? tr('vouchers.payment.payment_cash') : tr('vouchers.payment.payment_bank')} \n${tr('vouchers.receipt.entry')}: ${v['journal_entry_id']}", style: TextStyle(color: context.mutedText, fontSize: 10)),
                  Text("${v['amount']} $_currency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
