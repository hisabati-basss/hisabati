import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class CustodyService {
  final DatabaseHelper _db = DatabaseHelper();

  static const String FIN_PENDING = 'معلقة';
  static const String FIN_CLEARED = 'مصفاة';
  static const String ASSET_WITH_EMP = 'بحوزة الموظف';
  static const String ASSET_RETURNED = 'مسترجع';

  // ---------------------------------------------------------
  // 1. FINANCIAL CUSTODY (العهد المالية)
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

    // Journal entry: Debit Employee Receivable (Custody Account), Credit Cash
    await _db.saveManualJournalEntry(
      {
        'date': nowStr.split('T')[0],
        'description': 'صرف عهدة مالية - $reason',
      },
      [
        {'account_id': 'ACC_EMP_RECEIVABLE', 'debit': amount, 'credit': 0.0},
        {'account_id': 'ACC_CASH', 'debit': 0.0, 'credit': amount},
      ],
    );
  }

  Future<void> clearFinancialCustody({
    required String id,
    required double clearanceAmount,
    String? costCenterId,
    String? clearanceNotes,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();

    final res = await db.query('financial_custodies', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty || res.first['status'] == FIN_CLEARED) return;

    final double originalAmount = (res.first['amount'] as num).toDouble();
    final String employeeId = res.first['employee_id'] as String;

    await db.update('financial_custodies', {
      'status': clearanceAmount >= originalAmount ? FIN_CLEARED : FIN_PENDING,
      'cleared_amount': (res.first['cleared_amount'] as num).toDouble() + clearanceAmount,
      'clearance_date': nowStr,
      'notes': clearanceNotes,
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [id]);

    // Journal Entry: Debit Expense, Credit Employee Receivable
    // If there's a cost center, link it
    await _db.saveManualJournalEntry(
      {
        'date': nowStr.split('T')[0],
        'description': 'تصفية عهدة مالية - $clearanceNotes',
      },
      [
        {
          'account_id': 'ACC_EXPENSES_GENERAL', 
          'debit': clearanceAmount, 
          'credit': 0.0,
          'cost_center_id': costCenterId
        },
        {
          'account_id': 'ACC_EMP_RECEIVABLE', 
          'debit': 0.0, 
          'credit': clearanceAmount,
          'cost_center_id': costCenterId
        },
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getFinancialCustodies({String? status, String? employeeId}) async {
    final db = await _db.database;
    String where = 'is_deleted = 0';
    List<dynamic> args = [];
    
    if (status != null) {
      where += ' AND status = ?';
      args.add(status);
    }
    
    if (employeeId != null) {
      where += ' AND employee_id = ?';
      args.add(employeeId);
    }

    return await db.query('financial_custodies', where: where, whereArgs: args, orderBy: 'issue_date DESC');
  }

  // ---------------------------------------------------------
  // 2. ASSET CUSTODY (العهد العينية)
  // ---------------------------------------------------------

  Future<void> issueAssetCustody({
    required String assetId,
    required String employeeId,
    required String conditionOnIssue,
  }) async {
    final db = await _db.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.update('assets', {
      'status': ASSET_WITH_EMP,
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
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': await _db.getDeviceFingerprint(),
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
      'status': isDamaged ? 'تحتاج صيانة' : 'في المستودع',
      'assigned_to': null,
      'location': 'Warehouse',
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [assetId]);

    await db.update('asset_custody_logs', {
      'returned_date': nowStr,
      'status': 'returned',
      'notes': conditionOnReturn,
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: "asset_id = ? AND status = 'active'", whereArgs: [assetId]);
  }

  Future<List<Map<String, dynamic>>> getAssetCustodies({String? employeeId}) async {
    final db = await _db.database;
    String whereClause = "a.is_deleted = 0 AND a.status = ?";
    List<dynamic> args = [ASSET_WITH_EMP];
    
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
    return await db.query('assets', where: "status IN ('في المستودع', 'جاهز', 'available') AND is_deleted = 0");
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final db = await _db.database;
    return await db.query('employees', where: 'is_deleted = 0', orderBy: 'name ASC');
  }
}


