import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class DepreciationService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Processes depreciation for all eligible assets in the system.
  /// Returns a map with summary of the operation.
  Future<Map<String, dynamic>> processAllDepreciations() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    
    int assetsProcessed = 0;
    double totalDepreciationAmount = 0.0;
    int entriesCreated = 0;

    final assets = await db.query('assets', where: 'status != ? AND is_deleted = 0', whereArgs: ['scrap']);

    await db.transaction((txn) async {
      for (var asset in assets) {
        try {
          final String assetId = (asset['id'] ?? '').toString();
          if (assetId.isEmpty) continue;
          
          final String assetName = (asset['name'] ?? 'Asset').toString();
          final double cost = (asset['cost_price'] as num?)?.toDouble() ?? 0.0;
          final double salvage = (asset['salvage_value'] as num?)?.toDouble() ?? 0.0;
          
          // Fix: The column is useful_life not useful_life_months
          final int usefulLifeMonths = (asset['useful_life'] as int?) ?? (asset['useful_life_months'] as int?) ?? 60;
          
          final dynamic pDateRaw = asset['purchase_date'];
          if (pDateRaw == null) continue;
          final String purchaseDateStr = pDateRaw.toString();
          
          final String? lastDepDateStr = asset['last_depreciation_date']?.toString();

          if (cost <= salvage || usefulLifeMonths <= 0) continue;

          final double monthlyDepreciation = (cost - salvage) / usefulLifeMonths;
          
          // Determine starting point for catch-up
          DateTime startDate = DateTime.parse(lastDepDateStr ?? purchaseDateStr);
          
          // If we have a last dep date, we start from the next month
          if (lastDepDateStr != null) {
            startDate = DateTime(startDate.year, startDate.month + 1, 1);
          } else {
            // If no last dep date, start from purchase month
            startDate = DateTime(startDate.year, startDate.month, 1);
          }

          // Target: Current month start
          DateTime targetDate = DateTime(now.year, now.month, 1);

          DateTime cursorDate = startDate;
          bool assetUpdated = false;
          
          while (cursorDate.isBefore(targetDate) || _isSameMonth(cursorDate, targetDate)) {
             final DateTime purchaseDate = DateTime.parse(purchaseDateStr);
             int totalMonthsElapsed = _monthsBetween(purchaseDate, cursorDate) + 1;
             
             if (totalMonthsElapsed > usefulLifeMonths) break;

             final String periodStr = cursorDate.toIso8601String().substring(0, 7); // YYYY-MM
             
             final existing = await txn.query('asset_depreciation_logs', 
               where: 'asset_id = ? AND date LIKE ?', 
               whereArgs: [assetId, '$periodStr%']);

             if (existing.isEmpty) {
               final String? costCenterId = asset['cost_center_id']?.toString();
               await _recordDepreciation(txn, assetId, assetName, cursorDate, monthlyDepreciation, costCenterId: costCenterId);
               totalDepreciationAmount += monthlyDepreciation;
               entriesCreated++;
               assetUpdated = true;
             }

             cursorDate = DateTime(cursorDate.year, cursorDate.month + 1, 1);
          }
          
          if (assetUpdated) {
            assetsProcessed++;
            // Update last depreciation date to the end of last processed month
            DateTime lastProcessed = DateTime(now.year, now.month, 1);
            await txn.update('assets', 
              {'last_depreciation_date': lastProcessed.toIso8601String().split('T')[0]},
              where: 'id = ?',
              whereArgs: [assetId]);
          }
        } catch (e) {
          debugPrint("Error processing asset: $e");
          continue;
        }
      }
    });

    return {
      'assets_processed': assetsProcessed,
      'total_amount': totalDepreciationAmount,
      'entries_created': entriesCreated,
      'date': todayStr,
    };
  }

  Future<void> _recordDepreciation(Transaction txn, String assetId, String assetName, DateTime date, double amount, {String? costCenterId}) async {
    final String dateStr = date.toIso8601String().split('T')[0];
    final String logId = 'DEPLOG_${assetId}_${DateTime.now().microsecondsSinceEpoch}';
    final String entryId = 'JRN_DEP_${assetId}_${date.millisecondsSinceEpoch}';

    await txn.insert('asset_depreciation_logs', {
      'id': logId,
      'asset_id': assetId,
      'date': dateStr,
      'amount': amount,
      'entry_id': entryId,
    });

    await txn.insert('journal_entries', {
      'id': entryId,
      'date': dateStr,
      'description': 'إهلاك شهري - أصل: $assetName ($assetId)',
      'reference_id': assetId,
    });

    await txn.insert('journal_entry_lines', {
      'id': '${entryId}_L1',
      'entry_id': entryId,
      'account_id': 'ACC_DEPRECIATION_EXPENSE',
      'debit': amount,
      'credit': 0.0,
      'cost_center_id': costCenterId,
    });

    await txn.insert('journal_entry_lines', {
      'id': '${entryId}_L2',
      'entry_id': entryId,
      'account_id': 'ACC_ACCUMULATED_DEPRECIATION',
      'debit': 0.0,
      'credit': amount,
      'cost_center_id': costCenterId,
    });

    await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, 'ACC_DEPRECIATION_EXPENSE']);
    await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, 'ACC_ACCUMULATED_DEPRECIATION']);
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }

  bool _isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}
