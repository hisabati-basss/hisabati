import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class AssetService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Calculates and records depreciation for all assets up to the current date.
  /// This should be run monthly or upon request.
  Future<void> runDepreciationCycle() async {
    final db = await _db.database;
    final assets = await db.query('assets', where: 'status = ? AND is_deleted = 0', whereArgs: ['active']);
    final now = DateTime.now();

    for (var asset in assets) {
      final purchaseDateStr = asset['purchase_date'] as String?;
      final lastDepDateStr = asset['last_depreciation_date'] as String?;
      final costPrice = (asset['cost_price'] as num?)?.toDouble() ?? 0.0;
      final salvageValue = (asset['salvage_value'] as num?)?.toDouble() ?? 0.0;
      final usefulLifeMonths = (asset['useful_life_months'] as int?) ?? 60;
      final method = asset['depreciation_method'] as String? ?? 'straight_line';

      if (purchaseDateStr == null || costPrice <= 0) continue;

      DateTime startDate = lastDepDateStr != null 
          ? DateTime.parse(lastDepDateStr) 
          : DateTime.parse(purchaseDateStr);

      // Calculate months passed since last depreciation
      int monthsToDepreciate = (now.year - startDate.year) * 12 + now.month - startDate.month;
      
      if (monthsToDepreciate <= 0) continue;

      double monthlyDepreciation = 0.0;
      if (method == 'straight_line') {
        monthlyDepreciation = (costPrice - salvageValue) / usefulLifeMonths;
      }

      double totalDepreciationForPeriod = monthlyDepreciation * monthsToDepreciate;

      // Ensure we don't depreciate below salvage value
      final existingDepRes = await db.rawQuery(
        'SELECT SUM(amount) as total FROM asset_depreciation_logs WHERE asset_id = ?', 
        [asset['id']]
      );
      double alreadyDepreciated = (existingDepRes.first['total'] as num?)?.toDouble() ?? 0.0;

      if (alreadyDepreciated + totalDepreciationForPeriod > (costPrice - salvageValue)) {
        totalDepreciationForPeriod = (costPrice - salvageValue) - alreadyDepreciated;
      }

      if (totalDepreciationForPeriod > 0) {
        // 1. Log the depreciation
        await db.insert('asset_depreciation_logs', {
          'id': 'DEP_${asset['id']}_${now.millisecondsSinceEpoch}',
          'asset_id': asset['id'],
          'amount': totalDepreciationForPeriod,
          'date': now.toIso8601String().substring(0, 10),
          'notes': 'Automatic depreciation for $monthsToDepreciate months',
          'sync_status': 0,
        });

        // 2. Update the asset's last depreciation date
        await db.update('assets', {
          'last_depreciation_date': now.toIso8601String().substring(0, 10),
        }, where: 'id = ?', whereArgs: [asset['id']]);

        // 3. Create a Journal Entry (Accounting Integration)
        final entryId = 'JE_DEP_${asset['id']}_${now.millisecondsSinceEpoch}';
        await db.insert('journal_entries', {
          'id': entryId,
          'date': now.toIso8601String().substring(0, 10),
          'description': 'إهلاك آلي للأصل: ${asset['name']}',
          'reference_id': asset['id'],
        });

        // Debit: Depreciation Expense
        await db.insert('journal_entry_lines', {
          'id': '${entryId}_L1',
          'entry_id': entryId,
          'account_id': 'ACC_EXP_DEP', // Depreciation Expense
          'debit': totalDepreciationForPeriod,
          'credit': 0.0,
        });

        // Credit: Accumulated Depreciation (Contra-Asset)
        await db.insert('journal_entry_lines', {
          'id': '${entryId}_L2',
          'entry_id': entryId,
          'account_id': 'ACC_ASSET_ACC_DEP', // Accumulated Depreciation
          'debit': 0.0,
          'credit': totalDepreciationForPeriod,
        });

        // 4. Update account balances
        await db.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [totalDepreciationForPeriod, 'ACC_EXP_DEP']);
        await db.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [totalDepreciationForPeriod, 'ACC_ASSET_ACC_DEP']);

        debugPrint("AssetService: Recorded $totalDepreciationForPeriod depreciation for asset ${asset['id']}");
      }
    }
  }

  Future<void> transferAsset(String assetId, String employeeId, String location) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Log the transfer
      await txn.insert('asset_custody_logs', {
        'id': 'CUST_${DateTime.now().millisecondsSinceEpoch}',
        'asset_id': assetId,
        'employee_id': employeeId,
        'location': location,
        'issued_date': now,
        'status': 'transferred',
        'sync_status': 0,
      });

      // 2. Update asset record
      await txn.update('assets', {
        'assigned_to': employeeId,
        'location': location,
        'updated_at': now,
      }, where: 'id = ?', whereArgs: [assetId]);
    });
  }
}
