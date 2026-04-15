import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class AuditService {
  static final AuditService _instance = AuditService._();
  factory AuditService() => _instance;
  AuditService._();

  /// Logs a security or sensitive action to the local trace table
  static Future<void> log({
    required String action,     // 'create', 'update', 'delete', 'login', 'export'
    required String entityType, // 'invoice', 'employee', 'payment', etc.
    String? entityId,
    String? description,
    String? oldValue,           // JSON string (Optional)
    String? newValue,           // JSON string (Optional)
    bool isCritical = false,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      await db.insert('security_audit', {
        'id': const Uuid().v4(),
        'action_type': action,
        'description': description ?? '$action on $entityType: ${entityId ?? "N/A"}',
        'is_critical': isCritical ? 1 : 0,
        'old_value': oldValue,
        'new_value': newValue,
        'sync_status': 0,
        'updated_at': DateTime.now().toIso8601String(),
        'device_id': await DatabaseHelper().getDeviceFingerprint(),
      });
    } catch (e) {
      // Fail silently to not block user operations, but log to debug
      print("🚨 Audit Log Error: $e");
    }
  }

  /// Convenience method for audit viewing
  static Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final db = await DatabaseHelper().database;
    return await db.query('security_audit', orderBy: 'updated_at DESC', limit: limit);
  }
}
