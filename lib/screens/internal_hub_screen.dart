import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class InternalHubScreen extends StatefulWidget {
  const InternalHubScreen({super.key});
  @override
  State<InternalHubScreen> createState() => _InternalHubScreenState();
}

class _InternalHubScreenState extends State<InternalHubScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _bom = [];
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      _bom = (await db.query('bom', orderBy: 'created_at DESC', limit: 20)).map((b) => Map<String, dynamic>.from(b)).toList();
      _orders = (await db.query('manufacturing_orders', orderBy: 'created_at DESC', limit: 20)).map((o) => Map<String, dynamic>.from(o)).toList();
    } catch (e) { debugPrint("Hub: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _orders.where((o) => o['status'] == 'pending' || o['status'] == 'in_progress').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("المركز الصناعي", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("${_bom.length} وصفة تصنيع • $pendingOrders أمر قيد التنفيذ", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
              const SizedBox(height: 12),

              // KPIs
              Row(children: [
                Expanded(child: _buildKPI("وصفات التصنيع", "${_bom.length}", Colors.blue, Icons.build_circle)),
                const SizedBox(width: 6),
                Expanded(child: _buildKPI("أوامر الإنتاج", "${_orders.length}", Colors.purple, Icons.precision_manufacturing)),
                const SizedBox(width: 6),
                Expanded(child: _buildKPI("قيد التنفيذ", "$pendingOrders", pendingOrders > 0 ? Colors.orange : Colors.green, Icons.pending_actions)),
              ]),
              const SizedBox(height: 16),

              Text("وصفات التصنيع (BOM)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
              const SizedBox(height: 8),
              if (_bom.isEmpty) _emptyState("لا توجد وصفات تصنيع"),
              ..._bom.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cardBorder.withValues(alpha: 0.08))),
                child: Row(children: [
                  Icon(Icons.build_circle, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b['name']?.toString() ?? b['id']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                  Text("${b['output_quantity'] ?? '1'} وحدة", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              )),

              const SizedBox(height: 16),
              Text("أوامر الإنتاج", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
              const SizedBox(height: 8),
              if (_orders.isEmpty) _emptyState("لا توجد أوامر إنتاج"),
              ..._orders.map((o) {
                final status = o['status']?.toString() ?? 'pending';
                final color = status == 'completed' ? Colors.green : status == 'in_progress' ? Colors.blue : Colors.orange;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.12))),
                  child: Row(children: [
                    Icon(Icons.precision_manufacturing, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o['bom_id']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
                      Text("كمية: ${o['quantity'] ?? 1} • ${o['created_at']?.toString().substring(0, 10) ?? ''}", style: TextStyle(color: context.mutedText, fontSize: 10)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(status == 'completed' ? "مكتمل" : status == 'in_progress' ? "جاري" : "معلق", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                );
              }),
            ]),
          ),
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(msg, style: TextStyle(color: context.mutedText, fontSize: 12))),
  );

  Widget _buildKPI(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: context.mutedText, fontSize: 9)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ])),
      ]),
    );
  }
}
