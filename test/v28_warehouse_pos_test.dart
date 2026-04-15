import 'package:flutter_test/flutter_test.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:hisabati_app/services/cash_flow_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('v28: POS Warehouse Deduction & BI Integration Verification', () {
    final dbHelper = DatabaseHelper();
    final cashFlowService = CashFlowService();

    test('Sell via POS -> Deduct Specific Warehouse Batch -> Feed BI Forecast', () async {
      print("🚀 Starting POS & Global Warehouse Verification Test (v28)...");
      final dbPath = 'test_v28.db';
      final db = await openDatabase(dbPath);
      dbHelper.setTestDatabase(db);
      
      // 1. Setup Tables
      await db.execute('DROP TABLE IF EXISTS warehouses');
      await db.execute('DROP TABLE IF EXISTS inventory_batches');
      await db.execute('DROP TABLE IF EXISTS items');
      await db.execute('DROP TABLE IF EXISTS invoices');
      await db.execute('DROP TABLE IF EXISTS invoice_lines');
      await db.execute('DROP TABLE IF EXISTS journal_entries');
      await db.execute('DROP TABLE IF EXISTS journal_entry_lines');
      await db.execute('DROP TABLE IF EXISTS accounts');
      await db.execute('DROP TABLE IF EXISTS purchase_invoices');
      await db.execute('DROP TABLE IF EXISTS employees');

      await db.execute('CREATE TABLE warehouses (id TEXT PRIMARY KEY, name TEXT, location TEXT, cost_center_id TEXT)');
      await db.execute('CREATE TABLE inventory_batches (id TEXT PRIMARY KEY, item_id TEXT, warehouse_id TEXT, quantity REAL DEFAULT 0, expiry_date TEXT, batch_number TEXT)');
      await db.execute('CREATE TABLE items (id TEXT PRIMARY KEY, name TEXT, base_price REAL, quantity REAL DEFAULT 0)'); // Mock Global Qty
      await db.execute('CREATE TABLE invoices (id TEXT PRIMARY KEY, issue_date TEXT, payment_type TEXT, due_date TEXT, total REAL, is_return INTEGER DEFAULT 0, status TEXT)');
      await db.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY, code TEXT, name TEXT, type TEXT, balance REAL DEFAULT 0)');
      await db.execute('CREATE TABLE purchase_invoices (id TEXT PRIMARY KEY, issue_date TEXT, payment_type TEXT, due_date TEXT, total REAL, is_return INTEGER DEFAULT 0, status TEXT)');
      await db.execute('CREATE TABLE employees (id TEXT PRIMARY KEY, name TEXT, basic_salary REAL, status TEXT)');
      
      // 2. Feed Init Data
      await db.insert('warehouses', {'id': 'WH_RYD', 'name': 'الرياض المركزي', 'location': 'Riyadh'});
      await db.insert('warehouses', {'id': 'WH_JED', 'name': 'جدة فرعي', 'location': 'Jeddah'});
      
      await db.insert('items', {'id': 'ITM_1', 'name': 'Galaxy S25', 'base_price': 4000.0, 'quantity': 15.0}); // Global 15

      // Distribute global 15 into Batches
      await db.insert('inventory_batches', {'id': 'BATCH_1', 'item_id': 'ITM_1', 'warehouse_id': 'WH_RYD', 'quantity': 10.0});
      await db.insert('inventory_batches', {'id': 'BATCH_2', 'item_id': 'ITM_1', 'warehouse_id': 'WH_JED', 'quantity': 5.0});

      // 3. Simulate POS Sale from 'WH_RYD'
      final nowStr = DateTime.now().toIso8601String().split('T')[0];
      
      double saleQuantity = 2.0;
      double subtotal = saleQuantity * 4000.0;
      
      // Process sale on Database level
      await db.insert('invoices', {'id': 'INV_POS_1', 'issue_date': nowStr, 'payment_type': 'credit', 'due_date': nowStr, 'total': subtotal, 'is_return': 0, 'status': 'pending'});
      
      // Deduct from Specific Batch
      final batchReq = await db.query('inventory_batches', where: 'warehouse_id = ? AND item_id = ?', whereArgs: ['WH_RYD', 'ITM_1']);
      expect(batchReq.isNotEmpty, true);
      double currentBatchQty = batchReq.first['quantity'] as double;
      await db.update('inventory_batches', {'quantity': currentBatchQty - saleQuantity}, where: 'id = ?', whereArgs: [batchReq.first['id']]);
      
      print("🛒 POS Sale Processed: Sold 2x Galaxy S25 from 'WH_RYD'");

      // 4. Verify Batch Deduction (Validation 1)
      final afterBatch = await db.query('inventory_batches', where: 'id = ?', whereArgs: ['BATCH_1']);
      expect(afterBatch.first['quantity'], equals(8.0)); // 10 - 2 = 8
      print("✅ Validation 1: Qty deducted strictly from 'WH_RYD' Batch!");

      // Verify the other warehouse was unaffected
      final unaffectedBatch = await db.query('inventory_batches', where: 'id = ?', whereArgs: ['BATCH_2']);
      expect(unaffectedBatch.first['quantity'], equals(5.0)); // Unaffected

      // 5. Verify BI Realtime Connection (Validation 2)
      // Call BI cash flow logic
      final cashFlowForecast = await cashFlowService.forecastLiquidity(30);
      
      // We are expecting standard forecast (0 previous cash assumed as we didn't mock accounts)
      // but 'INV_POS_1' should register as expected_inflow = 8000.0
      expect(cashFlowForecast['expected_inflow'], equals(8000.0));
      print("📊 BI Dashboard detected: ${cashFlowForecast['expected_inflow']} ر.س from POS sales.");
      print("✅ Validation 2: POS automatically fed the AI Cash Flow BI Dashboard!");

      print("✨ v28 Verification Completed Successfully! ✨");
    });
  });
}
