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

    final assets = await db.query('assets', where: 'status != ?', whereArgs: ['scrap']);

    await db.transaction((txn) async {
      for (var asset in assets) {
        final String assetId = asset['id'] as String;
        final String assetName = asset['name'] as String;
        final double cost = (asset['cost_price'] as num?)?.toDouble() ?? 0.0;
        final double salvage = (asset['salvage_value'] as num?)?.toDouble() ?? 0.0;
        final int usefulLifeMonths = (asset['useful_life_months'] as int?) ?? 60;
        final String purchaseDateStr = asset['purchase_date'] as String;
        final String? lastDepDateStr = asset['last_depreciation_date'] as String?;

        if (cost <= salvage || usefulLifeMonths <= 0) continue;

        final double monthlyDepreciation = (cost - salvage) / usefulLifeMonths;
        
        // Determine starting point for catch-up
        DateTime startDate = DateTime.parse(lastDepDateStr ?? purchaseDateStr);
        // Start from next month if last_dep_date exists
        if (lastDepDateStr != null) {
          startDate = DateTime(startDate.year, startDate.month + 1, 1);
        }

        // Target: Current month start
        DateTime targetDate = DateTime(now.year, now.month, 1);

        int monthsToProcess = 0;
        DateTime cursorDate = startDate;
        
        while (cursorDate.isBefore(targetDate) || _isSameMonth(cursorDate, targetDate)) {
           // Verify if we already reached total life
           // Calculation of total months elapsed since purchase
           final DateTime purchaseDate = DateTime.parse(purchaseDateStr);
           int totalMonthsElapsed = _monthsBetween(purchaseDate, cursorDate) + 1;
           
           if (totalMonthsElapsed > usefulLifeMonths) break;

           final String periodStr = cursorDate.toIso8601String().substring(0, 7); // YYYY-MM
           
           // Check if already logged for this period to prevent duplicates
           final existing = await txn.query('asset_depreciation_logs', 
             where: 'asset_id = ? AND date LIKE ?', 
             whereArgs: [assetId, '$periodStr%']);

           if (existing.isEmpty) {
             final String? costCenterId = asset['cost_center_id'] as String?;
             await _recordDepreciation(txn, assetId, assetName, cursorDate, monthlyDepreciation, costCenterId: costCenterId);
             monthsToProcess++;
             totalDepreciationAmount += monthlyDepreciation;
             assetsProcessed++;
           }

           // Update last_depreciation_date
           await txn.update('assets', 
             {'last_depreciation_date': cursorDate.toIso8601String().split('T')[0]},
             where: 'id = ?',
             whereArgs: [assetId]);

           cursorDate = DateTime(cursorDate.year, cursorDate.month + 1, 1);
        }
        
        if (monthsToProcess > 0) {
           entriesCreated += monthsToProcess;
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

    // 1. Insert Log
    await txn.insert('asset_depreciation_logs', {
      'id': logId,
      'asset_id': assetId,
      'date': dateStr,
      'amount': amount,
      'entry_id': entryId,
    });

    // 2. Create Journal Entry
    await txn.insert('journal_entries', {
      'id': entryId,
      'date': dateStr,
      'description': 'إهلاك شهري - أصل: $assetName ($assetId)',
      'reference_id': assetId,
    });

    // 3. Insert Journal Lines (Debit Expense / Credit Contra-Asset)
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

    // 4. Update Global Account Balances
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
