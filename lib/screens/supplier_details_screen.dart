import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'purchase_invoice_screen.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final String supplierId;
  final String supplierName;

  const SupplierDetailsScreen({
    super.key, 
    required this.supplierId, 
    required this.supplierName,
  });

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<double> _aging = [0, 0, 0];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await _db.getSupplierSummary(widget.supplierId);
    final aging = await _db.getSupplierAging(widget.supplierId);
    final transactions = await _db.getSupplierTransactions(widget.supplierId);
    
    if (mounted) {
      setState(() {
        _summary = summary;
        _aging = aging;
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  void _showPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedAccount = 'ACC_CASH';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
          title: Text(tr('suppliers.details.register_payment'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('suppliers.details.payment_amount'),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAccount,
                decoration: InputDecoration(
                  labelText: tr('suppliers.details.from_account'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: context.bgSurface,
                items: [
                  DropdownMenuItem(value: 'ACC_CASH', child: Text(tr('suppliers.details.cash_account'))),
                  DropdownMenuItem(value: 'ACC_BANK_1', child: Text(tr('suppliers.details.bank_1'))),
                  DropdownMenuItem(value: 'ACC_BANK_2', child: Text(tr('suppliers.details.bank_2'))),
                ],
                onChanged: (val) => setDialogState(() => selectedAccount = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: tr('suppliers.details.notes'),
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                
                try {
                  await _db.registerSupplierPayment(
                    supplierId: widget.supplierId,
                    amount: amount,
                    paymentAccountId: selectedAccount,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('suppliers.details.payment_success')), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${tr('suppliers.details.payment_error')}: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check, color: Colors.black),
              label: Text(tr('suppliers.details.confirm_payment'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.supplierName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(),
                const SizedBox(height: 16),
                _buildAgingAnalysis(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 16),
                Text(tr('suppliers.details.statement'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTransactionList(),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard(tr('suppliers.details.total_debt'), "${_summary['balance']?.toStringAsFixed(2) ?? '0.00'}", Colors.redAccent, Icons.account_balance_wallet),
        const SizedBox(width: 8),
        _buildStatCard(tr('suppliers.details.overdue_invoices'), "${_summary['overdue']?.toStringAsFixed(2) ?? '0.00'}", Colors.orangeAccent, Icons.error_outline),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(context.cardPadding),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(context.cardRadius),
          border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: context.iconSize - 2),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
            const SizedBox(height: 2),
            Text("${value}", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingAnalysis() {
    final maxAging = _aging.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('suppliers.details.aging_analysis'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 16),
          _buildAgingBar(tr('suppliers.details.aging_0_30'), _aging[0], maxAging, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildAgingBar(tr('suppliers.details.aging_31_60'), _aging[1], maxAging, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildAgingBar(tr('suppliers.details.aging_60_plus'), _aging[2], maxAging, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildAgingBar(String label, double amount, double max, Color color) {
    final percent = max > 0 ? amount / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: context.bodySize - 2)),
            Text("${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: context.cardBorder, borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.01, 1.0),
              child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Pay supplier button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showPaymentDialog,
            icon: Icon(Icons.payments_outlined, color: Colors.black, size: context.iconSize),
            label: Text(tr('suppliers.details.pay_action'), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // New purchase invoice button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseInvoiceScreen(
                    preSelectedSupplierId: widget.supplierId,
                  ),
                ),
              );
              if (result == true) _loadData();
            },
            icon: Icon(Icons.receipt_long_outlined, color: primaryOrange, size: context.iconSize),
            label: Text(tr('suppliers.details.new_purchase'), style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.cardSurface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.cardRadius),
                side: BorderSide(color: primaryOrange.withValues(alpha: 0.3)),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Print button
        Container(
          decoration: BoxDecoration(color: context.cardSurface, border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(context.cardRadius)),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('جاري تصدير كشف حساب ${widget.supplierName} إلى PDF...'),
                  backgroundColor: primaryOrange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: Icon(Icons.print_outlined, size: context.iconSize),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(tr('suppliers.details.no_transactions'), style: TextStyle(color: context.mutedText)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isOut = tx['direction'] == 'out';
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(isOut ? Icons.shopping_cart_outlined : Icons.account_balance_wallet_outlined, color: isOut ? Colors.orange : Colors.green, size: context.iconSize - 2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['type'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                    Text(tx['date'] ?? '', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                  ],
                ),
              ),
              Text(
                "${isOut ? '-' : '+'}${tx['amount']}",
                style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.redAccent : Colors.greenAccent, fontSize: context.bodySize),
              ),
            ],
          ),
        );
      },
    );
  }
}
