import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/custody_service.dart';
import '../services/payroll_service.dart';
import '../services/database_helper.dart';

class CustodyScreen extends StatefulWidget {
  final bool isMobile;
  const CustodyScreen({super.key, this.isMobile = false});

  @override
  State<CustodyScreen> createState() => _CustodyScreenState();
}

class _CustodyScreenState extends State<CustodyScreen> with SingleTickerProviderStateMixin {
  final CustodyService _custodyService = CustodyService();
  final PayrollService _payrollService = PayrollService();
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;

  List<Map<String, dynamic>> _financialCustodies = [];
  List<Map<String, dynamic>> _assetCustodies = [];
  List<Map<String, dynamic>> _employees = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fins = await _custodyService.getFinancialCustodies();
      final assets = await _custodyService.getAssetCustodies();
      final emps = await _payrollService.getEmployees();
      
      setState(() {
        _financialCustodies = fins;
        _assetCustodies = assets;
        _employees = emps;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('yyyy/MM/dd HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(context.sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.work_history, color: Colors.blueAccent, size: context.iconSize - 6),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('custody.title'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
                    Text(tr('custody.subtitle'), style: TextStyle(fontSize: context.bodySize - 4, color: context.mutedText)),
                  ],
                ),
                const Spacer(),
                if (!widget.isMobile)
                  ElevatedButton.icon(
                    onPressed: _showIssueFinancialDialog,
                    icon: Icon(Icons.attach_money, color: Colors.white, size: context.iconSize - 10),
                    label: Text(tr('custody.btn_issue_fin'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodySize - 3)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: const Size(60, 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                const SizedBox(width: 4),
                if (!widget.isMobile)
                  ElevatedButton.icon(
                    onPressed: _showIssueAssetDialog,
                    icon: Icon(Icons.devices, color: Colors.white, size: context.iconSize - 10),
                    label: Text(tr('custody.btn_issue_asset'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.bodySize - 3)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: const Size(60, 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMetricsRow(context),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: context.textColor,
              unselectedLabelColor: context.mutedText,
              indicatorColor: primaryOrange,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: context.bodySize - 2),
              tabs: [
                Tab(text: tr('custody.financial_tab'), height: 28),
                Tab(text: tr('custody.asset_tab'), height: 28),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFinancialTab(context),
                  _buildAssetTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    double totalPendingFin = _financialCustodies
        .where((c) => c['status'] == CustodyService.FIN_PENDING)
        .fold(0.0, (sum, c) => sum + ((c['amount'] as num?)?.toDouble() ?? 0));

    int activeAssets = _assetCustodies.length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(context, tr('custody.metric_financial'), totalPendingFin.toStringAsFixed(0), Icons.money_off, Colors.redAccent),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildMetricCard(context, tr('custody.metric_assets'), activeAssets.toString(), Icons.laptop_chromebook, Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: context.iconSize - 6),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 4)),
              Text(value, style: TextStyle(color: context.textColor, fontSize: context.bodySize + 2, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: _financialCustodies.length,
        separatorBuilder: (context, index) => Divider(color: context.cardBorder, height: 1),
        itemBuilder: (context, index) {
          final c = _financialCustodies[index];
          final status = c['status']?.toString() ?? '';
          bool isPending = status == CustodyService.FIN_PENDING;
          Color statusColor = isPending ? Colors.orange : Colors.green;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: statusColor, size: context.iconSize - 10),
            ),
            title: Text(c['employee_name']?.toString() ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
            subtitle: Text("Amt: ${c['amount']} - ${c['reason']}", style: TextStyle(fontSize: context.bodySize - 5), maxLines: 1),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: context.bodySize - 5, fontWeight: FontWeight.bold)),
                ),
                if (isPending) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: ElevatedButton(
                      onPressed: () => _showClearFinancialDialog(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      child: Text(tr('custody.btn_clear'), style: TextStyle(color: Colors.white, fontSize: context.bodySize - 5)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetTab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: _assetCustodies.length,
        separatorBuilder: (context, index) => Divider(color: context.cardBorder, height: 1),
        itemBuilder: (context, index) {
          final c = _assetCustodies[index];
          final status = c['status']?.toString() ?? '';
          bool isWithEmp = status == 'مسلم لموظف';
          Color statusColor = isWithEmp ? Colors.blueAccent : Colors.grey;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.devices, color: statusColor, size: context.iconSize - 10),
            ),
            title: Text(c['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
            subtitle: Text("Emp: ${c['location'] ?? 'Unknown'}", style: TextStyle(fontSize: context.bodySize - 5), maxLines: 1),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: context.bodySize - 5, fontWeight: FontWeight.bold)),
                ),
                if (isWithEmp) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: ElevatedButton(
                      onPressed: () => _showReturnAssetDialog(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      child: Text(tr('custody.btn_return'), style: TextStyle(color: Colors.white, fontSize: context.bodySize - 5)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- DIALOGS ---

  void _showIssueFinancialDialog() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('custody.error_no_employees'))));
      return;
    }

    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String? selectedEmpId = _employees.first['id']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.bgSurface,
            title: Text(tr('custody.dialog_issue_fin_title')),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedEmpId,
                    decoration: InputDecoration(labelText: tr('custody.select_employee')),
                    items: _employees.map((e) => DropdownMenuItem(value: e['id']?.toString(), child: Text(e['name']?.toString() ?? ''))).toList(),
                    onChanged: (val) => setDialogState(() => selectedEmpId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: tr('custody.amount'), suffixText: tr('ceo.currency.sar')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(labelText: tr('custody.reason')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty || selectedEmpId == null) return;
                  await _custodyService.issueFinancialCustody(
                    employeeId: selectedEmpId!, 
                    amount: double.tryParse(amountController.text) ?? 0,
                    reason: reasonController.text,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(tr('custody.confirm_issue'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showClearFinancialDialog(Map<String, dynamic> custody) {
    final notesController = TextEditingController();
    final empName = custody['employee_name']?.toString() ?? '';
    final amount = custody['amount']?.toString() ?? '0';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text(tr('custody.dialog_clear_fin_title', args: [empName])),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${tr('custody.amount')}: $amount ${tr('ceo.currency.sar')}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(tr('custody.clearance_msg')),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: tr('custody.clearance_notes')),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('hr.cancel'))),
          ElevatedButton(
            onPressed: () async {
              await _custodyService.clearFinancialCustody(
                id: custody['id']?.toString() ?? '',
                clearanceNotes: notesController.text,
              );
              Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: Text(tr('custody.confirm_clear'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIssueAssetDialog() async {
    final assets = await _custodyService.getAvailableAssets();

    if (assets.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('custody.error_no_assets'))));
      return;
    }
    if (_employees.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('custody.error_no_employees'))));
      return;
    }

    String? selectedAssetId = assets.first['id']?.toString();
    String? selectedEmpId = _employees.first['id']?.toString();
    final condController = TextEditingController(text: "جيدة");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.bgSurface,
            title: Text(tr('custody.dialog_issue_asset_title')),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAssetId,
                    decoration: InputDecoration(labelText: tr('custody.select_asset')),
                    items: assets.map((a) => DropdownMenuItem(value: a['id']?.toString(), child: Text(a['name']?.toString() ?? ''))).toList(),
                    onChanged: (val) => setDialogState(() => selectedAssetId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEmpId,
                    decoration: InputDecoration(labelText: tr('custody.select_employee')),
                    items: _employees.map((e) => DropdownMenuItem(value: e['id']?.toString(), child: Text(e['name']?.toString() ?? ''))).toList(),
                    onChanged: (val) => setDialogState(() => selectedEmpId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: condController,
                    decoration: InputDecoration(labelText: tr('custody.asset_condition')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedEmpId == null || selectedAssetId == null) return;
                  await _custodyService.issueAssetCustody(
                    assetId: selectedAssetId!,
                    employeeId: selectedEmpId!,
                    conditionOnIssue: condController.text,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: Text(tr('custody.confirm_asset_issue'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showReturnAssetDialog(Map<String, dynamic> asset) {
    final condController = TextEditingController(text: "جيدة");
    bool isDamaged = false;
    final name = asset['name']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.bgSurface,
            title: Text(tr('custody.dialog_return_asset_title', args: [name])),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${tr('hr.new_employee')}: ${asset['location'] ?? ''}"),
                  const SizedBox(height: 16),
                  TextField(
                    controller: condController,
                    decoration: InputDecoration(labelText: tr('custody.return_condition')),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(tr('custody.is_damaged')),
                    value: isDamaged,
                    onChanged: (val) => setDialogState(() => isDamaged = val),
                    activeColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  await _custodyService.returnAssetCustody(
                    assetId: asset['id']?.toString() ?? '',
                    conditionOnReturn: condController.text,
                    isDamaged: isDamaged,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                child: Text(tr('custody.confirm_return'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }
}
