import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class MonitoringService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> getMonitoringSummary() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final next30DaysStr = now.add(const Duration(days: 30)).toIso8601String().split('T')[0];

    int chequesDueToday = 0;
    int bouncedCheques = 0;
    int expiringIDs = 0;
    int pendingLeaves = 0;
    int lowStock = 0;
    int expiredItems = 0;
    int pendingMaintenance = 0;
    int unpostedDrafts = 0;

    try {
      // 1. Cheques Monitoring
      final res1 = await db.rawQuery("SELECT COUNT(*) as count FROM cheques WHERE status = 'pending' AND due_date <= ? AND is_deleted = 0", [todayStr]);
      chequesDueToday = res1.first['count'] as int? ?? 0;
      
      final res2 = await db.rawQuery("SELECT COUNT(*) as count FROM cheques WHERE status = 'bounced' AND is_deleted = 0");
      bouncedCheques = res2.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint("Monitoring Error (Cheques): $e");
    }

    try {
      // 2. HR Monitoring
      // residency: Expired or expiring IDs in next 30 days
      final res3 = await db.rawQuery("SELECT COUNT(*) as count FROM employees WHERE id_expiry_date <= ? AND is_deleted = 0", [next30DaysStr]);
      expiringIDs = res3.first['count'] as int? ?? 0;

      // pending_leaves: Any leave request with 'pending' status
      final res4 = await db.rawQuery("SELECT COUNT(*) as count FROM leave_requests WHERE status = 'pending' AND is_deleted = 0");
      pendingLeaves = res4.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint("Monitoring Error (HR): $e");
    }

    try {
      // 3. Inventory Monitoring
      final res5 = await db.rawQuery("SELECT COUNT(*) as count FROM items WHERE quantity <= min_stock_level AND is_deleted = 0");
      lowStock = res5.first['count'] as int? ?? 0;
      
      final res6 = await db.rawQuery("SELECT COUNT(*) as count FROM items WHERE expiry_date <= ? AND is_deleted = 0", [todayStr]);
      expiredItems = res6.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint("Monitoring Error (Inventory): $e");
    }

    try {
      // 4. Maintenance Monitoring
      final res7 = await db.rawQuery("SELECT COUNT(*) as count FROM maintenance_schedules WHERE status = 'scheduled' AND scheduled_date <= ? AND is_deleted = 0", [todayStr]);
      pendingMaintenance = res7.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint("Monitoring Error (Maintenance): $e");
    }

    try {
      // 5. Accounting Monitoring
      final res8 = await db.rawQuery("SELECT COUNT(*) as count FROM invoices WHERE status = 'draft' AND is_deleted = 0");
      unpostedDrafts = res8.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint("Monitoring Error (Accounting): $e");
    }

    return {
      'cheque_due': chequesDueToday,
      'bounced': bouncedCheques,
      'residency': expiringIDs,
      'leave_balance': pendingLeaves,
      'low_stock': lowStock,
      'material_expiry': expiredItems,
      'maintenance': pendingMaintenance,
      'invoice_audit_ref': unpostedDrafts,
    };
  }
}
