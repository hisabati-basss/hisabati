import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart' as intl;
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart'; // 📉 Added missing import
import '../widgets/glass_container.dart';
import '../widgets/attachment_viewer.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final accs = await _dbHelper.getWalletAccounts();
    final hist = await _dbHelper.getTransferHistory();
    setState(() {
      _accounts = accs;
      _history = hist;
      _isLoading = false;
    });
  }

  Future<void> _toggleReconciliation(String id, bool currentStatus) async {
    await _dbHelper.setReconciliationStatus(id, !currentStatus);
    _refreshData();
  }

  void _showTransferDialog() {
    String? fromAccount;
    String? toAccount;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController feeController = TextEditingController(text: '0');
    final TextEditingController notesController = TextEditingController();
    String? attachmentPath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 28,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('wallet.transfer_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  // From Account
                  _buildDropdown(
                    label: tr('wallet.from_account'),
                    value: fromAccount,
                    items: _accounts,
                    onChanged: (val) => setDialogState(() => fromAccount = val),
                  ),
                  const SizedBox(height: 12),
                  
                  // To Account
                  _buildDropdown(
                    label: tr('wallet.to_account'),
                    value: toAccount,
                    items: _accounts.where((a) => a['id'] != fromAccount).toList(),
                    onChanged: (val) => setDialogState(() => toAccount = val),
                  ),
                  const SizedBox(height: 12),

                  // Amount and Fee
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: tr('wallet.amount'),
                          controller: amountController,
                          icon: Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: tr('wallet.bank_fee'),
                          controller: feeController,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    label: tr('wallet.notes'),
                    controller: notesController,
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 20),

                  // Image Attachment (v13 feature)
                  AttachmentViewer(
                    onAttachmentSelected: (path) => attachmentPath = path,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(tr('common.cancel'), style: const TextStyle(color: Colors.white60)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (fromAccount != null && toAccount != null && amountController.text.isNotEmpty) {
                              await _dbHelper.transferFunds(
                                fromAccountId: fromAccount!,
                                toAccountId: toAccount!,
                                amount: double.parse(amountController.text),
                                fee: double.parse(feeController.text),
                                attachmentPath: attachmentPath,
                                notes: notesController.text,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr('wallet.transfer_success'))),
                                );
                              }
                            }
                          },
                          child: Text(tr('wallet.confirm_transfer_btn')),
                        ),
                      ),
                    ],
                  )
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTransferDialog,
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.compare_arrows),
        label: Text(tr('wallet.transfer_between_btn')),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24.0
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('wallet.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: Colors.white)), // 📉 Reduced from 28
                Text(tr('wallet.subtitle'), style: TextStyle(color: Colors.white60, fontSize: context.bodySize - 1)), // 📉 Shortened
                const SizedBox(height: 12), // 📉 Reduced from 16/32
                
                // Account Cards Grid
                SizedBox(
                  height: 150, // 📉 Reduced from 200
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      return _buildWalletCard(acc, index);
                    },
                  ),
                ),
                
                const SizedBox(height: 16), // 📉 Reduced from 20/40
                Text(tr('wallet.recent_transfers'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: Colors.white)), // 📉 Reduced from 18
                const SizedBox(height: 12), // 📉 Reduced from 16
                
                // Transfer History
                Expanded(
                  child: _history.isEmpty 
                    ? Center(child: Text(tr('wallet.no_history'), style: const TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final h = _history[index];
                          return _buildHistoryItem(h);
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> acc, int index) {
    final List<Color> colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.orangeAccent,
    ];
    final color = colors[index % colors.length];

    return Container(
      width: 250, // 📉 Slightly reduced from 280 (but keeping readable for numbers)
      margin: const EdgeInsets.only(left: 8), // 📉 Reduced from 12/16
      child: GlassContainer(
        borderRadius: context.cardRadius, // 📉 Reduced from 24
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: color.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        acc['id'].toString().contains('BANK') ? Icons.account_balance : Icons.account_balance_wallet,
                        color: color,
                        size: context.iconSize, // 📉 Added
                      ),
                      Text(acc['code'] ?? "", style: TextStyle(color: Colors.white38, fontSize: context.bodySize - 2)), // 📉 Reduced from 12
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc['name'], style: TextStyle(fontSize: context.bodySize + 1, color: Colors.white70)), // 📉 Reduced from 16
                      const SizedBox(height: 2), // 📉 Reduced from 4
                      Text(
                        "${intl.NumberFormat("#,###.##").format(acc['balance'])} ${tr('common.currency_symbol')}",
                        style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: Colors.white), // 📉 Reduced from 24
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // 📉 Reduced from 12
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 14, // 📉 Reduced
            child: Icon(Icons.sync_alt, color: Colors.white70, size: context.iconSize - 4), // 📉 Reduced from 18
          ),
          const SizedBox(width: 12), // 📉 Reduced from 16
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("من ${h['from_name']} إلى ${h['to_name']}", style: TextStyle(color: Colors.white, fontSize: context.bodySize)), // 📉 Reduced from 14
                  Text(h['date'], style: TextStyle(color: Colors.white38, fontSize: context.bodySize - 2)), // 📉 Reduced from 12
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${h['amount']} ${tr('common.currency_symbol')}", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: context.bodySize)),
              if ((h['fee'] as num) > 0)
                Text("${tr('wallet.fee_label')}: ${h['fee']}", style: TextStyle(color: Colors.redAccent, fontSize: context.bodySize - 2)), // 📉 Reduced from -3
            ],
          ),
          IconButton(
            icon: Icon(
              (h['reconciled'] == 1) ? Icons.verified_user_rounded : Icons.radio_button_unchecked_rounded,
              color: (h['reconciled'] == 1) ? Colors.greenAccent : Colors.white24,
              size: context.iconSize,
            ),
            tooltip: (h['reconciled'] == 1) ? tr('wallet.matched') : tr('wallet.pending_match'),
            onPressed: () => _toggleReconciliation(h['id'].toString(), h['reconciled'] == 1),
          ),
          if (h['attachment_path'] != null)
             IconButton(
               icon: Icon(Icons.image, color: Colors.blueAccent, size: context.iconSize - 2), // 📉 Reduced
               onPressed: () {

                 showDialog(
                   context: context,
                   builder: (c) => Dialog(
                     child: Image.file(File(h['attachment_path'])),
                   ),
                 );
               },
             )
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<Map<String, dynamic>> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.black.withValues(alpha: 0.9),
              items: items.map((a) => DropdownMenuItem(
                value: a['id'].toString(),
                child: Text(a['name'], style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
