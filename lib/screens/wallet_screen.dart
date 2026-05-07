import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart' as intl;
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
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
  Map<String, dynamic>? _company;
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
    final company = await _dbHelper.getCompanyInfo();
    double total = 0;
    for (var a in accs) {
      total += (a['balance'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      _accounts = accs;
      _history = hist;
      _company = company;
      _totalBalance = total;
      _isLoading = false;
    });
  }
  double _totalBalance = 0;

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Container(
            width: 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: context.mutedText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text(tr('wallet.transfer_title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                    const SizedBox(height: 24),
                    
                    // From Account
                    _buildDropdown(
                      label: tr('wallet.from_account'),
                      value: fromAccount,
                      items: _accounts,
                      onChanged: (val) => setDialogState(() => fromAccount = val),
                    ),
                    const SizedBox(height: 16),
                    
                    // To Account
                    _buildDropdown(
                      label: tr('wallet.to_account'),
                      value: toAccount,
                      items: _accounts.where((a) => a['id'] != fromAccount).toList(),
                      onChanged: (val) => setDialogState(() => toAccount = val),
                    ),
                    const SizedBox(height: 16),

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
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: tr('wallet.bank_fee'),
                            controller: feeController,
                            icon: Icons.account_balance_wallet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: tr('wallet.notes'),
                      controller: notesController,
                      icon: Icons.notes,
                    ),
                    const SizedBox(height: 20),

                    // Image Attachment
                    AttachmentViewer(
                      onAttachmentSelected: (path) => attachmentPath = path,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: Text(tr('common.cancel'), style: TextStyle(color: context.mutedText)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    SnackBar(content: Text(tr('wallet.transfer_success')), backgroundColor: Colors.green),
                                  );
                                }
                              }
                            },
                            child: Text(tr('wallet.confirm_transfer_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('wallet.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(tr('wallet.subtitle'), style: TextStyle(color: Colors.white60, fontSize: context.bodySize - 1)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${_totalBalance.toStringAsFixed(2)} ${_company?['currency'] ?? ''}", 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                        Text(tr('accounting.total_balance'), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined, color: Colors.white60),
                      onPressed: () {
                         if (_company != null) {
                           PdfService.generateWalletReportPdf(accounts: _accounts, company: _company!);
                         }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12), // 📉 Reduced from 16/32
                
                // Account Cards Grid
                SizedBox(
                  height: 150, // 📉 Reduced from 200
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _accounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _accounts.length) {
                        return _buildAddBankButton();
                      }
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

    return GestureDetector(
      onTap: () => _showBankLinkDialog(acc),
      child: Container(
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
                          acc['id'].toString().contains('BANK') || acc['bank_name'] != null ? Icons.account_balance : Icons.account_balance_wallet,
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
                        if (acc['bank_name'] != null)
                          Text(acc['bank_name'], style: const TextStyle(fontSize: 10, color: Colors.white24)),
                        if (acc['iban'] != null && acc['iban'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(acc['iban'], style: const TextStyle(fontSize: 8, color: Colors.white24, letterSpacing: 0.5)),
                          ),
                        const SizedBox(height: 2),
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
      ),
    );
  }

  void _showBankLinkDialog(Map<String, dynamic> acc) {
    final TextEditingController bankNameCtrl = TextEditingController(text: acc['bank_name']);
    final TextEditingController accNumCtrl = TextEditingController(text: acc['bank_account_number']);
    final TextEditingController ibanCtrl = TextEditingController(text: acc['iban']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(child: Text(tr('wallet.link_bank_title'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(label: tr('wallet.bank_name'), controller: bankNameCtrl, icon: Icons.business),
            const SizedBox(height: 12),
            _buildTextField(label: tr('wallet.acc_number'), controller: accNumCtrl, icon: Icons.numbers),
            const SizedBox(height: 12),
            _buildTextField(label: tr('wallet.iban'), controller: ibanCtrl, icon: Icons.account_balance),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final db = await _dbHelper.database;
              await db.update('accounts', {
                'bank_name': bankNameCtrl.text,
                'bank_account_number': accNumCtrl.text,
                'iban': ibanCtrl.text,
              }, where: 'id = ?', whereArgs: [acc['id']]);
              if (mounted) {
                Navigator.pop(ctx);
                _refreshData();
              }
            },
            child: Text(tr('common.save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankButton() {
    return GestureDetector(
      onTap: _showAddNewBankDialog,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(left: 8),
        child: GlassContainer(
          borderRadius: context.cardRadius,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white60, size: 40),
              const SizedBox(height: 12),
              Text(tr('wallet.link_bank_title'), style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNewBankDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController codeCtrl = TextEditingController();
    final TextEditingController bankNameCtrl = TextEditingController();
    final TextEditingController accNumCtrl = TextEditingController();
    final TextEditingController ibanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('wallet.link_bank_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(label: tr('common.name'), controller: nameCtrl, icon: Icons.label),
              const SizedBox(height: 12),
              _buildTextField(label: tr('accounting.code'), controller: codeCtrl, icon: Icons.code),
              const SizedBox(height: 12),
              _buildTextField(label: tr('wallet.bank_name'), controller: bankNameCtrl, icon: Icons.business),
              const SizedBox(height: 12),
              _buildTextField(label: tr('wallet.acc_number'), controller: accNumCtrl, icon: Icons.numbers),
              const SizedBox(height: 12),
              _buildTextField(label: tr('wallet.iban'), controller: ibanCtrl, icon: Icons.account_balance),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
              await _dbHelper.addAccount({
                'name': nameCtrl.text,
                'code': codeCtrl.text,
                'type': 'asset',
                'bank_name': bankNameCtrl.text,
                'bank_account_number': accNumCtrl.text,
                'iban': ibanCtrl.text,
                'id': 'ACC_BANK_${codeCtrl.text}',
              });
              if (mounted) {
                Navigator.pop(ctx);
                _refreshData();
              }
            },
            child: Text(tr('common.save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
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
              dropdownColor: context.bgSurface,
              icon: Icon(Icons.arrow_drop_down, color: context.mutedText),
              items: items.map((a) => DropdownMenuItem(
                value: a['id'].toString(),
                child: Text(a['name'], style: TextStyle(color: context.textColor)),
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
          style: TextStyle(color: context.textColor),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: context.mutedText),
            filled: true,
            fillColor: context.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryOrange, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
