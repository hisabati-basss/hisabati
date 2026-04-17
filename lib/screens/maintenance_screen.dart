import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/maintenance_service.dart';
import '../services/asset_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final AssetService _assetService = AssetService();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _paymentAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;
    
    // Load asset maintenance schedules
    _schedules = await db.rawQuery('''
      SELECT ms.*, a.name as asset_name, a.status as asset_status, a.plate_number 
      FROM maintenance_schedules ms
      JOIN assets a ON ms.asset_id = a.id
      ORDER BY ms.scheduled_date ASC
    ''');

    // Load available assets for selection (vehicles/equipment)
    _assets = await db.query('assets', where: 'is_deleted = 0');

    // Load Cash and Bank accounts for payment
    _paymentAccounts = await DatabaseHelper().getAccounts(type: 'asset');

    setState(() => _isLoading = false);
  }

  Future<void> _addSchedule(String assetId, String reason, String date, {double? odometer}) async {
    await _maintenanceService.addSchedule(
      assetId: assetId,
      reason: reason,
      date: date,
      odometerReading: odometer,
    );
    _loadData();
  }

  Future<void> _completeMaintenance(String id, String assetId, String assetName, double cost, String accountId, {double? currentOdometer}) async {
    await _maintenanceService.completeMaintenance(
      scheduleId: id,
      assetId: assetId,
      assetName: assetName,
      totalCost: cost,
      paymentAccountId: accountId,
      currentOdometer: currentOdometer,
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildStatsRow(context, isMobile),
            const SizedBox(height: 24),
            _buildSchedulesList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.build_circle, color: Colors.black87),
        label: Text(tr('maintenance.btn_add_schedule'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('maintenance.header_title'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
        const SizedBox(height: 4),
        Text(tr('maintenance.header_subtitle'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isMobile) {
    int pending = _schedules.where((s) => s['status'] == 'pending').length;
    double totalCost = _schedules.fold(0.0, (sum, item) => sum + (item['total_cost'] ?? 0.0));

    return Row(
      children: [
        Expanded(child: _buildSimpleKpi(tr('maintenance.stats_pending'), pending.toString(), Icons.timer_outlined, Colors.orangeAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildSimpleKpi(tr('maintenance.stats_total_cost'), "${totalCost.toStringAsFixed(0)} ${tr('ceo.currency.sar')}", Icons.payments_outlined, Colors.greenAccent)),
      ],
    );
  }

  Widget _buildSimpleKpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: context.iconSize),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
              Text(value, style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSchedulesList(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));
    if (_schedules.isEmpty) return Center(child: Text(tr('maintenance.no_schedules'), style: TextStyle(color: context.mutedText)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('maintenance.list_title'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schedules.length,
          itemBuilder: (context, index) {
            final item = _schedules[index];
            bool isCompleted = item['status'] == 'completed';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                color: context.cardSurface.withValues(alpha: isCompleted ? 0.3 : 1.0),
                borderRadius: BorderRadius.circular(context.cardRadius),
                border: Border.all(color: isCompleted ? Colors.transparent : context.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.toys_outlined, color: isCompleted ? context.mutedText : primaryOrange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['asset_name'] ?? tr('common.unknown_asset'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (item['plate_number'] != null)
                          Text("لوحة: ${item['plate_number']}", style: TextStyle(color: primaryOrange, fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(item['reason'] ?? tr('maintenance.default_reason'), style: TextStyle(color: context.mutedText, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: context.mutedText),
                            const SizedBox(width: 4),
                            Text(item['scheduled_date'] ?? "", style: TextStyle(color: context.mutedText, fontSize: 12)),
                            if (item['odometer_reading'] != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.speed, size: 12, color: context.mutedText),
                              const SizedBox(width: 4),
                              Text("${item['odometer_reading']} كم", style: TextStyle(color: context.mutedText, fontSize: 12)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    _buildCapsuleButton(
                      context, 
                      label: tr('maintenance.btn_complete'), 
                      onTap: () => _showCompleteDialog(context, item),
                      color: Colors.greenAccent
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(tr('maintenance.status_completed'), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("${(item['total_cost'] ?? 0).toStringAsFixed(0)} ${tr('ceo.currency.sar')}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCapsuleButton(BuildContext context, {required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    if (_assets.isEmpty) {
      _showEmptyAssetsWarning(context);
      return;
    }

    String? selectedAsset;
    final reasonController = TextEditingController();
    final odometerController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
        title: Text(tr('maintenance.dialog_add_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: tr('maintenance.dialog_asset_label')),
                items: _assets.map((a) => DropdownMenuItem(value: a['id'].toString(), child: Text(a['name'] ?? ""))).toList(),
                onChanged: (v) => selectedAsset = v,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController, 
                decoration: InputDecoration(
                  labelText: tr('maintenance.dialog_reason_label'),
                  prefixIcon: const Icon(Icons.description_outlined)
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: odometerController, 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "قراءة العداد الحالية (كم)",
                  prefixIcon: Icon(Icons.speed)
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController, 
                decoration: InputDecoration(
                  labelText: tr('maintenance.dialog_date_label'),
                  prefixIcon: const Icon(Icons.calendar_today)
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('maintenance.btn_cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black),
            onPressed: () {
              if (selectedAsset != null) {
                _addSchedule(
                  selectedAsset!, 
                  reasonController.text, 
                  dateController.text,
                  odometer: double.tryParse(odometerController.text)
                );
                Navigator.pop(context);
              }
            },
            child: Text(tr('maintenance.btn_save')),
          ),
        ],
      ),
    );
  }

  void _showEmptyAssetsWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: const Text("لا توجد مركبات أو معدات"),
        content: const Text("يجب إضافة مركبة أو معدة أولاً لتتمكن من جدولة صيانة لها. هل تود إضافة واحدة الآن؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showQuickAddAssetDialog(context);
            },
            child: const Text("إضافة مركبة جديدة"),
          ),
        ],
      ),
    );
  }

  void _showQuickAddAssetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final modelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: const Text("إضافة مركبة/معدة جديدة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم المركبة (مثلاً: تويوتا هايلكس)")),
            TextField(controller: plateController, decoration: const InputDecoration(labelText: "رقم اللوحة")),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: "الموديل / السنة")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _assetService.createAsset({
                  'name': nameController.text,
                  'plate_number': plateController.text,
                  'model': modelController.text,
                  'status': 'available',
                });
                Navigator.pop(context);
                _loadData();
                _showAddDialog(context);
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, Map<String, dynamic> item) {
    final costController = TextEditingController();
    final odometerController = TextEditingController(text: (item['odometer_reading'] ?? "").toString());
    String? selectedAccount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
        title: Text(tr('maintenance.dialog_complete_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("إتمام صيانة: ${item['asset_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: costController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: tr('maintenance.dialog_cost_label'),
                  prefixIcon: const Icon(Icons.attach_money)
                )
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "حساب الدفع (QuickBooks Style)",
                  prefixIcon: Icon(Icons.account_balance_wallet)
                ),
                items: _paymentAccounts.map((a) => DropdownMenuItem(
                  value: a['id'].toString(), 
                  child: Text("${a['name']} (${(a['balance'] ?? 0).toStringAsFixed(0)})")
                )).toList(),
                onChanged: (v) => selectedAccount = v,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: odometerController, 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "قراءة العداد عند الإتمام (كم)",
                  prefixIcon: Icon(Icons.speed)
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('maintenance.btn_cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () {
              double cost = double.tryParse(costController.text) ?? 0.0;
              if (selectedAccount != null) {
                _completeMaintenance(
                  item['id'], 
                  item['asset_id'], 
                  item['asset_name'] ?? "", 
                  cost, 
                  selectedAccount!,
                  currentOdometer: double.tryParse(odometerController.text)
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار حساب الدفع")));
              }
            },
            child: Text(tr('maintenance.btn_confirm')),
          ),
        ],
      ),
    );
  }
}
