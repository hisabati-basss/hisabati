import '../services/database_helper.dart';

class ManufacturingService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Creates a new production order in Draft status
  Future<void> createOrder(String bomId, double qty) async {
    final db = await _db.database;
    await db.insert('manufacturing_orders', {
      'id': 'MO_${DateTime.now().millisecondsSinceEpoch}',
      'bom_id': bomId,
      'qty_to_produce': qty,
      'status': 'planned',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Checks if raw materials are available for a given BOM and quantity
  Future<List<Map<String, dynamic>>> checkMaterialAvailability(String bomId, double qtyToProduce) async {
    final lines = await _db.getBOMLines(bomId);
    List<Map<String, dynamic>> availability = [];

    for (var line in lines) {
      final double required = (line['quantity_required'] as num).toDouble() * qtyToProduce * (1 + ((line['waste_percentage'] as num?)?.toDouble() ?? 0) / 100);
      final double available = (line['available_qty'] as num?)?.toDouble() ?? 0;
      
      availability.add({
        'item_name': line['material_name'],
        'required': required,
        'available': available,
        'is_sufficient': available >= required,
        'shortage': available < required ? (required - available) : 0,
      });
    }
    return availability;
  }

  /// Starts production (Deducts raw materials, moves to WIP)
  Future<void> startOrder(String orderId) async {
    await _db.startManufacturingOrder(orderId: orderId);
  }

  /// Completes production (Adds finished goods, finalizes costs)
  Future<Map<String, dynamic>> finalizeOrder(String orderId, double actualQty, double actualOverhead) async {
    return await _db.finishManufacturingOrder(
      orderId: orderId, 
      actualQty: actualQty, 
      actualOverhead: actualOverhead
    );
  }

  Future<List<Map<String, dynamic>>> getBOMs() async {
    return await _db.getBOMs();
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    return await _db.getManufacturingOrders();
  }

  /// Retrieves analytics for the manufacturing dashboard
  Future<Map<String, dynamic>> getStats() async {
    final orders = await getOrders();
    final completed = orders.where((o) => o['status'] == 'completed').toList();
    
    double totalValue = 0;
    double totalOverhead = 0;
    
    for (var o in completed) {
      totalValue += (o['total_cost'] as num?)?.toDouble() ?? 0;
      totalOverhead += (o['actual_overhead_cost'] as num?)?.toDouble() ?? 0;
    }

    // Top Items logic
    Map<String, double> itemVolume = {};
    for (var o in completed) {
      String name = o['bom_name'] ?? 'Unknown';
      double qty = (o['actual_qty_produced'] as num?)?.toDouble() ?? 0;
      itemVolume[name] = (itemVolume[name] ?? 0) + qty;
    }

    final topItems = itemVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_completed': completed.length,
      'total_in_progress': orders.where((o) => o['status'] == 'in_progress').length,
      'total_planned': orders.where((o) => o['status'] == 'planned').length,
      'total_production_value': totalValue,
      'total_overhead': totalOverhead,
      'top_items': topItems.take(5).map((e) => {'name': e.key, 'value': e.value}).toList(),
      'efficiency': completed.isEmpty ? 100 : 95.5, // Placeholder for now
    };
  }

  /// Approves or fails quality control for a completed order
  Future<void> submitQC(String orderId, String status, String notes) async {
    final db = await _db.database;
    await db.update('manufacturing_orders', {
      'qc_status': status,
      'qc_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [orderId]);
  }
}
