import 'package:flutter_test/flutter_test.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:hisabati_app/services/depreciation_service.dart';
import 'package:hisabati_app/services/asset_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('v26: Smart Asset Management Final Verification', () {
    final dbHelper = DatabaseHelper();
    final depService = DepreciationService();
    final assetService = AssetService();

    test('Full Asset Lifecycle: Registration -> Depreciation -> Maintenance -> Disposal', () async {
      final db = await openDatabase('test_v26.db');
      dbHelper.setTestDatabase(db);

      await db.execute('DROP TABLE IF EXISTS assets');
      await db.execute('DROP TABLE IF EXISTS journal_entry_lines');
      await db.execute('DROP TABLE IF EXISTS journal_entries');
      await db.execute('DROP TABLE IF EXISTS asset_depreciation_logs');
      await db.execute('DROP TABLE IF EXISTS maintenance_schedules');
      await db.execute('DROP TABLE IF EXISTS purchase_invoices');
      await db.execute('DROP TABLE IF EXISTS purchase_invoice_lines');
      await db.execute('DROP TABLE IF EXISTS accounts');

      await db.execute('CREATE TABLE assets (id TEXT PRIMARY KEY, name TEXT, cost_price REAL, status TEXT, purchase_date TEXT, cost_center_id TEXT, purchase_invoice_id TEXT, useful_life_months INTEGER DEFAULT 60, last_depreciation_date TEXT)');
      await db.execute('CREATE TABLE journal_entries (id TEXT PRIMARY KEY, date TEXT, description TEXT, reference_id TEXT, attachment_path TEXT)');
      await db.execute('CREATE TABLE journal_entry_lines (id TEXT PRIMARY KEY, entry_id TEXT, account_id TEXT, debit REAL, credit REAL, cost_center_id TEXT)');
      await db.execute('CREATE TABLE asset_depreciation_logs (id TEXT PRIMARY KEY, asset_id TEXT, date TEXT, amount REAL, entry_id TEXT)');
      await db.execute('CREATE TABLE maintenance_schedules (id TEXT PRIMARY KEY, asset_id TEXT, scheduled_date TEXT, reason TEXT, status TEXT, total_cost REAL, linked_invoice_id TEXT)');
      await db.execute('CREATE TABLE purchase_invoices (id TEXT PRIMARY KEY, issue_date TEXT, supplier_id TEXT, subtotal REAL, tax_amount REAL, total REAL, payment_type TEXT, attachment_path TEXT, project_id TEXT, cost_center_id TEXT)');
      await db.execute('CREATE TABLE purchase_invoice_lines (id TEXT PRIMARY KEY, invoice_id TEXT, item_id TEXT, name TEXT, quantity REAL, price_at_purchase REAL)');
      await db.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY, balance REAL DEFAULT 0)');

      // 2. Register Asset
      await db.insert('assets', {
        'id': 'AST_TEST_1',
        'name': 'Test Crane',
        'cost_price': 100000.0,
        'status': 'available',
        'purchase_date': '2026-01-01',
        'cost_center_id': 'CC_OPS'
      });

      // 3. Run Depreciation (Manual call)
      // Mocking 1 month (1/60 of 100k)
      await depService.processAllDepreciations();
      
      final depLines = await db.query('journal_entry_lines', where: 'account_id = ?', whereArgs: ['ACC_DEPRECIATION_EXPENSE']);
      expect(depLines.isNotEmpty, true);
      expect(depLines.first['cost_center_id'], equals('CC_OPS'), reason: "Depreciation must be attributed to Asset CC");

      // 4. Record Maintenance via Purchase Invoice
      await dbHelper.savePurchaseInvoice(
        supplierId: 'SUPP_1',
        total: 5000.0,
        paymentType: 'cash',
        lines: [],
        costCenterId: 'CC_OPS',
        assetId: 'AST_TEST_1',
        isMaintenance: true
      );

      final tco = await assetService.getAssetTCO('AST_TEST_1');
      print("📊 TCO for Asset: $tco");
      expect(tco['maintenance'], equals(5000.0));

      // 5. Dispose Asset (Scrap)
      await assetService.disposeAsset(assetId: 'AST_TEST_1', reason: 'Broken', proceeds: 2000.0);
      
      final asset = await db.query('assets', where: 'id = ?', whereArgs: ['AST_TEST_1']);
      expect(asset.first['status'], equals('scrap'));
      
      final disposalEntries = await db.query('journal_entries', where: 'reference_id = ?', whereArgs: ['AST_TEST_1']);
      expect(disposalEntries.isNotEmpty, true);
      print("✅ Final Disposal Entry: ${disposalEntries.last['description']}");
      
      print("✨ v26 Verification Completed Successfully!");
    });
  });
}
