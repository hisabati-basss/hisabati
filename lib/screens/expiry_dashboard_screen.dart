import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class ExpiryDashboardScreen extends StatefulWidget {
  const ExpiryDashboardScreen({super.key});
  @override
  State<ExpiryDashboardScreen> createState() => _ExpiryDashboardScreenState();
}

class _ExpiryDashboardScreenState extends State<ExpiryDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _expired = [];
  List<Map<String, dynamic>> _expiringSoon = [];
  List<Map<String, dynamic>> _safe = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      final now = DateTime.now().toIso8601String().split('T')[0];
      final soon = DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];

      // Products with expiry_date
      final expired = await db.rawQuery('''
        SELECT p.*, ib.expiry_date, ib.batch_number, ib.quantity as batch_qty
        FROM inventory_batches ib
        JOIN products p ON ib.product_id = p.id
        WHERE ib.expiry_date IS NOT NULL AND ib.expiry_date < ? AND ib.quantity > 0
        ORDER BY ib.expiry_date ASC
      ''', [now]);

      final expiringSoon = await db.rawQuery('''
        SELECT p.*, ib.expiry_date, ib.batch_number, ib.quantity as batch_qty
        FROM inventory_batches ib
        JOIN products p ON ib.product_id = p.id
        WHERE ib.expiry_date >= ? AND ib.expiry_date <= ? AND ib.quantity > 0
        ORDER BY ib.expiry_date ASC
      ''', [now, soon]);

      final safe = await db.rawQuery('''
        SELECT p.*, ib.expiry_date, ib.batch_number, ib.quantity as batch_qty
        FROM inventory_batches ib
        JOIN products p ON ib.product_id = p.id
        WHERE ib.expiry_date > ? AND ib.quantity > 0
        ORDER BY ib.expiry_date ASC
        LIMIT 20
      ''', [soon]);

      if (mounted) setState(() {
        _expired = expired.map((e) => Map<String, dynamic>.from(e)).toList();
        _expiringSoon = expiringSoon.map((e) => Map<String, dynamic>.from(e)).toList();
        _safe = safe.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Expiry load: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("رقابة انتهاء الصلاحية", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text(_expired.isEmpty && _expiringSoon.isEmpty ? "✅ لا توجد منتجات منتهية أو قريبة" : "⚠️ ${_expired.length} منتهي • ${_expiringSoon.length} قريب",
                style: TextStyle(color: _expired.isEmpty ? Colors.green : Colors.red, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            ])),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryOrange.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh, size: 14, color: primaryOrange), const SizedBox(width: 4), Text("تحديث", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12))]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // KPIs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            Expanded(child: _buildKPI("منتهي الصلاحية", "${_expired.length}", Colors.red, Icons.error)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI("خلال 30 يوم", "${_expiringSoon.length}", Colors.orange, Icons.warning)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI("آمن", "${_safe.length}", Colors.green, Icons.check_circle)),
          ]),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : (_expired.isEmpty && _expiringSoon.isEmpty && _safe.isEmpty)
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.event_available, size: 48, color: context.mutedText.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text("لا توجد بيانات صلاحية — أضف دفعات بتواريخ انتهاء", style: TextStyle(color: context.mutedText, fontSize: 12)),
                ]))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_expired.isNotEmpty) ...[
                      _sectionHeader("🔴 منتهي الصلاحية", Colors.red),
                      ..._expired.map((p) => _buildExpiryRow(p, Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    if (_expiringSoon.isNotEmpty) ...[
                      _sectionHeader("🟡 ينتهي خلال 30 يوم", Colors.orange),
                      ..._expiringSoon.map((p) => _buildExpiryRow(p, Colors.orange)),
                      const SizedBox(height: 12),
                    ],
                    if (_safe.isNotEmpty) ...[
                      _sectionHeader("🟢 آمن", Colors.green),
                      ..._safe.take(10).map((p) => _buildExpiryRow(p, Colors.green)),
                    ],
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize, color: color)),
    );
  }

  Widget _buildExpiryRow(Map<String, dynamic> p, Color color) {
    final name = p['name']?.toString() ?? '';
    final batch = p['batch_number']?.toString() ?? '';
    final expiry = p['expiry_date']?.toString() ?? '';
    final qty = (p['batch_qty'] as num?)?.toDouble() ?? 0;

    // Days remaining
    int daysRemaining = 0;
    try {
      final expiryDate = DateTime.parse(expiry);
      daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Icon(daysRemaining < 0 ? Icons.error : daysRemaining <= 30 ? Icons.warning : Icons.check_circle, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
          Text("دفعة: $batch • كمية: ${qty.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(expiry.length >= 10 ? expiry.substring(0, 10) : expiry, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
          Text(daysRemaining < 0 ? "منتهي منذ ${daysRemaining.abs()} يوم" : daysRemaining == 0 ? "ينتهي اليوم!" : "متبقي $daysRemaining يوم",
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildKPI(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: context.mutedText, fontSize: 9)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ])),
      ]),
    );
  }
}
