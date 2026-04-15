import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _assets = [];
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
      SELECT ms.*, a.name as asset_name, a.status as asset_status 
      FROM maintenance_schedules ms
      JOIN assets a ON ms.asset_id = a.id
      ORDER BY ms.scheduled_date ASC
    ''');

    // Load available assets for selection (vehicles/equipment)
    _assets = await db.query('assets');

    setState(() => _isLoading = false);
  }

  Future<void> _addSchedule(String assetId, String reason, String date) async {
    final db = await DatabaseHelper().database;
    await db.insert('maintenance_schedules', {
      'id': 'MNTS_${DateTime.now().millisecondsSinceEpoch}',
      'asset_id': assetId,
      'scheduled_date': date,
      'reason': reason,
      'status': 'pending',
      'total_cost': 0.0
    });
    _loadData();
  }

  Future<void> _completeMaintenance(String id, double cost) async {
    final db = await DatabaseHelper().database;
    await db.update('maintenance_schedules', {
      'status': 'completed',
      'total_cost': cost,
    }, where: 'id = ?', whereArgs: [id]);
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
                        Text(item['reason'] ?? tr('maintenance.default_reason'), style: TextStyle(color: context.mutedText, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: context.mutedText),
                            const SizedBox(width: 4),
                            Text(item['scheduled_date'] ?? "", style: TextStyle(color: context.mutedText, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    _buildCapsuleButton(
                      context, 
                      label: tr('maintenance.btn_complete'), 
                      onTap: () => _showCompleteDialog(context, item['id']),
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
    String? selectedAsset;
    final reasonController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text(tr('maintenance.dialog_add_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: tr('maintenance.dialog_asset_label')),
              items: _assets.map((a) => DropdownMenuItem(value: a['id'].toString(), child: Text(a['name'] ?? ""))).toList(),
              onChanged: (v) => selectedAsset = v,
            ),
            TextField(controller: reasonController, decoration: InputDecoration(labelText: tr('maintenance.dialog_reason_label'))),
            TextField(controller: dateController, decoration: InputDecoration(labelText: tr('maintenance.dialog_date_label'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('maintenance.btn_cancel'))),
          ElevatedButton(
            onPressed: () {
              if (selectedAsset != null) {
                _addSchedule(selectedAsset!, reasonController.text, dateController.text);
                Navigator.pop(context);
              }
            },
            child: Text(tr('maintenance.btn_save')),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String id) {
    final costController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text(tr('maintenance.dialog_complete_title')),
        content: TextField(
          controller: costController, 
          keyboardType: TextInputType.number, 
          decoration: InputDecoration(labelText: tr('maintenance.dialog_cost_label'))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('maintenance.btn_cancel'))),
          ElevatedButton(
            onPressed: () {
              double cost = double.tryParse(costController.text) ?? 0.0;
              _completeMaintenance(id, cost);
              Navigator.pop(context);
            },
            child: Text(tr('maintenance.btn_confirm')),
          ),
        ],
      ),
    );
  }
}
