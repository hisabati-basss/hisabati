import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class CommercialService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // --- Targets ---
  Future<List<Map<String, dynamic>>> getTargets() async {
    final db = await _dbHelper.database;
    return await db.query('sales_targets', orderBy: 'start_date DESC');
  }

  Future<void> addTarget(String empId, double amount, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    await db.insert('sales_targets', {
      'id': _uuid.v4(),
      'employee_id': empId,
      'target_amount': amount,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'created_at': DateTime.now().toIso8601String()
    });
  }

  // --- Commissions ---
  Future<List<Map<String, dynamic>>> getCommissions() async {
    final db = await _dbHelper.database;
    return await db.query('commissions', orderBy: 'created_at DESC');
  }

  // --- Promotions ---
  Future<List<Map<String, dynamic>>> getPromotions() async {
    final db = await _dbHelper.database;
    return await db.query('promotional_campaigns', orderBy: 'start_date DESC');
  }

  Future<void> addPromotion(String itemId, String type, double value, DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    await db.insert('promotional_campaigns', {
      'id': _uuid.v4(),
      'item_id': itemId,
      'discount_type': type,
      'discount_value': value,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'created_at': DateTime.now().toIso8601String()
    });
  }

  // --- Slow Moving Stock Analysis ---
  Future<List<Map<String, dynamic>>> getSlowMovingStock() async {
    final db = await _dbHelper.database;
    // Products that haven't been sold in 90 days but still have stock
    return await db.rawQuery('''
      SELECT i.*, 
        COALESCE(
          (SELECT MAX(inv.issue_date) FROM invoice_lines il 
           JOIN invoices inv ON il.invoice_id = inv.id 
           WHERE il.name = i.name), 
          'لم يُباع أبداً'
        ) as last_sold_date
      FROM items i
      WHERE i.quantity > 0
        AND i.id NOT IN (
          SELECT DISTINCT il.name FROM invoice_lines il
          JOIN invoices inv ON il.invoice_id = inv.id
          WHERE inv.issue_date >= date('now', '-90 days')
        )
      ORDER BY i.quantity DESC
    ''');
  }

  /// Toggle a promotional campaign active/inactive
  Future<void> togglePromotion(String promoId, bool isActive) async {
    final db = await _dbHelper.database;
    await db.update('promotional_campaigns', {
      'is_active': isActive ? 1 : 0,
    }, where: 'id = ?', whereArgs: [promoId]);
  }
}
