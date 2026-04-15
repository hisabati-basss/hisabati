import 'database_helper.dart';
import 'notification_service.dart';

class HRProService {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifications = NotificationService();

  /// Checks for document and contract expirations and triggers alerts.
  Future<void> runAutoChecks() async {
    final db = await _db.database;
    final now = DateTime.now();
    final alertThreshold = now.add(const Duration(days: 30));

    // 1. Check Documents
    final docs = await db.query(
      'documents',
      where: 'expiry_date IS NOT NULL AND status = ? AND is_deleted = 0',
      whereArgs: ['active'],
    );

    for (var doc in docs) {
      final expiry = DateTime.tryParse(doc['expiry_date'].toString());
      if (expiry != null && expiry.isBefore(alertThreshold)) {
        final daysLeft = expiry.difference(now).inDays;
        _notifications.notify(
          title: "⚠️ تنبيه انتهاء مستند",
          message: "المستند (${doc['name']}) سينتهي خلال $daysLeft يوم.",
          type: NotificationType.warning,
        );
      }
    }

    // 2. Check Contracts
    final contracts = await db.rawQuery('''
      SELECT c.*, e.name as employee_name
      FROM employee_contracts c
      JOIN employees e ON c.employee_id = e.id
      WHERE c.end_date IS NOT NULL AND c.status = 'active' AND c.is_deleted = 0
    ''');

    for (var contract in contracts) {
      final expiry = DateTime.tryParse(contract['end_date'].toString());
      if (expiry != null && expiry.isBefore(alertThreshold)) {
        final daysLeft = expiry.difference(now).inDays;
        _notifications.notify(
          title: "📜 تنبيه انتهاء عقد",
          message: "عقد الموظف (${contract['employee_name']}) سينتهي خلال $daysLeft يوم.",
          type: NotificationType.warning,
        );
      }
    }
  }
}
