import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class MaintenanceService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  /// Adds a new maintenance schedule with optional odometer reading.
  Future<void> addSchedule({
    required String assetId,
    required String reason,
    required String date,
    double? odometerReading,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('maintenance_schedules', {
      'id': 'MNTS_${DateTime.now().millisecondsSinceEpoch}',
      'asset_id': assetId,
      'scheduled_date': date,
      'reason': reason,
      'status': 'pending',
      'total_cost': 0.0,
      'odometer_reading': odometerReading,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
      'device_id': await _dbHelper.getDeviceFingerprint(),
    });
  }

  /// Completes maintenance, records costs, chooses payment account, and generates journal entry.
  Future<void> completeMaintenance({
    required String scheduleId,
    required String assetId,
    required String assetName,
    required double totalCost,
    required String paymentAccountId,
    double? currentOdometer,
  }) async {
    final db = await _dbHelper.database;
    final String entryId = 'JRN_${DateTime.now().millisecondsSinceEpoch}_MAINT';
    final String nowStr = DateTime.now().toIso8601String();
    final deviceId = await _dbHelper.getDeviceFingerprint();

    await db.transaction((txn) async {
      // 1. Update Schedule Status
      await txn.update('maintenance_schedules', {
        'status': 'completed',
        'total_cost': totalCost,
        'payment_account_id': paymentAccountId,
        'updated_at': nowStr,
        'sync_status': 0,
      }, where: 'id = ?', whereArgs: [scheduleId]);

      // 2. Update Asset Odometer (if provided)
      if (currentOdometer != null) {
        await txn.update('assets', {
          'last_mileage': currentOdometer,
          'updated_at': nowStr,
          'sync_status': 0,
        }, where: 'id = ?', whereArgs: [assetId]);
      }

      // 3. Create Journal Entry (QuickBooks Style)
      // Debit: Maintenance Expense (ACC_EXPENSE_MAINTENANCE)
      // Credit: Selected Payment Account (Bank/Cash)
      
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': nowStr,
        'description': 'صيانة معدة/مركبة: $assetName',
        'reference_id': scheduleId,
        'sync_status': 0,
        'updated_at': nowStr,
        'device_id': deviceId,
      });

      // Lines
      await txn.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': 'ACC_EXPENSE_MAINTENANCE', // We'll ensure this exists or use a generic expense
        'debit': totalCost,
        'credit': 0,
      });

      await txn.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': paymentAccountId,
        'debit': 0,
        'credit': totalCost,
      });
      
      // Update account balances
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [totalCost, paymentAccountId]
      );
    });
  }
}
