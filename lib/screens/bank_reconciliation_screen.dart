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
    bool isDark = context.isDark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.obsidianGlass,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: context.glassBlurLevel, sigmaY: context.glassBlurLevel),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                _buildDragHandle(),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 24),
                              _buildAccountSelector(context),
                              const SizedBox(height: 24),
                              _buildSummaryCards(context),
                              const SizedBox(height: 32),
                              _buildSectionTitle(context),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        sliver: _isLoading
                            ? const SliverFillRemaining(
                                child: Center(child: CircularProgressIndicator(color: primaryOrange)),
                              )
                            : _transactions.isEmpty
                                ? SliverFillRemaining(child: _buildEmptyState())
                                : _buildTransactionsSliverList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('common.details'),
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${_transactions.length} قيود",
            style: TextStyle(color: context.mutedText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: sunsetStart.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('bank_reconciliation.title'),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'تأكيد مطابقة الحسابات البنكية ومزامنة القيود',
                style: TextStyle(
                  color: context.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(BuildContext context) {
    bool isDark = context.isDark;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.sheetGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => context.primaryGradient.createShader(bounds),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccountId,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.mutedText, size: 24),
                items: _bankAccounts.map((a) => DropdownMenuItem(
                  value: a['id'].toString(),
                  child: Text(
                    '${a['name']} (${a['code']})', 
                    style: TextStyle(
                      color: context.textColor, 
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                )).toList(),
                onChanged: (v) {
                  setState(() => _selectedAccountId = v);
                  _loadTransactions();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    double diff = _systemBalance - (double.tryParse(_statementBalanceController.text) ?? 0.0);
    
    return Row(
      children: [
        _buildStatCard(context, 'رصيد النظام', _systemBalance.toStringAsFixed(2), sunsetStart, Icons.account_balance_wallet_outlined),
        const SizedBox(width: 12),
        _buildStatCard(context, 'الرصيد المطابق', _reconciledBalance.toStringAsFixed(2), context.successColor, Icons.verified_user_outlined),
        const SizedBox(width: 12),
        _buildStatCard(context, 'الفرق المتبقي', diff.toStringAsFixed(2), diff == 0 ? Colors.blueAccent : context.errorColor, Icons.balance_outlined),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.sheetGlass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value, 
                style: TextStyle(
                  color: context.textColor, 
                  fontSize: 20, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                )
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: context.mutedText, 
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = _transactions[index];
          bool isReconciled = tx['reconciled'] == 1;
          Color accentColor = isReconciled 
              ? context.successColor 
              : (tx['debit'] > 0 ? Colors.blueAccent : Colors.orangeAccent);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.sheetGlass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isReconciled ? accentColor.withValues(alpha: 0.3) : context.glassBorder,
                width: 1.5,
              ),
              boxShadow: [
                if (!isReconciled)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTransactionIcon(tx, accentColor, isReconciled),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['description'] ?? 'بدون وصف',
                        style: TextStyle(
                          color: context.textColor, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 12, color: context.mutedText),
                          const SizedBox(width: 6),
                          Text(
                            tx['date'],
                            style: TextStyle(color: context.mutedText, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tx['debit'] > 0 ? '+${tx['debit'].toStringAsFixed(2)}' : '-${tx['credit'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: tx['debit'] > 0 ? context.successColor : context.errorColor,
                        fontWeight: FontWeight.w900, fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMatchButton(tx, isReconciled),
                  ],
                ),
              ],
            ),
          );
        },
        childCount: _transactions.length,
      ),
    );
  }

  Widget _buildTransactionIcon(Map tx, Color color, bool isReconciled) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isReconciled ? Icons.verified_rounded : (tx['debit'] > 0 ? Icons.add_rounded : Icons.remove_rounded),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildMatchButton(Map tx, bool isReconciled) {
    return GestureDetector(
      onTap: () => _toggleReconcile(tx['line_id'].toString(), !isReconciled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isReconciled ? context.successColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReconciled ? context.successColor.withValues(alpha: 0.4) : context.mutedText.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          isReconciled ? "تمت المطابقة" : "مطابقة الآن",
          style: TextStyle(
            color: isReconciled ? context.successColor : context.textColor, 
            fontSize: 11, 
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.sheetGlass,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد قيود محاسبية لهذا الحساب', 
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReconcile(String lineId, bool status) async {
    await _db.reconcileTransaction(lineId, status);
    _loadTransactions();
  }
}
