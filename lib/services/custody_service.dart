import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class CustodyService {
  final DatabaseHelper _db = DatabaseHelper();

  static const String FIN_PENDING = '?????';
  static const String FIN_CLEARED = '?????';
  static const String ASSET_WITH_EMP = '????? ??????';
  static const String ASSET_RETURNED = '??????';

  // ---------------------------------------------------------
  // 1. FINANCIAL CUSTODY (????? ???????)
  // ---------------------------------------------------------

  Future<void> issueFinancialCustody({
    required String employeeId,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();
    final custodyId = 'FC_${DateTime.now().millisecondsSinceEpoch}';

    // Create custody record
    await db.insert('financial_custodies', {
      'id': custodyId,
      'employee_id': employeeId,
      'amount': amount,
      'issue_date': nowStr,
      'reason': reason,
      'status': FIN_PENDING,
      'cleared_amount': 0,
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': await _db.getDeviceFingerprint(),
      'is_deleted': 0,
    });

    // Journal entry
    await _db.saveManualJournalEntry(
      date: nowStr.split('T')[0],
      description: '??? ???? ????? - $reason',
      lines: [
        {'account_id': 'ACC_EMP_RECEIVABLE', 'debit': amount, 'credit': 0.0},
        {'account_id': 'ACC_CASH', 'debit': 0.0, 'credit': amount},
      ],
    );
  }

  Future<void> clearFinancialCustody({
    required String id,
    String? clearanceNotes,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();

    final res = await db.query('financial_custodies', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty || res.first['status'] == FIN_CLEARED) return;

    final double amount = (res.first['amount'] as num).toDouble();

    await db.update('financial_custodies', {
      'status': FIN_CLEARED,
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [id]);

    await _db.saveManualJournalEntry(
      date: nowStr.split('T')[0],
      description: '????? ???? ?????',
      lines: [
        {'account_id': 'ACC_EXPENSES_GENERAL', 'debit': amount, 'credit': 0.0},
        {'account_id': 'ACC_EMP_RECEIVABLE', 'debit': 0.0, 'credit': amount},
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getFinancialCustodies({String? status, String? employeeId}) async {
    final db = await _db.database;
    String where = '';
    List<dynamic> args = [];
    
    if (status != null) {
      where = 'status = ?';
      args.add(status);
    }
    
    if (employeeId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'employee_id = ?';
      args.add(employeeId);
    }

    if (where.isEmpty) {
      return await db.query('financial_custodies', orderBy: 'issue_date DESC');
    }
    return await db.query('financial_custodies', where: where, whereArgs: args, orderBy: 'issue_date DESC');
  }

  // ---------------------------------------------------------
  // 2. ASSET CUSTODY (????? ???????)
  // ---------------------------------------------------------

  Future<void> issueAssetCustody({
    required String assetId,
    required String employeeId,
    required String conditionOnIssue,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.update('assets', {
      'status': '???? ?????',
      'assigned_to': employeeId,
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [assetId]);

    await db.insert('asset_custody_logs', {
      'id': 'ACL_${DateTime.now().millisecondsSinceEpoch}',
      'asset_id': assetId,
      'employee_id': employeeId,
      'issued_date': nowStr,
      'status': 'active',
      'notes': conditionOnIssue,
    });
  }

  Future<void> returnAssetCustody({
    required String assetId,
    required String conditionOnReturn,
    bool isDamaged = false,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.update('assets', {
      'status': isDamaged ? '????? ?????' : '?? ??????',
      'assigned_to': null,
      'location': 'Warehouse',
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [assetId]);

    await db.update('asset_custody_logs', {
      'returned_date': nowStr,
      'status': 'returned',
      'notes': conditionOnReturn,
    }, where: "asset_id = ? AND status = 'active'", whereArgs: [assetId]);
  }

  Future<List<Map<String, dynamic>>> getAssetCustodies({String? employeeId}) async {
    final db = await _db.database;
    String whereClause = "a.status = '???? ?????'";
    List<dynamic> args = [];
    
    if (employeeId != null) {
      whereClause += " AND a.assigned_to = ?";
      args.add(employeeId);
    }

    return await db.rawQuery('''
      SELECT a.*, e.name as employee_name
      FROM assets a
      LEFT JOIN employees e ON a.assigned_to = e.id
      WHERE $whereClause
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getAvailableAssets() async {
    final db = await _db.database;
    return await db.query('assets', where: "status IN ('?? ??????', '????', 'available')");
  }
}

