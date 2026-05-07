import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'sync_service.dart';

class ChequeService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // Status definitions
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_CLEARED = 'cleared';
  static const String STATUS_BOUNCED = 'bounced';

  // Type definitions
  static const String TYPE_RECEIVABLE = 'receivable'; // Got from client
  static const String TYPE_PAYABLE = 'payable'; // Gave to supplier

  /// Adds a new cheque and automatically generates the Journal Entry.
  Future<String> addCheque({
    required String chequeNumber,
    required String bankName,
    required double amount,
    required DateTime issueDate,
    required DateTime dueDate,
    required String type, // TYPE_RECEIVABLE or TYPE_PAYABLE
    required String partnerId,
    required String partnerName,
    required String partnerType,
    String notes = '',
  }) async {
    final db = await _dbHelper.database;
    final String chequeId = 'CHQ_${DateTime.now().millisecondsSinceEpoch}';
    final String entryId = 'JRN_${DateTime.now().millisecondsSinceEpoch}_CHQ';
    final String nowStr = DateTime.now().toIso8601String();
    final deviceId = await _dbHelper.getDeviceFingerprint();

    // 1. Create Initial Journal Entry
    await db.insert('journal_entries', {
      'id': entryId,
      'date': issueDate.toIso8601String(),
      'description': 'شيك \${type == TYPE_RECEIVABLE ? "وارد" : "صادر"} رقم \$chequeNumber - \$partnerName',
      'reference_id': chequeId,
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': deviceId,
    });

    // 2. Insert Journal Lines (Double-Entry)
    if (type == TYPE_RECEIVABLE) {
      await db.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': 'ACC_CHEQUES_RECEIVABLE',
        'debit': amount,
        'credit': 0,
      });
      await db.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': 'ACC_RECEIVABLE',
        'debit': 0,
        'credit': amount,
      });
    } else {
      await db.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': 'ACC_PAYABLE',
        'debit': amount,
        'credit': 0,
      });
      await db.insert('journal_entry_lines', {
        'id': _uuid.v4(),
        'entry_id': entryId,
        'account_id': 'ACC_CHEQUES_PAYABLE',
        'debit': 0,
        'credit': amount,
      });
    }

    // 3. Save the Cheque Record
    await db.insert('cheques', {
      'id': chequeId,
      'cheque_number': chequeNumber,
      'bank_name': bankName,
      'amount': amount,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'type': type,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_type': partnerType,
      'status': STATUS_PENDING,
      'journal_entry_id': entryId,
      'notes': notes,
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': deviceId,
    });

    // Update partner balance
    try {
      if (partnerType == 'client') {
         await db.rawUpdate('UPDATE clients SET balance = balance - ? WHERE id = ?', [amount, partnerId]);
      } else if (partnerType == 'supplier') {
         await db.rawUpdate('UPDATE suppliers SET balance = balance - ? WHERE id = ?', [amount, partnerId]);
      }
    } catch (_) {}

    // Sync on Save
    SyncService().performFullSync();
    
    return chequeId;
  }

  /// Mark a cheque as cleared and create the bank impact journal entry.
  Future<void> clearCheque(String chequeId) async {
     final db = await _dbHelper.database;
     
     // 1. Get cheque details
     final List<Map<String, dynamic>> res = await db.query('cheques', where: 'id = ?', whereArgs: [chequeId]);
     if (res.isEmpty) return;
     
     final cheque = res.first;
     if (cheque['status'] == STATUS_CLEARED) return; 
     
     final double amount = (cheque['amount'] as num).toDouble();
     final String type = cheque['type'] as String;
     final String chequeNum = cheque['cheque_number'] as String;
     final String partnerName = cheque['partner_name'] as String;
     
     // 2. Create Clearing Journal Entry
     final String entryId = 'JRN_${DateTime.now().millisecondsSinceEpoch}_CLR';
     final String nowStr = DateTime.now().toIso8601String();
     final deviceId = await _dbHelper.getDeviceFingerprint();

     await db.insert('journal_entries', {
       'id': entryId,
       'date': nowStr,
       'description': 'تحصيل شيك \${type == TYPE_RECEIVABLE ? "وارد" : "صادر"} رقم \$chequeNum - \$partnerName',
       'reference_id': chequeId,
       'sync_status': 0,
       'updated_at': nowStr,
       'device_id': deviceId,
     });
     
     // Double Entry for Clearing
     if (type == TYPE_RECEIVABLE) {
        // Debit Bank, Credit Cheques Receivable
        await db.insert('journal_entry_lines', {'id': _uuid.v4(), 'entry_id': entryId, 'account_id': 'ACC_BANK', 'debit': amount, 'credit': 0});
        await db.insert('journal_entry_lines', {'id': _uuid.v4(), 'entry_id': entryId, 'account_id': 'ACC_CHEQUES_RECEIVABLE', 'debit': 0, 'credit': amount});
     } else {
        // Debit Cheques Payable, Credit Bank
        await db.insert('journal_entry_lines', {'id': _uuid.v4(), 'entry_id': entryId, 'account_id': 'ACC_CHEQUES_PAYABLE', 'debit': amount, 'credit': 0});
        await db.insert('journal_entry_lines', {'id': _uuid.v4(), 'entry_id': entryId, 'account_id': 'ACC_BANK', 'debit': 0, 'credit': amount});
     }

     // 3. Update Status
     await db.update('cheques', {
       'status': STATUS_CLEARED,
       'sync_status': 0,
       'updated_at': nowStr,
       'device_id': deviceId,
     }, where: 'id = ?', whereArgs: [chequeId]);

     // Sync on Save
     SyncService().performFullSync();
  }

  Future<void> bounceCheque(String chequeId) async {
     final db = await _dbHelper.database;
     
     final List<Map<String, dynamic>> res = await db.query('cheques', where: 'id = ?', whereArgs: [chequeId]);
     if (res.isEmpty) return;
     
     final cheque = res.first;
     final String nowStr = DateTime.now().toIso8601String();
     final deviceId = await _dbHelper.getDeviceFingerprint();

     await db.update('cheques', {
       'status': STATUS_BOUNCED,
       'sync_status': 0,
       'updated_at': nowStr,
       'device_id': deviceId,
     }, where: 'id = ?', whereArgs: [chequeId]);

     // Sync on Save
     SyncService().performFullSync();

     // Restore partner balance
     final double amount = (cheque['amount'] as num).toDouble();
     final String partnerId = cheque['partner_id'] as String;
     final String partnerType = cheque['partner_type'] as String;

     try {
       if (partnerType == 'client') {
         await db.rawUpdate('UPDATE clients SET balance = balance + ? WHERE id = ?', [amount, partnerId]);
       } else if (partnerType == 'supplier') {
         await db.rawUpdate('UPDATE suppliers SET balance = balance + ? WHERE id = ?', [amount, partnerId]);
       }
     } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAllCheques() async {
    final db = await _dbHelper.database;
    return await db.query('cheques', where: 'is_deleted = 0', orderBy: 'due_date ASC');
  }

  Future<Map<String, double>> getChequeStats() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = ? AND status = ? THEN amount ELSE 0 END) as receivable_pending,
        SUM(CASE WHEN type = ? AND status = ? THEN amount ELSE 0 END) as payable_pending,
        SUM(CASE WHEN status = ? THEN amount ELSE 0 END) as bounced_total,
        SUM(CASE WHEN status = ? THEN amount ELSE 0 END) as cleared_total
      FROM cheques
      WHERE is_deleted = 0
    ''', [TYPE_RECEIVABLE, STATUS_PENDING, TYPE_PAYABLE, STATUS_PENDING, STATUS_BOUNCED, STATUS_CLEARED]);

    if (res.isEmpty) return {'receivable_pending': 0, 'payable_pending': 0, 'bounced_total': 0, 'cleared_total': 0};
    
    return {
      'receivable_pending': (res.first['receivable_pending'] as num?)?.toDouble() ?? 0.0,
      'payable_pending': (res.first['payable_pending'] as num?)?.toDouble() ?? 0.0,
      'bounced_total': (res.first['bounced_total'] as num?)?.toDouble() ?? 0.0,
      'cleared_total': (res.first['cleared_total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Generates a report of cheques due within a specific period.
  Future<List<Map<String, dynamic>>> getChequesReport(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    return await db.query(
      'cheques',
      where: 'due_date BETWEEN ? AND ? AND is_deleted = 0',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'due_date ASC'
    );
  }
}


