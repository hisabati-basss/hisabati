import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
        AND is_deleted = 0
        ORDER BY expiry_date ASC
      ''', [now]);

      final expiringSoon = await db.rawQuery('''
        SELECT *, sku as batch_number, quantity as batch_qty
        FROM items
        WHERE expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date != 'null' AND expiry_date >= ? AND expiry_date <= ?
        AND is_deleted = 0
        ORDER BY expiry_date ASC
      ''', [now, soon]);

      final safe = await db.rawQuery('''
        SELECT *, sku as batch_number, quantity as batch_qty
        FROM items
        WHERE expiry_date IS NOT NULL AND expiry_date != '' AND expiry_date != 'null' AND expiry_date > ?
        AND is_deleted = 0
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
      if (mounted) { setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Compact Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          "رقابة انتهاء الصلاحية",
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined, color: primaryOrange, size: 16),
                      ],
                    ),
                    Text(
                      _isLoading ? "جاري الفحص..." : "يوجد ${_expired.length} منتهي و ${_expiringSoon.length} ينتهي قريباً",
                      style: TextStyle(color: _expired.isEmpty ? Colors.green : Colors.red, fontSize: 9),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      const Icon(Icons.refresh, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text("تحديث", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Glass KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildMiniKPI("منتهي", "${_expired.length}", Colors.red)),
                      Container(width: 1, height: 16, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                      Expanded(child: _buildMiniKPI("قريباً", "${_expiringSoon.length}", Colors.orange)),
                      Container(width: 1, height: 16, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                      Expanded(child: _buildMiniKPI("آمن", "${_safe.length}", Colors.green)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    if (_expired.isNotEmpty) ...[
                      _buildSectionLabel("🔴 منتجات منتهية"),
                      ..._expired.map((p) => _buildGlassRow(p, Colors.red, isDark)),
                    ],
                    if (_expiringSoon.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSectionLabel("🟡 تقترب من الانتهاء"),
                      ..._expiringSoon.map((p) => _buildGlassRow(p, Colors.orange, isDark)),
                    ],
                    if (_safe.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSectionLabel("🟢 مخزون آمن"),
                      ..._safe.map((p) => _buildGlassRow(p, Colors.green, isDark)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKPI(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 8)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildGlassRow(Map<String, dynamic> p, Color color, bool isDark) {
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
      margin: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                // Status on left
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expiry.length >= 10 ? expiry.substring(0, 10) : expiry, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color)
                    ),
                    Text(
                      isExpired ? "منتهي منذ ${daysRemaining.abs()}ي" : daysRemaining == 0 ? "ينتهي اليوم" : "متبقي $daysRemainingي",
                      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const Spacer(),
                // Info on right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("الكمية: ${qty.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: 8)),
                          const SizedBox(width: 8),
                          Text(sku, style: TextStyle(color: context.mutedText, fontSize: 8)),
                          const SizedBox(width: 4),
                          Icon(Icons.qr_code, size: 8, color: context.mutedText),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isExpired ? Icons.dangerous_outlined : daysRemaining <= 30 ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                    color: color, 
                    size: 16
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
