import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import '../services/unified_pdf_export_service.dart';
import 'purchase_invoice_screen.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final String supplierId;
  final String supplierName;

  const SupplierDetailsScreen({
    super.key, 
    required this.supplierId, 
    required this.supplierName,
  });

  static void show(BuildContext context, String id, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SupplierDetailsScreen(supplierId: id, supplierName: name),
    );
  }

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

  Future<void> _printStatement() async {
    setState(() => _isLoading = true);
    try {
      final company = await _db.getCompanyInfo();
      final headers = [
        tr('suppliers.details.pdf.date'),
        tr('suppliers.details.pdf.description'),
        tr('suppliers.details.pdf.financial_item'),
        tr('suppliers.details.pdf.total_value'),
      ];

      final data = _transactions.map((tx) {
        final isOut = tx['direction'] == 'out';
        return [
          tx['date'] ?? '',
          tx['type'] ?? '',
          isOut ? tr('suppliers.details.new_purchase') : tr('suppliers.details.pay_action'),
          "${isOut ? '-' : '+'}${tx['amount']}",
        ];
      }).toList();

      final summaryItems = [
        {'label': tr('suppliers.details.total_debt'), 'value': _summary['balance']?.toStringAsFixed(2) ?? '0.00'},
        {'label': tr('suppliers.details.overdue_invoices'), 'value': _summary['overdue']?.toStringAsFixed(2) ?? '0.00'},
      ];

      await UnifiedPdfExportService.generateModuleReport(
        title: "${tr('suppliers.details.statement')}: ${widget.supplierName}",
        headers: headers,
        data: data,
        company: company,
        summaryItems: summaryItems,
        isArabic: context.locale.languageCode == 'ar',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${tr('common.error')}: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedAccount = 'ACC_CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(context.cardPadding * 2),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF1A1A1F) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.mutedText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(tr('suppliers.details.register_payment'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize + 2, color: context.textColor)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.textColor),
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
                      labelText: tr('suppliers.details.payment_account'),
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor: context.bgSurface,
                    style: TextStyle(color: context.textColor),
                    items: [
                      DropdownMenuItem(value: 'ACC_CASH', child: Text(tr('accounts.cash'))),
                      DropdownMenuItem(value: 'ACC_BANK', child: Text(tr('accounts.bank'))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedAccount = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    style: TextStyle(color: context.textColor),
                    decoration: InputDecoration(
                      labelText: tr('suppliers.details.notes'),
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr('common.cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0) return;
                          
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          
                          try {
                            await _db.registerSupplierPayment(
                              widget.supplierId,
                              amount,
                              DateTime.now().toIso8601String(),
                              selectedAccount,
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
                        style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: 800,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF0F0F12) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: context.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.mutedText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.supplierName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textColor)),
                    IconButton(icon: Icon(Icons.close, color: context.mutedText), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(context.sectionPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverdueAlert(),
                        _buildSummaryCards(),
                        const SizedBox(height: 16),
                        _buildSupplierInfo(),
                        _buildAgingAnalysis(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        Text(tr('suppliers.details.statement'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)),
                        const SizedBox(height: 12),
                        _buildTransactionList(),
                      ],
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(tr('suppliers.details.total_debt'), "${_summary['balance']?.toStringAsFixed(2) ?? '0.00'}", Colors.redAccent, Icons.account_balance_wallet),
            const SizedBox(width: 8),
            _buildStatCard(tr('suppliers.details.overdue_invoices'), "${_summary['overdue']?.toStringAsFixed(2) ?? '0.00'}", Colors.orangeAccent, Icons.error_outline),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatCard(tr('suppliers.details.total_paid_title'), "${_summary['total_paid']?.toStringAsFixed(2) ?? '0.00'}", Colors.greenAccent, Icons.check_circle_outline),
          ],
        ),
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
            onPressed: _printStatement,
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
                    Row(
                      children: [
                        Text("${tr('suppliers.details.id')}: ${tx['id']}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
                        const SizedBox(width: 8),
                        Text(tx['date']?.toString().split('T')[0] ?? '', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
                      ],
                    ),
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
  Widget _buildOverdueAlert() {
    final double overdue = _summary['overdue'] ?? 0;
    if (overdue <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('suppliers.details.overdue_alert'),
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Text(
            "${overdue.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_outlined, tr('suppliers.contact_label'), _summary['contact_info'] ?? '-'),
          const Divider(height: 16),
          _buildInfoRow(Icons.receipt_outlined, tr('suppliers.details.tax_id'), _summary['tax_id'] ?? '-'),
          const Divider(height: 16),
          _buildInfoRow(Icons.history_outlined, tr('suppliers.details.last_payment'), _summary['last_payment_date']?.toString().split('T')[0] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.mutedText),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.bodySize - 2)),
      ],
    );
  }
}
