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
      final res1 = await db.rawQuery("SELECT COUNT(*) as count FROM cheques WHERE status = 'pending' AND due_date <= ?", [todayStr]);
      chequesDueToday = res1.first['count'] as int? ?? 0;
      
      final res2 = await db.rawQuery("SELECT COUNT(*) as count FROM cheques WHERE status = 'bounced'");
      bouncedCheques = res2.first['count'] as int? ?? 0;
    } catch (e) {
      // Ignore if table missing
    }

    try {
      // 2. HR Monitoring
      final res3 = await db.rawQuery("SELECT COUNT(*) as count FROM employees WHERE id_expiry_date BETWEEN ? AND ?", [todayStr, next30DaysStr]);
      expiringIDs = res3.first['count'] as int? ?? 0;
    } catch (e) {
      // Ignore
    }

    try {
      // 3. Inventory Monitoring
      final res5 = await db.rawQuery("SELECT COUNT(*) as count FROM inventory_items WHERE quantity <= reorder_level");
      lowStock = res5.first['count'] as int? ?? 0;
      
      final res6 = await db.rawQuery("SELECT COUNT(*) as count FROM inventory_batches WHERE expiry_date <= ?", [todayStr]);
      expiredItems = res6.first['count'] as int? ?? 0;
    } catch (e) {
      // Ignore
    }

    try {
      // 4. Maintenance Monitoring
      final res7 = await db.rawQuery("SELECT COUNT(*) as count FROM maintenance_schedules WHERE status = 'pending' AND scheduled_date <= ?", [todayStr]);
      pendingMaintenance = res7.first['count'] as int? ?? 0;
    } catch (e) {
      // Ignore
    }

    try {
      // 5. Accounting Monitoring
      final res8 = await db.rawQuery("SELECT COUNT(*) as count FROM invoices WHERE status = 'draft'");
      unpostedDrafts = res8.first['count'] as int? ?? 0;
    } catch (e) {
      // Ignore
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
