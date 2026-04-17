import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AssetService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Calculates Total Cost of Ownership (TCO) for a specific asset.
  /// TCO = Purchase Price + All Maintenance Costs - Accumulated Depreciation
  Future<Map<String, double>> getAssetTCO(String assetId) async {
    final db = await _dbHelper.database;

    // 1. Get Asset Purchase Price
    final asset = await db.query('assets', where: 'id = ?', whereArgs: [assetId]);
    if (asset.isEmpty) return {'purchase_price': 0, 'maintenance': 0, 'depreciation': 0, 'nbv': 0};
    
    double purchasePrice = (asset.first['cost_price'] as num?)?.toDouble() ?? 0.0;

    // 2. Get Maintenance Costs
    final maintenanceRes = await db.rawQuery(
      'SELECT SUM(total_cost) as total FROM maintenance_schedules WHERE asset_id = ?',
      [assetId]
    );
    double totalMaintenance = (maintenanceRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Get Accumulated Depreciation
    final depRes = await db.rawQuery(
      'SELECT SUM(amount) as total FROM asset_depreciation_logs WHERE asset_id = ?',
      [assetId]
    );
    double accDepreciation = (depRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Net Book Value (NBV)
    double nbv = purchasePrice - accDepreciation;

    return {
      'purchase_price': purchasePrice,
      'maintenance': totalMaintenance,
      'depreciation': accDepreciation,
      'nbv': nbv,
    };
  }

  /// Processes Asset Disposal (Scrap/Sale).
  /// Generates accounting entries to close the asset account and record gain/loss.
  Future<void> disposeAsset({
    required String assetId,
    required String reason,
    required double proceeds, // Amount received if sold (0 if scrapped)
  }) async {
    final db = await _dbHelper.database;
    final stats = await getAssetTCO(assetId);
    final asset = await db.query('assets', where: 'id = ?', whereArgs: [assetId]);
    final String assetName = asset.first['name'] as String;
    final String? costCenterId = asset.first['cost_center_id'] as String?;

    double nbv = stats['nbv']!;
    double gainLoss = proceeds - nbv;

    await db.transaction((txn) async {
      final String entryId = 'JRN_DISP_${assetId}_${DateTime.now().millisecondsSinceEpoch}';
      final String dateStr = DateTime.now().toIso8601String().split('T')[0];

      // 1. Create Journal Entry
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': dateStr,
        'description': 'تخلص من أصل ($reason): $assetName ($assetId)',
        'reference_id': assetId,
      });

      // 2. Close Accumulated Depreciation (Debit)
      await txn.insert('journal_entry_lines', {
        'id': '${entryId}_L1',
        'entry_id': entryId,
        'account_id': 'ACC_ACCUMULATED_DEPRECIATION',
        'debit': stats['depreciation']!,
        'credit': 0.0,
        'cost_center_id': costCenterId,
      });

      // 3. Record Proceeds/Cash (Debit)
      if (proceeds > 0) {
        await txn.insert('journal_entry_lines', {
          'id': '${entryId}_L2',
          'entry_id': entryId,
          'account_id': 'ACC_BANK_1',
          'debit': proceeds,
          'credit': 0.0,
          'cost_center_id': costCenterId,
        });
      }

      // 4. Close Asset Cost (Credit)
      // Note: We need a mapping from asset type to specific asset account, 
      // but for now we assume assets are in a general Fixed Assets account or we use the contra-asset logic.
      // Usually: Dr Cash, Dr AccDep, Cr Asset Cost. 
      // Gain/Loss goes to P&L.
      await txn.insert('journal_entry_lines', {
        'id': '${entryId}_L3',
        'entry_id': entryId,
        'account_id': 'ACC_INVENTORY', // Placeholder for Fixed Asset account if not unique
        'debit': 0.0,
        'credit': stats['purchase_price']!,
        'cost_center_id': costCenterId,
      });

      // 5. Record Gain or Loss
      if (gainLoss != 0) {
        await txn.insert('journal_entry_lines', {
          'id': '${entryId}_L4',
          'entry_id': entryId,
          'account_id': gainLoss > 0 ? 'ACC_REVENUE_OTHER' : 'ACC_LOSS_ASSETS',
          'debit': gainLoss < 0 ? gainLoss.abs() : 0.0,
          'credit': gainLoss > 0 ? gainLoss : 0.0,
          'cost_center_id': costCenterId,
        });
      }

      // 6. Update Asset Status to 'scrap'
      await txn.update('assets', 
        {'status': 'scrap'},
        where: 'id = ?',
        whereArgs: [assetId]
      );
    });
  }

  /// Creates a new asset/vehicle in the database.
  Future<void> createAsset(Map<String, dynamic> assetData) async {
    final db = await _dbHelper.database;
    final String nowStr = DateTime.now().toIso8601String();
    final deviceId = await _dbHelper.getDeviceFingerprint();

    final Map<String, dynamic> data = Map<String, dynamic>.from(assetData);
    data['id'] ??= 'ASSET_${DateTime.now().millisecondsSinceEpoch}';
    data['sync_status'] = 0;
    data['updated_at'] = nowStr;
    data['device_id'] = deviceId;
    data['is_deleted'] = 0;
    data['status'] ??= 'available';

    await db.insert('assets', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
