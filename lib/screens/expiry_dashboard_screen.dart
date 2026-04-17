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

      final expired = await db.rawQuery('''
        SELECT *, sku as batch_number, quantity as batch_qty
        FROM items
        WHERE expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date != 'null' AND expiry_date < ?
        ORDER BY expiry_date ASC
      ''', [now]);

      final expiringSoon = await db.rawQuery('''
        SELECT *, sku as batch_number, quantity as batch_qty
        FROM items
        WHERE expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date != 'null' AND expiry_date >= ? AND expiry_date <= ?
        ORDER BY expiry_date ASC
      ''', [now, soon]);

      final safe = await db.rawQuery('''
        SELECT *, sku as batch_number, quantity as batch_qty
        FROM items
        WHERE expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date != 'null' AND expiry_date > ?
        ORDER BY expiry_date ASC
        LIMIT 20
      ''', [soon]);

      if (mounted) { setState(() {
        _expired = expired.map((e) => Map<String, dynamic>.from(e)).toList();
        _expiringSoon = expiringSoon.map((e) => Map<String, dynamic>.from(e)).toList();
        _safe = safe.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      }); }
    } catch (e) {
      debugPrint("Expiry load: $e");
      if (mounted) { setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme mode dynamically to provide solid colors instead of transparent/glass
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor, // FIXED: Solid background to prevent black screen errors when popping or animating
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("رقابة انتهاء الصلاحية", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
          Text(
            _isLoading ? "جاري الفحص..." : _expired.isEmpty && _expiringSoon.isEmpty ? "المستودع آمن بالكامل" : "يوجد ${_expired.length} منتهي و ${_expiringSoon.length} ينتهي قريباً",
            style: TextStyle(color: _isLoading ? context.mutedText : _expired.isEmpty ? Colors.green : Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.refresh, size: 16, color: Colors.white), SizedBox(width: 6), Text("تحديث", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Solid KPIs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 16),
          child: Row(children: [
            Expanded(child: _buildSolidKPI("منتهي الصلاحية", "${_expired.length}", Colors.red, Icons.error, cardColor, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildSolidKPI("ينتهي خلال شهر", "${_expiringSoon.length}", Colors.orange, Icons.warning, cardColor, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildSolidKPI("مخزون آمن", "${_safe.length}", Colors.green, Icons.check_circle, cardColor, isDark)),
          ]),
        ),

        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : (_expired.isEmpty && _expiringSoon.isEmpty && _safe.isEmpty)
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.event_available, size: 64, color: context.mutedText.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text("المستودع خالي من تواريخ الصلاحية المسجلة", style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.bold)),
                ]))
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
                  children: [
                    if (_expired.isNotEmpty) ...[
                      _buildSectionTitle("🔴 منتجات منتهية الصلاحية", Colors.red),
                      ..._expired.map((p) => _buildSolidRow(p, Colors.red, cardColor, isDark)),
                      const SizedBox(height: 24),
                    ],
                    if (_expiringSoon.isNotEmpty) ...[
                      _buildSectionTitle("🟡 منتجات تقترب من الانتهاء", Colors.orange),
                      ..._expiringSoon.map((p) => _buildSolidRow(p, Colors.orange, cardColor, isDark)),
                      const SizedBox(height: 24),
                    ],
                    if (_safe.isNotEmpty) ...[
                      _buildSectionTitle("🟢 مخزون آمن", Colors.green),
                      ..._safe.take(15).map((p) => _buildSolidRow(p, Colors.green, cardColor, isDark)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
    );
  }

  Widget _buildSolidRow(Map<String, dynamic> p, Color color, Color cardColor, bool isDark) {
    final name = p['name']?.toString() ?? 'صنف غير معروف';
    final sku = p['batch_number']?.toString() ?? 'بدون باركود';
    final expiry = p['expiry_date']?.toString() ?? '';
    final qty = (p['batch_qty'] as num?)?.toDouble() ?? 0;

    int daysRemaining = 0;
    try {
      final expiryDate = DateTime.parse(expiry);
      daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    } catch (_) {}

    final bool isExpired = daysRemaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(isExpired ? Icons.dangerous : daysRemaining <= 30 ? Icons.warning_amber : Icons.check_circle_outline, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textColor)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.qr_code, size: 14, color: context.mutedText),
            const SizedBox(width: 4),
            Text(sku, style: TextStyle(color: context.mutedText, fontSize: 12)),
            const SizedBox(width: 16),
            Icon(Icons.inventory_2, size: 14, color: context.mutedText),
            const SizedBox(width: 4),
            Text("الكمية: ${qty.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: 12)),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(expiry.length >= 10 ? expiry.substring(0, 10) : expiry, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(isExpired ? "منتهي منذ ${daysRemaining.abs()} يوم" : daysRemaining == 0 ? "ينتهي اليوم" : "متبقي $daysRemaining يوم",
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSolidKPI(String title, String value, Color color, IconData icon, Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: context.mutedText, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: context.textColor, height: 1.0)),
      ]),
    );
  }
}
