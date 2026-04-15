import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import '../services/pdf_service.dart';
import 'invoice_entry_screen.dart';
import 'purchase_invoice_screen.dart';
import 'manual_journal_screen.dart';
import 'quotation_screen.dart';
import 'receipt_voucher_screen.dart';
import 'payment_voucher_screen.dart';
import 'bank_reconciliation_screen.dart';
import '../core/accounting/accounting_engine.dart';

class AccountingOperationsScreen extends StatefulWidget {
  const AccountingOperationsScreen({super.key});

  @override
  State<AccountingOperationsScreen> createState() =>
      _AccountingOperationsScreenState();
}

class _AccountingOperationsScreenState
    extends State<AccountingOperationsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  late TabController _tabController;
  
  // Tab 0: Journal
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _company;
  String _currency = 'SAR';

  // Tab 1: COA
  List<Map<String, dynamic>> _accounts = [];
  
  // Tab 2: Ledger
  String? _selectedAccountId;
  String? _selectedAccountName;
  List<Map<String, dynamic>> _ledgerEntries = [];
  
  // Tab 3: Financial Position
  Map<String, dynamic> _financialPosition = {};
  Map<String, dynamic> _incomeStatement = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialConfig();
    _loadTabData(0);
  }

  Future<void> _loadInitialConfig() async {
    final company = await _db.getCurrentCompanyContext();
    if (mounted && company != null) {
      setState(() {
        _company = company;
        _currency = company['currency_code'] ?? 'SAR';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTabData(int tab) async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      final companies = await db.query('companies', limit: 1);
      if (companies.isNotEmpty) _company = companies.first;

      switch (tab) {
        case 0: await _loadJournal(); break;
        case 1: await _loadCOA(); break;
        case 2: if (_selectedAccountId != null) await _loadLedger(_selectedAccountId!); break;
        case 3: await _loadFinancials(); break;
      }
    } catch (e) {
      debugPrint('Error loading tab $tab: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadJournal() async {
    List<Map<String, dynamic>> data = [];
    final invoices = await _db.getInvoices();
    for (var inv in invoices) {
      final id = inv['id']?.toString() ?? '';
      final clientName = inv['client_id']?.toString() ?? tr('accounting.cash');
      final issueDate = inv['issue_date']?.toString() ?? '';
      final total = (inv['total'] as num?)?.toDouble() ?? 0;
      if (_searchQuery.isEmpty || id.toLowerCase().contains(_searchQuery.toLowerCase()) || clientName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        data.add({'id': id, 'type': 'sales', 'title': "${tr('accounting_module.actions.invoice')} - $clientName", 'date': issueDate.length >= 10 ? issueDate.substring(0, 10) : issueDate, 'amount': total, 'real_date': DateTime.tryParse(issueDate) ?? DateTime.now()});
      }
    }
    final journals = await _db.getJournalEntries();
    for (var j in journals) {
      final desc = j['description']?.toString() ?? '';
      final dateStr = j['date']?.toString() ?? '';
      final totalDebit = (j['total_debit'] as num?)?.toDouble() ?? 0;
      if (_searchQuery.isEmpty || desc.toLowerCase().contains(_searchQuery.toLowerCase())) {
        data.add({'id': j['id']?.toString() ?? '', 'type': 'entry', 'title': desc, 'date': dateStr, 'amount': totalDebit, 'real_date': DateTime.tryParse(dateStr) ?? DateTime.now()});
      }
    }
    data.sort((a, b) => (b['real_date'] as DateTime).compareTo(a['real_date'] as DateTime));
    _records = data;
  }

  Future<void> _loadCOA() async {
    _accounts = await _db.getChartOfAccounts();
  }

  Future<void> _loadLedger(String accountId) async {
    _ledgerEntries = await _db.getAccountLedger(accountId);
  }

  Future<void> _loadFinancials() async {
    _financialPosition = await _db.getFinancialPosition();
    _incomeStatement = await _db.getIncomeStatement();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('accounting_module.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                      Text(tr('accounting_module.subtitle'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                    ],
                  ),
                ),
                _buildActionButton(context, tr('accounting_module.actions.entry'), Icons.add_circle_outline, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ManualJournalScreen());
                  _loadTabData(_tabController.index);
                }),
                const SizedBox(width: 8),
                _buildActionButton(context, tr('accounting_module.actions.quotation'), Icons.description_outlined, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const QuotationScreen());
                  _loadTabData(_tabController.index);
                }),
                const SizedBox(width: 8),
                _buildActionButton(context, tr('accounting_module.actions.invoice'), Icons.receipt_long, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const InvoiceEntryScreen());
                  _loadTabData(_tabController.index);
                }, isPrimary: true),
              ],
            ),
          ),
          
          // Row 2 of Actions (QuickBooks style Quick-Bar)
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickIcon(tr('accounting_module.quick_actions.receipt'), Icons.account_balance_wallet, Colors.green, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ReceiptVoucherScreen());
                  _loadTabData(0);
                }),
                _buildQuickIcon(tr('accounting_module.quick_actions.payment'), Icons.payments, Colors.redAccent, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const PaymentVoucherScreen());
                  _loadTabData(0);
                }),
                _buildQuickIcon(tr('accounting_module.quick_actions.bank_reconciliation'), Icons.account_balance, Colors.blue, () async {
                  await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const BankReconciliationScreen());
                  _loadTabData(0);
                }),
                _buildQuickIcon(tr('accounting_module.quick_actions.close_period'), Icons.lock_clock, Colors.orange, () => _showClosePeriodDialog()),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.black87,
              unselectedLabelColor: context.mutedText,
              indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: tr('accounting_module.tabs.journal')),
                Tab(text: tr('accounting_module.tabs.coa')),
                Tab(text: tr('accounting_module.tabs.ledger')),
                Tab(text: tr('accounting_module.tabs.financial_position')),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                : TabBarView(controller: _tabController, children: [
                    _buildJournalTab(),
                    _buildCOATab(),
                    _buildLedgerTab(),
                    _buildFinancialTab(),
                  ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 0: اليومية العامة
  // ═══════════════════════════════════════════════════
  Widget _buildJournalTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _records.isEmpty
            ? _buildEmptyState(tr('accounting_module.messages.no_records'), Icons.search_off)
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 4),
                itemCount: _records.length,
                itemBuilder: (_, i) => _buildRecordCard(_records[i]),
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 1: شجرة الحسابات
  // ═══════════════════════════════════════════════════
  Widget _buildCOATab() {
    if (_accounts.isEmpty) return _buildEmptyState(tr('accounting_module.messages.no_accounts'), Icons.account_tree);
    
    final types = {
      'asset': tr('accounting_module.account_types.asset'), 
      'liability': tr('accounting_module.account_types.liability'), 
      'revenue': tr('accounting_module.account_types.revenue'), 
      'expense': tr('accounting_module.account_types.expense'), 
      'equity': tr('accounting_module.account_types.equity')
    };
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        children: [
          // Quick stats
          Row(
            children: [
              Expanded(child: _buildMiniStat(tr('accounting_module.tabs.coa'), "${_accounts.length}", Icons.account_tree, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStat(tr('accounting_module.account_types.asset'), "${_accounts.where((a) => a['type'] == 'asset').length}", Icons.trending_up, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStat(tr('accounting_module.account_types.liability'), "${_accounts.where((a) => a['type'] == 'liability').length}", Icons.trending_down, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStat(tr('accounting_module.account_types.expense'), "${_accounts.where((a) => a['type'] == 'expense').length}", Icons.receipt, Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add account button
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () => _showAddAccountDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, size: 16, color: Colors.black87),
                  const SizedBox(width: 4),
                  Text(tr('accounting_module.dialogs.add_account_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Accounts grouped by type
          ...types.entries.map((entry) {
            final typeAccounts = _accounts.where((a) => a['type'] == entry.key).toList();
            if (typeAccounts.isEmpty) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cardBorder.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _typeColor(entry.key).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(_typeIcon(entry.key), size: 16, color: _typeColor(entry.key)),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                        const Spacer(),
                        Text("${typeAccounts.length} حسابات", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...typeAccounts.map((acc) => InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAccountId = acc['id'];
                        _selectedAccountName = acc['name'];
                      });
                      _tabController.animateTo(2);
                      _loadTabData(2);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 48, alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _typeColor(entry.key).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                            child: Text(acc['code']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _typeColor(entry.key))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(acc['name']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 1))),
                          Text("${((acc['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1, color: ((acc['balance'] as num?)?.toDouble() ?? 0) >= 0 ? Colors.green : Colors.red)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 10, color: context.mutedText.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 2: الأستاذ العام
  // ═══════════════════════════════════════════════════
  Widget _buildLedgerTab() {
    if (_selectedAccountId == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(tr('accounting_module.messages.select_account_hint'), style: TextStyle(color: context.mutedText)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _tabController.animateTo(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              child: Text(tr('accounting_module.tabs.coa'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
        ]),
      );
    }

    // Account selector dropdown
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.cardSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    isExpanded: true, isDense: true, underline: const SizedBox(),
                    items: _accounts.map((a) => DropdownMenuItem(
                      value: a['id'] as String,
                      child: Text("${a['code']} - ${a['name']}", style: TextStyle(fontSize: context.bodySize - 1)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        final acc = _accounts.firstWhere((a) => a['id'] == v, orElse: () => {});
                        setState(() { _selectedAccountId = v; _selectedAccountName = acc['name']?.toString(); });
                        _loadTabData(2);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Ledger header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(tr('accounting_module.fields.statement'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))),
                Expanded(child: Text(tr('accounting_module.fields.date'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))),
                Expanded(child: Text(tr('accounting_module.fields.debit'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2, color: Colors.green))),
                Expanded(child: Text(tr('accounting_module.fields.credit'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2, color: Colors.red))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _ledgerEntries.isEmpty
            ? _buildEmptyState(tr('accounting.no_ledger_entries'), Icons.list_alt)
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                itemCount: _ledgerEntries.length,
                itemBuilder: (_, i) {
                  final e = _ledgerEntries[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.1)))),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(e['description']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 2), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Expanded(child: Text(e['date']?.toString() ?? '', style: TextStyle(fontSize: context.bodySize - 3, color: context.mutedText))),
                        Expanded(child: Text("${((e['debit'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}", style: TextStyle(fontSize: context.bodySize - 2, color: Colors.green))),
                        Expanded(child: Text("${((e['credit'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}", style: TextStyle(fontSize: context.bodySize - 2, color: Colors.red))),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 3: المركز المالي
  // ═══════════════════════════════════════════════════
  Widget _buildFinancialTab() {
    final assets = (_financialPosition['total_assets'] as num?)?.toDouble() ?? 0;
    final liabilities = (_financialPosition['total_liabilities'] as num?)?.toDouble() ?? 0;
    final revenue = (_financialPosition['total_revenue'] as num?)?.toDouble() ?? 0;
    final expenses = (_financialPosition['total_expenses'] as num?)?.toDouble() ?? 0;
    final netProfit = revenue - expenses;
    final equity = (_financialPosition['equity'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Row
          Row(
            children: [
              Expanded(child: _buildKPICard(tr('accounting_module.account_types.revenue'), revenue, Icons.trending_up, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildKPICard(tr('accounting_module.account_types.expense'), expenses, Icons.trending_down, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildKPICard(tr('ceo.metrics.profit'), netProfit, Icons.account_balance, netProfit >= 0 ? primaryOrange : Colors.red, isPrimary: true)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Balance Sheet
          Text(tr('accounting_module.sections.balance_sheet'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 8),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assets
              Expanded(child: _buildFinancialSection(tr('accounting_module.account_types.asset'), assets, _financialPosition['asset_accounts'] as List? ?? [], Colors.blue)),
              const SizedBox(width: 12),
              // Liabilities + Equity
              Expanded(child: Column(
                children: [
                  _buildFinancialSection(tr('accounting_module.account_types.liability'), liabilities, _financialPosition['liability_accounts'] as List? ?? [], Colors.red),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr('accounting_module.account_types.equity'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                        Text("${equity.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 2, color: primaryOrange)),
                      ],
                    ),
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),
          
          // P&L Summary
          Text(tr('accounting_module.sections.income_statement'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFinancialSection(tr('accounting_module.account_types.revenue'), revenue, _financialPosition['revenue_accounts'] as List? ?? [], Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildFinancialSection(tr('accounting_module.account_types.expense'), expenses, _financialPosition['expense_accounts'] as List? ?? [], Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Helper Widgets
  // ═══════════════════════════════════════════════════
  
  Widget _buildFinancialSection(String title, double total, List accounts, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: context.bodySize)),
              Text("${total.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 1, color: color)),
            ],
          ),
          const Divider(height: 16),
          ...accounts.map((acc) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${acc['code']} ${acc['name']}", style: TextStyle(fontSize: context.bodySize - 2), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text("${((acc['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}", style: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, double value, IconData icon, Color color, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPrimary ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text("${value.toStringAsFixed(2)}", style: TextStyle(fontSize: context.bodySize + 4, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(title, style: TextStyle(fontSize: 10, color: context.mutedText)),
      ]),
    );
  }

  void _showAddAccountDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedType = 'asset';
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.cardSurface,
      title: Text(tr('accounting_module.dialogs.add_account_title')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: codeCtrl, decoration: InputDecoration(labelText: tr('accounting_module.dialogs.account_code'), hintText: "e.g. 107")),
        const SizedBox(height: 8),
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: tr('accounting_module.dialogs.account_name'))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedType,
          decoration: InputDecoration(labelText: tr('accounting_module.dialogs.account_type')),
          items: [
            DropdownMenuItem(value: 'asset', child: Text(tr('accounting_module.account_types.asset'))),
            DropdownMenuItem(value: 'liability', child: Text(tr('accounting_module.account_types.liability'))),
            DropdownMenuItem(value: 'revenue', child: Text(tr('accounting_module.account_types.revenue'))),
            DropdownMenuItem(value: 'expense', child: Text(tr('accounting_module.account_types.expense'))),
            DropdownMenuItem(value: 'equity', child: Text(tr('accounting_module.account_types.equity'))),
          ],
          onChanged: (v) { if (v != null) selectedType = v; },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('accounting_module.invoice_entry.cancel'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
          onPressed: () async {
            if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
            await _db.addAccount({
              'id': 'ACC_${const Uuid().v4().substring(0, 8).toUpperCase()}',
              'code': codeCtrl.text,
              'name': nameCtrl.text,
              'type': selectedType,
              'balance': 0,
            });
            Navigator.pop(ctx);
            _loadTabData(1);
          },
          child: Text(tr('hr.form.buttons.save'), style: const TextStyle(color: Colors.black87)),
        ),
      ],
    ));
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) { _searchQuery = v; _loadTabData(0); },
        style: TextStyle(color: context.textColor, fontSize: context.bodySize - 1),
        decoration: InputDecoration(
          isDense: true, hintText: tr('accounting.search_hint'),
          hintStyle: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: context.mutedText, size: 18),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final type = record['type'];
    final color = type == 'sales' ? primaryOrange : type == 'purchase' ? Colors.blueAccent : Colors.purpleAccent;
    final icon = type == 'sales' ? Icons.receipt_long : type == 'purchase' ? Icons.shopping_bag : Icons.article;
    final label = type == 'sales' ? tr('accounting_module.actions.invoice') : type == 'purchase' ? tr('inventory.purchase_orders') : tr('accounting_module.actions.entry');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _handleRecordTap(record),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: TextStyle(color: color, fontSize: context.bodySize - 3, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text(record['date'] ?? "", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
              ]),
              Text(record['title'] ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Text("${(record['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
          ],
        ),
      ),
    );
  }

  void _handleRecordTap(Map<String, dynamic> record) {
    final type = record['type'];
    final id = record['id'];
    if (type == 'sales' || type == 'purchase') {
      _showInvoiceDetails(id);
    } else {
      _showJournalEntryDetails(id, record['title'] ?? "");
    }
  }

  void _showInvoiceDetails(String invoiceId) async {
    final invoices = await _db.getInvoices();
    final invoice = invoices.firstWhere((i) => i['id'] == invoiceId, orElse: () => {});
    if (invoice.isEmpty) return;
    final lines = await _db.getInvoiceLines(invoiceId);
    if (!mounted) return;
    final total = (invoice['total'] as num?)?.toDouble() ?? 0;
    
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(color: context.obsidianGlass, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(tr('accounting_module.actions.invoice'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(onPressed: () async { await PdfService.generateInvoice(invoice: invoice, items: lines, company: _company ?? {'name': 'Hisabati', 'currency': _currency}); }, icon: const Icon(Icons.print, color: primaryOrange)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
          ]),
          const Divider(),
          Text("${tr('pdf.invoice_number')}: $invoiceId", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Expanded(child: ListView.builder(itemCount: lines.length, itemBuilder: (_, idx) {
            final line = lines[idx];
            final qty = (line['quantity'] as num?)?.toDouble() ?? 1;
            final price = (line['price_at_sale'] as num?)?.toDouble() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(line['name']?.toString() ?? tr('accounting_module.actions.entry'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("${tr('pdf.quantity')}: $qty × $price", style: const TextStyle(color: Colors.white70)),
                ])),
                Text("${(qty * price).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
            );
          })),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${tr('pdf.total')}:", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text("${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryOrange)),
          ]),
        ]),
      ),
    ));
  }

  void _showJournalEntryDetails(String entryId, String description) async {
    final lines = await _db.getJournalEntryLines(entryId);
    if (!mounted) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: context.obsidianGlass, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(tr('accounting.entry_details'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
          ]),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text("${tr('accounting.entry_label')}: $entryId", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Text("${tr('accounting.memo_label')}: $description", style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(flex: 2, child: Text(tr('accounting.account_header'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70))),
            Expanded(child: Text(tr('accounting.debit_header'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 13))),
            Expanded(child: Text(tr('accounting.credit_header'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13))),
          ]),
          Expanded(child: ListView.builder(itemCount: lines.length, itemBuilder: (_, idx) {
            final line = lines[idx];
            return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
              Expanded(flex: 2, child: Text(line['account_name']?.toString() ?? 'غير محدد', style: const TextStyle(fontSize: 12))),
              Expanded(child: Text("${line['debit'] ?? 0}", style: const TextStyle(color: Colors.green, fontSize: 12))),
              Expanded(child: Text("${line['credit'] ?? 0}", style: const TextStyle(color: Colors.red, fontSize: 12))),
            ]));
          })),
        ]),
      ),
    ));
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: context.mutedText)),
    ]));
  }

  Widget _buildQuickIcon(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showClosePeriodDialog() {
    final yearCtrl = TextEditingController(text: "${tr('accounting.year_prefix')} ${DateTime.now().year}");
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.cardSurface,
      title: Text(tr('accounting.close_period_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('accounting.close_period_desc')),
          const SizedBox(height: 16),
          TextField(controller: yearCtrl, decoration: InputDecoration(labelText: tr('accounting.period_name_label'))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () async {
            final start = "${DateTime.now().year}-01-01";
            final end = "${DateTime.now().year}-12-31";
            final success = await _engine.closeFiscalYear(yearCtrl.text, start, end);
            Navigator.pop(ctx);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('accounting.close_success')), backgroundColor: Colors.green));
              _loadTabData(0);
            }
          },
          child: Text(tr('accounting.close_rotate_btn'), style: const TextStyle(color: Colors.black)),
        )
      ],
    ));
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryOrange.withValues(alpha: isPrimary ? 1.0 : 0.3)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: isPrimary ? Colors.black87 : primaryOrange),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isPrimary ? Colors.black87 : primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) { case 'asset': return Colors.blue; case 'liability': return Colors.red; case 'revenue': return Colors.green; case 'expense': return Colors.orange; case 'equity': return Colors.purple; default: return Colors.grey; }
  }
  IconData _typeIcon(String type) {
    switch (type) { case 'asset': return Icons.trending_up; case 'liability': return Icons.trending_down; case 'revenue': return Icons.monetization_on; case 'expense': return Icons.receipt; case 'equity': return Icons.account_balance; default: return Icons.help; }
  }
}
