import 'package:flutter_test/flutter_test.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:hisabati_app/services/reporting_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Setup FFI for Desktop Testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('v25 Performance & Accuracy Verification', () {
    final dbHelper = DatabaseHelper();
    final reporting = ReportingService();

    test('Stress Test: Insert 5000 Lines and Verify Total P&L', () async {
      print("🚀 Starting Stress Test (v25)...");
      
      // Use a local test DB path instead of default app path
      final dbPath = 'test_v25.db';
      final db = await openDatabase(dbPath);
      dbHelper.setTestDatabase(db);
      
      // 1. Create tables needed for P&L test if they don't exist
      await db.execute('CREATE TABLE IF NOT EXISTS journal_entries (id TEXT PRIMARY KEY, date TEXT, description TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS journal_entry_lines (id TEXT PRIMARY KEY, entry_id TEXT, account_id TEXT, debit REAL, credit REAL, cost_center_id TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, code TEXT, name TEXT, type TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS cost_centers (id TEXT PRIMARY KEY, name TEXT, code TEXT)');

      // Seed core accounts for testing
      await db.insert('accounts', {'id': 'ACC_EXPENSES_GENERAL', 'code': '503', 'name': 'مصروفات عمومية', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_BANK_1', 'code': '104', 'name': 'مصرف الراجحي', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
      
      await db.insert('cost_centers', {'id': 'CC_MGMT', 'name': 'Management', 'code': '100'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_SALES', 'name': 'Sales', 'code': '200'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_OPS', 'name': 'Operations', 'code': '300'}, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.delete('journal_entry_lines');
      await db.delete('journal_entries');

      final stopwatch = Stopwatch()..start();

      await db.transaction((txn) async {
        for (int i = 0; i < 5000; i++) {
          final String entryId = 'STRESS_ENTRY_$i';
          final String ccId = (i % 3 == 0) ? 'CC_MGMT' : (i % 3 == 1 ? 'CC_SALES' : 'CC_OPS');
          
          await txn.insert('journal_entries', {
            'id': entryId,
            'date': '2026-04-01',
            'description': 'Stress Test Entry $i',
          });

          // Debit Expense
          await txn.insert('journal_entry_lines', {
            'id': '${entryId}_D',
            'entry_id': entryId,
            'account_id': 'ACC_EXPENSES_GENERAL',
            'debit': 100.0,
            'credit': 0.0,
            'cost_center_id': ccId,
          });

          // Credit Cash
          await txn.insert('journal_entry_lines', {
            'id': '${entryId}_C',
            'entry_id': entryId,
            'account_id': 'ACC_BANK_1',
            'debit': 0.0,
            'credit': 100.0,
            'cost_center_id': ccId,
          });
        }
      });

      print("⏱️ Inserted 5000 entries (10,000 lines) in ${stopwatch.elapsedMilliseconds}ms");

      // 2. Performance Check: Generating Reports
      stopwatch.reset();
      final globalPNL = await reporting.getPNLReport('2026-01-01', '2026-12-31');
      print("📊 Global P&L Generation: ${stopwatch.elapsedMilliseconds}ms");
      print("💰 Global Expenses: ${globalPNL['expenses']}");

      // 3. Accuracy Check: Sum of CCs vs Global
      stopwatch.reset();
      final ccPerformance = await reporting.getCostCenterPerformance('2026-01-01', '2026-12-31');
      print("📈 CC Performance Matrix Generation: ${stopwatch.elapsedMilliseconds}ms");

      double sumOfCCExpenses = 0;
      for (var cc in ccPerformance) {
        sumOfCCExpenses += cc['expenses'] as double;
        print("   - ${cc['name']}: ${cc['expenses']} SAR");
      }

      print("✅ Global Expenses: ${globalPNL['expenses']}");
      print("✅ Sum of CC Expenses: $sumOfCCExpenses");

      expect(globalPNL['expenses'], equals(sumOfCCExpenses), reason: "Sum of CCs must match Global Total");
      expect(globalPNL['expenses'], equals(5000 * 100.0));
      
      print("✨ Verification Completed Successfully!");
    });
  });
}
