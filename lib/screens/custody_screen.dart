import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../services/custody_service.dart';
import '../theme/app_theme_extension.dart';

class CustodyScreen extends StatefulWidget {
  const CustodyScreen({super.key});

  @override
  State<CustodyScreen> createState() => _CustodyScreenState();
}

class _CustodyScreenState extends State<CustodyScreen> {
  final CustodyService _custodyService = CustodyService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Map<String, dynamic>> _financialCustodies = [];
  List<Map<String, dynamic>> _assetCustodies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initCustodyData();
  }

  Future<void> _initCustodyData() async {
    await _ensureCustodySchema();
    await _loadData();
  }

  Future<void> _ensureCustodySchema() async {
    try {
      final db = await _dbHelper.database;
      final tableInfo = await db.rawQuery('PRAGMA table_info(financial_custodies)');
      final columns = tableInfo.map((c) => c['name'].toString()).toList();
      
      if (!columns.contains('cleared_amount')) {
        await db.execute('ALTER TABLE financial_custodies ADD COLUMN cleared_amount REAL DEFAULT 0.0');
      }
      if (!columns.contains('sync_status')) {
        await db.execute('ALTER TABLE financial_custodies ADD COLUMN sync_status INTEGER DEFAULT 0');
      }
      if (!columns.contains('updated_at')) {
        await db.execute('ALTER TABLE financial_custodies ADD COLUMN updated_at TEXT');
      }
      if (!columns.contains('device_id')) {
        await db.execute('ALTER TABLE financial_custodies ADD COLUMN device_id TEXT');
      }
      if (!columns.contains('is_deleted')) {
        await db.execute('ALTER TABLE financial_custodies ADD COLUMN is_deleted INTEGER DEFAULT 0');
      }
    } catch (e) {
      debugPrint("Custody Schema Migration Error: $e");
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final financial = await _custodyService.getFinancialCustodies();
      final assets = await _custodyService.getAssetCustodies();
      if (mounted) {
        setState(() {
          _financialCustodies = financial;
          _assetCustodies = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading custody data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildGlassHeader(isDark),
          const SizedBox(height: 20),
          _buildStatsRow(isDark),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : _buildTabsContent(isDark),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'asset_custody',
            onPressed: () => _showIssueAssetDialog(),
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.devices, color: Colors.white),
            label: Text(tr('custody.btn_issue_asset'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'financial_custody',
            onPressed: () => _showIssueFinancialDialog(),
            backgroundColor: primaryOrange,
            icon: const Icon(Icons.payments, color: Colors.black),
            label: Text(tr('custody.btn_issue_financial'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tr('custody.header_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(tr('custody.header_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final totalFinancial = _financialCustodies.fold(0.0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildGlassStat(tr('custody.stats_total_assets'), "${_assetCustodies.length}", Icons.inventory_2_outlined, Colors.blueAccent, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildGlassStat(tr('custody.stats_total_financial'), "${totalFinancial.toStringAsFixed(0)} ${tr('ceo.currency.sar')}", Icons.account_balance_wallet_outlined, primaryOrange, isDark)),
        ],
      ),
    );
  }

  Widget _buildGlassStat(String label, String value, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: context.mutedText, fontSize: 10), overflow: TextOverflow.ellipsis),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsContent(bool isDark) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: primaryOrange,
            labelColor: primaryOrange,
            unselectedLabelColor: context.mutedText,
            tabs: [
              Tab(text: tr('custody.tab_financial')),
              Tab(text: tr('custody.tab_assets')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFinancialList(isDark),
                _buildAssetList(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialList(bool isDark) {
    if (_financialCustodies.isEmpty) {
      return Center(child: Text(tr('custody.no_financial'), style: TextStyle(color: context.mutedText)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _financialCustodies.length,
      itemBuilder: (context, index) => _buildCustodyGlassCard(_financialCustodies[index], true, isDark),
    );
  }

  Widget _buildAssetList(bool isDark) {
    if (_assetCustodies.isEmpty) {
      return Center(child: Text(tr('custody.no_assets'), style: TextStyle(color: context.mutedText)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _assetCustodies.length,
      itemBuilder: (context, index) => _buildCustodyGlassCard(_assetCustodies[index], false, isDark),
    );
  }

  Widget _buildCustodyGlassCard(Map<String, dynamic> item, bool isFinancial, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isFinancial && (item['status'] ?? '') != 'settled')
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                              onPressed: () => _showSettleDialog(item),
                              tooltip: "تسوية العهدة",
                            ),
                          Text(
                            item['employee_name'] ?? 'Employee', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFinancial ? (item['reason'] ?? '') : (item['asset_name'] ?? ''),
                        style: TextStyle(color: context.mutedText, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isFinancial 
                              ? "${item['amount']} ${tr('ceo.currency.sar')}${ (item['status'] == 'settled') ? ' (تمت التسوية)' : ''}" 
                              : (item['barcode'] ?? ''),
                            style: TextStyle(
                              color: item['status'] == 'settled' ? Colors.greenAccent : (isFinancial ? primaryOrange : Colors.blueAccent), 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isFinancial ? Icons.payments_outlined : Icons.qr_code_scanner, 
                            color: item['status'] == 'settled' ? Colors.greenAccent : (isFinancial ? primaryOrange : Colors.blueAccent), 
                            size: 14
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  backgroundColor: (isFinancial ? primaryOrange : Colors.blueAccent).withValues(alpha: 0.1),
                  child: Icon(
                    isFinancial ? Icons.person : Icons.inventory_2, 
                    color: isFinancial ? primaryOrange : Colors.blueAccent
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIssueFinancialDialog() async {
    final employees = await _custodyService.getEmployees();
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('hr.no_employees_found'))));
      return;
    }

    String? selectedEmpId;
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(tr('custody.btn_issue_financial'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E24),
                  value: selectedEmpId,
                  decoration: InputDecoration(labelText: tr('hr.employee')),
                  style: const TextStyle(color: Colors.white),
                  items: employees.map((e) => DropdownMenuItem(
                    value: e['id'].toString(),
                    child: Text(e['name'] ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedEmpId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: tr('common.amount'), suffixText: tr('ceo.currency.sar')),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: tr('common.reason')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null || amountController.text.isEmpty) return;
                
                try {
                  // Safeguard migration before insert
                  await _ensureCustodySchema();
                  
                  await _custodyService.issueFinancialCustody(
                    employeeId: selectedEmpId!,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    reason: reasonController.text,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('common.save_success')), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${tr('common.error')}: $e"), backgroundColor: Colors.redAccent));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: Text(tr('common.save'), style: const TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueAssetDialog() async {
    final employees = await _custodyService.getEmployees();
    final assets = await _custodyService.getAvailableAssets();
    
    if (employees.isEmpty || assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('custody.no_emp_or_assets'))));
      return;
    }

    String? selectedEmpId;
    String? selectedAssetId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(tr('custody.btn_issue_asset'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E24),
                value: selectedEmpId,
                decoration: InputDecoration(labelText: tr('hr.employee')),
                style: const TextStyle(color: Colors.white),
                items: employees.map((e) => DropdownMenuItem(
                  value: e['id'].toString(),
                  child: Text(e['name'] ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedEmpId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E24),
                value: selectedAssetId,
                decoration: InputDecoration(labelText: tr('assets_module.title')),
                style: const TextStyle(color: Colors.white),
                items: assets.map((a) => DropdownMenuItem(
                  value: a['id'].toString(),
                  child: Text(a['name'] ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedAssetId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null || selectedAssetId == null) return;
                await _custodyService.issueAssetCustody(
                  employeeId: selectedEmpId!,
                  assetId: selectedAssetId!,
                  conditionOnIssue: 'Excellent',
                );
                Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: Text(tr('common.save'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleDialog(Map<String, dynamic> item) async {
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    final descCtrl = TextEditingController(text: "تسوية عهدة الموظف: ${item['employee_name']}");
    final List<Map<String, dynamic>> expenseAccounts = await (await _dbHelper.database).query('accounts', where: "type = 'expense'");

    String? selectedAccountId = expenseAccounts.isNotEmpty ? expenseAccounts.first['id'] : null;

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text("تسوية عهدة مالية", style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("الموظف: ${item['employee_name']}", style: TextStyle(color: context.mutedText)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E24),
                  value: selectedAccountId,
                  items: expenseAccounts.map((a) => DropdownMenuItem(value: a['id'].toString(), child: Text(a['name'] ?? 'Account'))).toList(),
                  onChanged: (v) => setDialogState(() => selectedAccountId = v),
                  decoration: const InputDecoration(labelText: "حساب المصروف"),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "المبلغ الفعلي للمصروف"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "الوصف"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (selectedAccountId == null) return;
                await _dbHelper.settleCustody(
                  custodyId: item['id'],
                  expenseAmount: double.tryParse(amountCtrl.text) ?? 0.0,
                  expenseAccountId: selectedAccountId!,
                  description: descCtrl.text,
                );
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت التسوية بنجاح"), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: const Text("تأكيد التسوية", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }
}
