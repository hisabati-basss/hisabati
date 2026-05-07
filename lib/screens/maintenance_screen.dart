import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _ensureTableSchema();
    await _loadSchedules();
    await _loadAssets();
  }

  Future<void> _ensureTableSchema() async {
    try {
      final db = await _db.database;
      final tableInfo = await db.rawQuery('PRAGMA table_info(maintenance_schedules)');
      final columns = tableInfo.map((c) => c['name'].toString()).toList();
      
      if (!columns.contains('estimated_cost')) {
        await db.execute('ALTER TABLE maintenance_schedules ADD COLUMN estimated_cost REAL DEFAULT 0.0');
      }
      if (!columns.contains('sync_status')) {
        await db.execute('ALTER TABLE maintenance_schedules ADD COLUMN sync_status INTEGER DEFAULT 0');
      }
      if (!columns.contains('created_at')) {
        await db.execute('ALTER TABLE maintenance_schedules ADD COLUMN created_at TEXT');
      }
      if (!columns.contains('completion_date')) {
        await db.execute('ALTER TABLE maintenance_schedules ADD COLUMN completion_date TEXT');
      }
    } catch (e) {
      debugPrint("Migration error: $e");
    }
  }

  Future<void> _loadAssets() async {
    final db = await _db.database;
    final results = await db.query('assets', where: 'is_deleted = 0');
    if (mounted) setState(() => _assets = results);
  }

  Future<void> _loadSchedules() async {
    if (mounted) setState(() => _isLoading = true);
    final db = await _db.database;
    try {
      final results = await db.rawQuery('''
        SELECT ms.*, a.name as asset_name, a.barcode as asset_barcode
        FROM maintenance_schedules ms
        JOIN assets a ON ms.asset_id = a.id
        WHERE ms.status = 'pending'
        ORDER BY ms.scheduled_date ASC
      ''');
      if (mounted) {
        setState(() {
          _schedules = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading schedules: $e");
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tr('maintenance.list_title'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : _schedules.isEmpty
                ? Center(child: Text(tr('maintenance.no_schedules'), style: TextStyle(color: context.mutedText)))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) => _buildMaintenanceGlassCard(_schedules[index], isDark),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(),
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.build_circle, color: Colors.black),
        label: Text(tr('maintenance.btn_add_schedule'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              Text(tr('maintenance.header_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(tr('maintenance.header_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final totalCost = _schedules.fold(0.0, (sum, item) => sum + ((item['estimated_cost'] as num?)?.toDouble() ?? 0.0));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildGlassStat(tr('maintenance.stats_pending'), "${_schedules.length}", Icons.timer_outlined, Colors.orangeAccent, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildGlassStat(tr('maintenance.stats_total_cost'), "${totalCost.toStringAsFixed(0)} ${tr('ceo.currency.sar')}", Icons.payments_outlined, Colors.greenAccent, isDark)),
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
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceGlassCard(Map<String, dynamic> schedule, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _completeMaintenance(schedule),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tr('maintenance.btn_complete'), style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        schedule['asset_name'] ?? 'Asset', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${tr('inventory_module.barcode')}: ${schedule['asset_barcode']}", 
                        style: TextStyle(color: context.mutedText, fontSize: 10), 
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              "${schedule['scheduled_date']?.toString().split('T').first}", 
                              style: TextStyle(color: context.mutedText, fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.calendar_month, color: context.mutedText, size: 10),
                          const SizedBox(width: 8),
                          Text(
                            "${schedule['estimated_cost'] ?? 0} ${tr('ceo.currency.sar')}", 
                            style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.payments, color: primaryOrange, size: 10),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.car_repair, color: primaryOrange, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddScheduleDialog() {
    if (_assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('maintenance.no_assets_error'))));
      return;
    }

    String? selectedAssetId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(tr('maintenance.btn_add_schedule'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E24),
                  value: selectedAssetId,
                  decoration: InputDecoration(
                    labelText: tr('maintenance.field_asset'),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: _assets.map((a) => DropdownMenuItem(
                    value: a['id'].toString(),
                    child: Text(a['name'] ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedAssetId = v),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(tr('maintenance.field_date'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  subtitle: Text("${selectedDate.toIso8601String().split('T').first}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.calendar_today, color: primaryOrange),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: tr('maintenance.field_cost'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    suffixText: tr('ceo.currency.sar'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedAssetId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('maintenance.error_select_asset'))));
                  return;
                }
                
                try {
                  // Ensure schema is updated BEFORE insert
                  await _ensureTableSchema();
                  
                  final db = await _db.database;
                  final double? cost = double.tryParse(costController.text);
                  
                  await db.insert('maintenance_schedules', {
                    'id': 'MNTS_${DateTime.now().millisecondsSinceEpoch}',
                    'asset_id': selectedAssetId,
                    'scheduled_date': selectedDate.toIso8601String(),
                    'estimated_cost': cost ?? 0.0,
                    'status': 'pending',
                    'sync_status': 0,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr('common.save_success')),
                      backgroundColor: Colors.green,
                    ));
                  }
                  _loadSchedules();
                } catch (e) {
                  debugPrint("Error saving maintenance: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("${tr('common.error')}: $e"),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
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

  Future<void> _completeMaintenance(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text(tr('maintenance.dialog_complete_title'), style: const TextStyle(color: Colors.white)),
        content: Text("${tr('maintenance.btn_confirm')}: ${schedule['asset_name']}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: Text(tr('common.confirm'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await _db.database;
      try {
        await db.update('maintenance_schedules', 
          {'status': 'completed', 'completion_date': DateTime.now().toIso8601String()},
          where: 'id = ?', 
          whereArgs: [schedule['id']]
        );
      } catch (e) {
        await db.update('maintenance_schedules', 
          {'status': 'completed'},
          where: 'id = ?', 
          whereArgs: [schedule['id']]
        );
      }
      _loadSchedules();
    }
  }
}
