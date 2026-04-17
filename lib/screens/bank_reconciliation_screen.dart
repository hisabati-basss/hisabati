import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class BankReconciliationScreen extends StatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _transactions = [];
  String? _selectedAccountId;
  bool _isLoading = true;
  
  double _systemBalance = 0.0;
  double _reconciledBalance = 0.0;
  final _statementBalanceController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await _db.getBankAccounts();
    setState(() {
      _bankAccounts = accounts;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first['id'];
      }
      _isLoading = false;
    });
    if (_selectedAccountId != null) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    if (_selectedAccountId == null) return;
    setState(() => _isLoading = true);
    
    final txs = await _db.getAccountTransactions(_selectedAccountId!);
    final sysBal = await _db.getAccountBalance(_selectedAccountId!);
    final recBal = await _db.getReconciledBalance(_selectedAccountId!);
    
    setState(() {
      _transactions = txs;
      _systemBalance = sysBal;
      _reconciledBalance = recBal;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium Glow
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildAccountSelector(context),
                const SizedBox(height: 24),
                _buildSummaryCards(context),
                const SizedBox(height: 24),
                Text(
                  tr('common.details'),
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _transactions.isEmpty
                          ? _buildEmptyState()
                          : _buildTransactionsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('bank_reconciliation.title'),
              style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'تأكيد مطابقة الحسابات البنكية',
              style: TextStyle(color: context.mutedText, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAccountId,
          isExpanded: true,
          dropdownColor: Colors.black87,
          items: _bankAccounts.map((a) => DropdownMenuItem(
            value: a['id'].toString(),
            child: Text('${a['name']} (${a['code']})', style: TextStyle(color: context.textColor)),
          )).toList(),
          onChanged: (v) {
            setState(() => _selectedAccountId = v);
            _loadTransactions();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    double diff = _systemBalance - (double.tryParse(_statementBalanceController.text) ?? 0.0);
    
    return Row(
      children: [
        _buildStatCard(context, 'رصيد النظام', _systemBalance.toStringAsFixed(2), sunsetStart),
        const SizedBox(width: 12),
        _buildStatCard(context, 'الرصيد المطابق', _reconciledBalance.toStringAsFixed(2), Colors.greenAccent),
        const SizedBox(width: 12),
        _buildStatCard(context, 'الفرق المتبقي', diff.toStringAsFixed(2), diff == 0 ? Colors.blueAccent : Colors.redAccent),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: context.mutedText, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.separated(
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        bool isReconciled = tx['reconciled'] == 1;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isReconciled ? Colors.greenAccent.withValues(alpha: 0.1) : context.cardBorder.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isReconciled ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReconciled ? Icons.check_circle_outline : Icons.help_outline,
                  color: isReconciled ? Colors.greenAccent : Colors.orangeAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['description'] ?? 'بدون وصف',
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tx['date'],
                      style: TextStyle(color: context.mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx['debit'] > 0 ? '+${tx['debit']}' : '-${tx['credit']}',
                    style: TextStyle(
                      color: tx['debit'] > 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleReconcile(tx['line_id'], !isReconciled),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReconciled ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isReconciled ? tr('bank_reconciliation.status_reconciled') : tr('bank_reconciliation.match_btn'),
                        style: TextStyle(
                          color: isReconciled ? Colors.greenAccent : Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: context.mutedText.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('لا يوجد قيود محاسبية لهذا الحساب', style: TextStyle(color: context.mutedText)),
        ],
      ),
    );
  }

  Future<void> _toggleReconcile(String lineId, bool status) async {
    await _db.reconcileTransaction(lineId, status);
    _loadTransactions();
  }
}
