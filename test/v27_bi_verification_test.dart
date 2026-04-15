import 'package:flutter_test/flutter_test.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:hisabati_app/services/cash_flow_service.dart';
import 'package:hisabati_app/services/tax_service.dart';
import 'package:hisabati_app/services/reporting_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('v27: BI Dashboard, Cash-Flow & Tax Engine Verification', () {
    final dbHelper = DatabaseHelper();
    final cashFlowService = CashFlowService();
    final taxService = TaxService();
    final reportingService = ReportingService();

    test('Full BI Integration Test: Cash Flow & ZATCA Tax Compliance', () async {
      print("🚀 Starting BI & Tax Verification Test (v27)...");
      final dbPath = 'test_v27.db';
      final db = await openDatabase(dbPath);
      dbHelper.setTestDatabase(db);
      
      // 1. Setup Tables
      await db.execute('DROP TABLE IF EXISTS journal_entries');
      await db.execute('DROP TABLE IF EXISTS journal_entry_lines');
      await db.execute('DROP TABLE IF EXISTS accounts');
      await db.execute('DROP TABLE IF EXISTS cost_centers');
      await db.execute('DROP TABLE IF EXISTS invoices');
      await db.execute('DROP TABLE IF EXISTS purchase_invoices');
      await db.execute('DROP TABLE IF EXISTS employees');

      await db.execute('CREATE TABLE journal_entries (id TEXT PRIMARY KEY, date TEXT, description TEXT, reference_id TEXT)');
      await db.execute('CREATE TABLE journal_entry_lines (id TEXT PRIMARY KEY, entry_id TEXT, account_id TEXT, debit REAL, credit REAL, cost_center_id TEXT)');
      await db.execute('CREATE TABLE accounts (id TEXT PRIMARY KEY, code TEXT, name TEXT, type TEXT, balance REAL DEFAULT 0)');
      await db.execute('CREATE TABLE cost_centers (id TEXT PRIMARY KEY, name TEXT, code TEXT)');
      await db.execute('CREATE TABLE invoices (id TEXT PRIMARY KEY, issue_date TEXT, client_id TEXT, subtotal REAL, tax_amount REAL, total REAL, payment_type TEXT, due_date TEXT, is_return INTEGER DEFAULT 0, status TEXT)');
      await db.execute('CREATE TABLE purchase_invoices (id TEXT PRIMARY KEY, issue_date TEXT, supplier_id TEXT, subtotal REAL, tax_amount REAL, total REAL, payment_type TEXT, due_date TEXT, is_return INTEGER DEFAULT 0, status TEXT)');
      await db.execute('CREATE TABLE employees (id TEXT PRIMARY KEY, name TEXT, basic_salary REAL, status TEXT)');

      // Seed Balances
      await db.insert('accounts', {'id': 'ACC_CASH', 'code': '100', 'name': 'Cash', 'type': 'asset', 'balance': 50000.0});
      await db.insert('cost_centers', {'id': 'CC_MGMT', 'name': 'Management', 'code': '100'});

      // Date Logic
      final now = DateTime.now();
      final nowStr = now.toIso8601String().split('T')[0];
      final futureDate = now.add(const Duration(days: 15)).toIso8601String().split('T')[0];

      // 2. Tax Engine Test Data (ZATCA)
      // Sales Invoice (Output VAT)
      await db.insert('invoices', {'id': 'INV_1', 'issue_date': nowStr, 'payment_type': 'credit', 'due_date': futureDate, 'subtotal': 10000.0, 'tax_amount': 1500.0, 'total': 11500.0, 'is_return': 0, 'status': 'pending'});
      // Sales Return / Credit Note (Negative Output VAT)
      await db.insert('invoices', {'id': 'INV_RET_1', 'issue_date': nowStr, 'payment_type': 'credit', 'due_date': futureDate, 'subtotal': 2000.0, 'tax_amount': 300.0, 'total': 2300.0, 'is_return': 1, 'status': 'completed'}); // Return

      // Purchase Invoice (Input VAT)
      await db.insert('purchase_invoices', {'id': 'PINV_1', 'issue_date': nowStr, 'payment_type': 'credit', 'due_date': futureDate, 'subtotal': 4000.0, 'tax_amount': 600.0, 'total': 4600.0, 'is_return': 0, 'status': 'pending'});

      // Employee for payroll prediction
      await db.insert('employees', {'id': 'EMP_1', 'name': 'Test', 'basic_salary': 5000.0, 'status': 'active'});

      // --- Verify Tax Logic ---
      final taxReturn = await taxService.generateVatReturn(nowStr, futureDate);
      print("📊 ZATCA VAT Return: $taxReturn");
      // Output VAT should be 1500 - 300 = 1200
      expect(taxReturn['net_output_vat'], equals(1200.0));
      // Input VAT should be 600
      expect(taxReturn['net_input_vat'], equals(600.0));
      // Due to ZATCA = 1200 - 600 = 600
      expect(taxReturn['tax_due'], equals(600.0));
      print("✅ ZATCA Tax Logic with Credit Notes Verified!");

      // --- Verify AI Cash Flow Forecasting ---
      final cashForecast = await cashFlowService.forecastLiquidity(30);
      print("🔮 Cash Flow Forecast (30 Days): $cashForecast");
      
      expect(cashForecast['current_cash'], equals(50000.0));
      // Expected Inflow = 11500 (we don't count returns as positive inflow usually, but for test logic we check the implementation)
      // Actually we set 'is_return = 0' in the CashFlow service query. So only INV_1 counts.
      expect(cashForecast['expected_inflow'], equals(11500.0));
      // Expected Outflow = 4600 (Purchases) + 5000 (Payroll) = 9600
      expect(cashForecast['expected_outflow'], equals(9600.0));
      // Projected Cash = 50000 + 11500 - 9600 = 51900
      expect(cashForecast['projected_cash'], equals(51900.0));
      print("✅ Predictive Cash Flow Logistics Verified!");

      // --- Verify Aggregated Reporting (Optimization check) ---
      // Simulate Journal entries for CC_MGMT
      await db.insert('journal_entries', {'id': 'J_1', 'date': nowStr, 'description': 'Sale'});
      await db.insert('journal_entry_lines', {'id': 'JL_1', 'entry_id': 'J_1', 'account_id': 'ACC_REV', 'debit': 0, 'credit': 5000.0, 'cost_center_id': 'CC_MGMT'}); // Revenue Account
      await db.insert('accounts', {'id': 'ACC_REV', 'type': 'revenue'});

      final ccPerf = await reportingService.getCostCenterPerformance(nowStr, futureDate);
      expect(ccPerf.length, equals(1));
      expect(ccPerf.first['revenue'], equals(5000.0));
      print("✅ Aggregated Cost Center Reporting Verified!");
      
      print("✨ BI & Tax Virtual Architecture Verified Successfully!");
    });
  });
}
