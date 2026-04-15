import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';

class ManufacturingService {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();

  /// Creates a new production order in Draft status
  Future<void> createOrder(String bomId, double qty) async {
    final db = await _db.database;
    await db.insert('manufacturing_orders', {
      'id': 'MO_${DateTime.now().millisecondsSinceEpoch}',
      'bom_id': bomId,
      'qty_to_produce': qty,
      'status': 'draft',
      'start_date': DateTime.now().toIso8601String(),
    });
  }

  /// Completes a manufacturing order
  Future<Map<String, dynamic>> completeManufacturingOrder(String orderId) async {
    final db = await _db.database;
    final orderRes = await db.query('manufacturing_orders', where: 'id = ?', whereArgs: [orderId]);
    if (orderRes.isEmpty) throw Exception("Order not found");

    final order = orderRes.first;
    if (order['status'] == 'completed') throw Exception("Order already completed");

    final String bomId = order['bom_id'] as String;
    final double qty = (order['qty_to_produce'] as num).toDouble();

    final success = await _engine.processManufacturing(
      bomId: bomId,
      qtyToProduce: qty,
    );

    if (!success) throw Exception("Failed to process manufacturing transaction.");

    // Delete draft since the engine creates a completed record
    await db.delete('manufacturing_orders', where: 'id = ?', whereArgs: [orderId]);

    return {
      'success': true,
      'cost_per_unit': ((order['total_cost'] as num?)?.toDouble() ?? 0) / qty,
    };
  }

  Future<List<Map<String, dynamic>>> getBOMs() async {
    return await _db.getBOMs();
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    return await _db.getManufacturingOrders();
  }
}
