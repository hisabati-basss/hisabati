import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import '../core/accounting/coa_template.dart';
import 'industry_provider.dart';
import 'audit_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  @visibleForTesting
  void setTestDatabase(Database db) {
    _database = db;
  }

  static const String _databaseName = "hisabati.db";
  static const int _databaseVersion = 59;

  Future<Database> _initDatabase() async {
    // Force Web FFI
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        _databaseName,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // Force FFI on desktop platforms if not already set
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (Platform.isWindows) {
      final appSupportDir = await getApplicationSupportDirectory();
      dbPath = join(appSupportDir.path, _databaseName);
    } else {
      dbPath = join(await getDatabasesPath(), 'hisabati_offline.db');
    }

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Returns a combined string of (Device Name - Serial Number) for v34 Sync Engine
  Future<String> getDeviceFingerprint() async {
    final devInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final web = await devInfo.webBrowserInfo;
        return "Web-${web.browserName.name}-${web.platform}";
      }
      if (Platform.isWindows) {
        final win = await devInfo.windowsInfo;
        return "${win.computerName}-${win.deviceId}";
      }
      if (Platform.isAndroid) {
        final and = await devInfo.androidInfo;
        return "${and.model}-${and.id}";
      }
      if (Platform.isIOS) {
        final ios = await devInfo.iosInfo;
        return "${ios.name}-${ios.identifierForVendor}";
      }
    } catch (_) {}
    return "Unknown-Device";
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v43: Force re-apply of any skipped tables due to fresh install missed logic
    if (oldVersion < 43) {
      // Safe CREATE TABLE statements if they were missed during V42 manual skips
      await db.execute("CREATE TABLE IF NOT EXISTS attendance_logs (id TEXT PRIMARY KEY, employee_id TEXT, date TEXT, check_in TEXT, check_out TEXT, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS leave_requests (id TEXT PRIMARY KEY, employee_id TEXT, type TEXT, start_date TEXT, end_date TEXT, reason TEXT, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS employee_loans (id TEXT PRIMARY KEY, employee_id TEXT, amount REAL, monthly_installment REAL, start_date TEXT, balance REAL, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS real_estate_units (id TEXT PRIMARY KEY, name TEXT, type TEXT, address TEXT, rent_amount REAL, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS real_estate_contracts (id TEXT PRIMARY KEY, unit_id TEXT, tenant_name TEXT, tenant_phone TEXT, start_date TEXT, end_date TEXT, annual_rent REAL, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS investments (id TEXT PRIMARY KEY, name TEXT, type TEXT, current_value REAL, risk_level TEXT, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
      await db.execute("CREATE TABLE IF NOT EXISTS liquidation_requests (id TEXT PRIMARY KEY, asset_id TEXT, asset_type TEXT, requested_amount REAL, reason TEXT, status TEXT, is_deleted INTEGER DEFAULT 0, created_at TEXT)");
    }

    if (oldVersion < 44) {
      // Fix tables that were created in v43 without the is_deleted column
      try { await db.execute("ALTER TABLE real_estate_units ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE real_estate_contracts ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE investments ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE liquidation_requests ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE attendance_logs ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE leave_requests ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE employee_loans ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
    }

    if (oldVersion < 45) {
      try { await db.execute("ALTER TABLE employees ADD COLUMN manager_id TEXT"); } catch (_) {}
    }

    if (oldVersion < 46) {
      try { await db.execute("ALTER TABLE companies ADD COLUMN logo_path TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE companies ADD COLUMN letterhead_path TEXT"); } catch (_) {}
    }

    if (oldVersion < 47) {
      // v47: Sales Agents & Commissions Module
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_agents (
          id TEXT PRIMARY KEY,
          name TEXT,
          phone TEXT,
          email TEXT,
          commission_rate REAL DEFAULT 0, -- Default percentage
          status TEXT DEFAULT 'active'
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_targets (
          id TEXT PRIMARY KEY,
          agent_id TEXT,
          month TEXT, -- YYYY-MM
          target_amount REAL,
          achieved_amount REAL DEFAULT 0,
          commission_earned REAL DEFAULT 0,
          status TEXT DEFAULT 'pending'
        )
      ''');

      // Add sales_agent_id to invoices
      try { await db.execute("ALTER TABLE invoices ADD COLUMN sales_agent_id TEXT"); } catch (_) {}
    }



    if (oldVersion < 48) {
      // v48: System Users & Permissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE,
          name TEXT,
          email TEXT,
          role TEXT DEFAULT 'employee',
          avatar_url TEXT,
          is_active INTEGER DEFAULT 1,
          permissions TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          assigned_to TEXT,
          assigned_by TEXT,
          due_date TEXT,
          priority TEXT DEFAULT 'medium',
          status TEXT DEFAULT 'pending',
          project_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          id TEXT PRIMARY KEY,
          owner_type TEXT,
          owner_id TEXT,
          name TEXT,
          file_path TEXT,
          file_type TEXT,
          expiry_date TEXT,
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 49) {
      // v49: Advanced Accounting Tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotations (
          id TEXT PRIMARY KEY,
          client_id TEXT,
          client_name TEXT,
          issue_date TEXT,
          expiry_date TEXT,
          subtotal REAL DEFAULT 0,
          tax_amount REAL DEFAULT 0,
          total REAL DEFAULT 0,
          status TEXT DEFAULT 'draft',
          notes TEXT,
          converted_invoice_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotation_lines (
          id TEXT PRIMARY KEY,
          quotation_id TEXT,
          item_id TEXT,
          name TEXT,
          quantity REAL,
          price REAL,
          tax_rate REAL DEFAULT 0,
          total REAL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS receipt_vouchers (
          id TEXT PRIMARY KEY,
          client_id TEXT,
          client_name TEXT,
          amount REAL,
          payment_method TEXT,
          bank_account_id TEXT,
          invoice_id TEXT,
          date TEXT,
          notes TEXT,
          journal_entry_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_vouchers (
          id TEXT PRIMARY KEY,
          supplier_id TEXT,
          supplier_name TEXT,
          amount REAL,
          payment_method TEXT,
          bank_account_id TEXT,
          invoice_id TEXT,
          date TEXT,
          notes TEXT,
          journal_entry_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_notes (
          id TEXT PRIMARY KEY,
          original_invoice_id TEXT,
          client_id TEXT,
          amount REAL,
          reason TEXT,
          date TEXT,
          journal_entry_id TEXT,
          status TEXT DEFAULT 'draft',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id TEXT PRIMARY KEY,
          type TEXT,
          template_data TEXT,
          frequency TEXT,
          next_run_date TEXT,
          last_run_date TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_trail (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          user_name TEXT,
          action TEXT,
          entity_type TEXT,
          entity_id TEXT,
          old_value TEXT,
          new_value TEXT,
          ip_address TEXT,
          timestamp TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS currency_rates (
          id TEXT PRIMARY KEY,
          from_currency TEXT,
          to_currency TEXT,
          rate REAL,
          date TEXT,
          source TEXT DEFAULT 'manual'
        )
      ''');
    }

    if (oldVersion < 51) {
      try { await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN reconciled INTEGER DEFAULT 0"); } catch (_) {}
    }

    if (oldVersion < 52) {
      // Universal ERP: Closing Date for Fiscal Control
      try { await db.execute("ALTER TABLE companies ADD COLUMN closing_date TEXT"); } catch (_) {}

      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN payment_status TEXT DEFAULT 'draft'"); } catch (_) {}

      // HR: Performance Reviews Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS performance_reviews (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          review_date TEXT,
          rating INTEGER, -- 1 to 5
          manager_feedback TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // HR: Employee Contracts Table (Universal QuickBooks style)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employee_contracts (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          contract_type TEXT, -- (Fixed, Unlimited)
          start_date TEXT,
          end_date TEXT,
          basic_salary REAL,
          allowances TEXT, -- JSON string for dynamic allowances
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 53) {
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN overtime REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN custom_earnings REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN tax_deduction REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN loan_deduction REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN custom_deductions REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN payment_status TEXT DEFAULT 'draft'"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN cost_center_id TEXT"); } catch (_) {}
    }

    if (oldVersion < 54) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_transactions (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          item_name TEXT,
          type TEXT, -- (sale, purchase, adjustment, return)
          quantity REAL,
          reference_id TEXT,
          date TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 55) {
      // Phase 12: Professional Accounting (Purchase Orders & Debit Notes)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_orders (
          id TEXT PRIMARY KEY,
          supplier_id TEXT,
          issue_date TEXT,
          expected_delivery TEXT,
          subtotal REAL,
          tax_amount REAL,
          total REAL,
          status TEXT DEFAULT 'draft',
          notes TEXT,
          converted_invoice_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_lines (
          id TEXT PRIMARY KEY,
          order_id TEXT,
          item_id TEXT,
          name TEXT,
          quantity REAL,
          price REAL,
          total REAL,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS debit_notes (
          id TEXT PRIMARY KEY,
          original_purchase_id TEXT,
          supplier_id TEXT,
          amount REAL,
          reason TEXT,
          date TEXT,
          journal_entry_id TEXT,
          status TEXT DEFAULT 'draft',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id TEXT PRIMARY KEY,
          code TEXT,
          name TEXT,
          type TEXT,
          balance REAL DEFAULT 0,
          parent_id TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries (
          id TEXT PRIMARY KEY,
          date TEXT,
          description TEXT,
          reference_id TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entry_lines (
          id TEXT PRIMARY KEY,
          entry_id TEXT,
          account_id TEXT,
          debit REAL DEFAULT 0,
          credit REAL DEFAULT 0,
          reconciled INTEGER DEFAULT 0
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_transactions (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          item_name TEXT,
          type TEXT,
          quantity REAL,
          reference_id TEXT,
          date TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await _seedDefaultAccounts(db); // Seed if empty
    }
    
    if (oldVersion < 6) {
      // HR Module Tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employees (
          id TEXT PRIMARY KEY,
          name TEXT,
          job_title TEXT,
          basic_salary REAL,
          hiring_date TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS salary_payments (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          pay_period TEXT,
          amount REAL,
          payment_date TEXT
        )
      ''');
      
      // Ensure the salary expense account exists
      final res = await db.query('accounts', where: 'id = ?', whereArgs: ['ACC_EXPENSES_SALARY']);
      if (res.isEmpty) {
        await db.insert('accounts', {'id': 'ACC_EXPENSES_SALARY', 'code': '501', 'name': 'مصروفات الرواتب والأجور', 'type': 'expense'});
      }
    }
    
    if (oldVersion < 7) {
      // Add payment_type to invoices
      try { await db.execute("ALTER TABLE invoices ADD COLUMN payment_type TEXT DEFAULT 'cash'"); } catch (_) {}

      // Create Suppliers and Purchases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id TEXT PRIMARY KEY,
          name TEXT,
          contact_info TEXT,
          tax_id TEXT,
          balance REAL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_invoices (
          id TEXT PRIMARY KEY,
          issue_date TEXT,
          supplier_id TEXT,
          subtotal REAL,
          tax_amount REAL,
          total REAL,
          payment_type TEXT DEFAULT 'credit'
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id TEXT PRIMARY KEY,
          partner_id TEXT,
          partner_type TEXT,
          amount REAL,
          type TEXT,
          date TEXT
        )
      ''');

      // Add Credit/Debt new Accounts
      await db.insert('accounts', {'id': 'ACC_RECEIVABLE', 'code': '102', 'name': 'مدينون (العملاء)', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_PAYABLE', 'code': '202', 'name': 'دائنون (الموردين)', 'type': 'liability'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_INVENTORY', 'code': '103', 'name': 'المخزون', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (oldVersion < 8) {
      try { await db.execute("ALTER TABLE invoices ADD COLUMN due_date TEXT"); } catch (_) {}
    }

    if (oldVersion < 9) {
      // Add cost_price to items
      try { await db.execute("ALTER TABLE items ADD COLUMN cost_price REAL DEFAULT 0"); } catch (_) {}
      
      // New Accounts: COGS & General Expenses
      await db.insert('accounts', {'id': 'ACC_COGS', 'code': '502', 'name': 'تكلفة المبيعات (COGS)', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_EXPENSES_GENERAL', 'code': '503', 'name': 'مصروفات عمومية وتسويق', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    if (oldVersion < 10) {
      // Assets Module
      await db.execute('''
        CREATE TABLE IF NOT EXISTS assets (
          id TEXT PRIMARY KEY,
          name TEXT,
          barcode TEXT,
          serial_number TEXT,
          location TEXT,
          image_path TEXT,
          cost_price REAL DEFAULT 0,
          status TEXT,
          assigned_to TEXT,
          purchase_date TEXT
        )
      ''');
    }

    if (oldVersion < 11) {
      // Internal Hub (Chat & Tasks)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS channels (
          id TEXT PRIMARY KEY,
          name TEXT,
          type TEXT,
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          channel_id TEXT,
          sender_id TEXT,
          sender_name TEXT,
          content TEXT,
          created_at TEXT,
          is_task INTEGER DEFAULT 0,
          task_id TEXT
        )
      ''');
      // Adding dummy chat records so you can test immediately
      await db.insert('channels', {'id': 'CH_GENERAL', 'name': 'الفرع الرئيسي', 'type': 'public', 'created_at': DateTime.now().toIso8601String()});
      await db.insert('channels', {'id': 'CH_SALES', 'name': 'فريق المبيعات', 'type': 'public', 'created_at': DateTime.now().toIso8601String()});
      
      await db.insert('messages', {
        'id': 'MSG001', 'channel_id': 'CH_GENERAL', 'sender_id': 'SYS', 'sender_name': 'النظام', 
        'content': 'مرحباً بالجميع في مركز التواصل الداخلي!', 'created_at': DateTime.now().subtract(const Duration(minutes: 60)).toIso8601String(), 'is_task': 0
      });
      await db.insert('messages', {
        'id': 'MSG002', 'channel_id': 'CH_GENERAL', 'sender_id': 'EMP01', 'sender_name': 'أحمد سعيد', 
        'content': 'يرجى مراجعة إعدادات العهدة الخاصة بفرع الرياض وتسليمها للمستودع خلال اليوم.', 'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(), 'is_task': 0
      });
    }

    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_invoice_lines (
          id TEXT PRIMARY KEY,
          invoice_id TEXT,
          item_id TEXT,
          name TEXT,
          quantity REAL,
          price_at_purchase REAL
        )
      ''');
    }

    if (oldVersion < 13) {
      // Banks and Wallet Module
      await db.execute('''
        CREATE TABLE IF NOT EXISTS money_transfers (
          id TEXT PRIMARY KEY,
          from_account_id TEXT,
          to_account_id TEXT,
          amount REAL,
          fee REAL DEFAULT 0,
          date TEXT,
          attachment_path TEXT,
          notes TEXT
        )
      ''');

      // Add attachment columns to existing tables
      try { await db.execute("ALTER TABLE invoices ADD COLUMN attachment_path TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE purchase_invoices ADD COLUMN attachment_path TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE payments ADD COLUMN attachment_path TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE journal_entries ADD COLUMN attachment_path TEXT"); } catch (_) {}

      // Seed New Bank Accounts
      await db.insert('accounts', {'id': 'ACC_BANK_1', 'code': '104', 'name': 'مصرف الراجحي', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_BANK_2', 'code': '105', 'name': 'البنك الأهلي Saudi National Bank', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_EXPENSES_BANK', 'code': '504', 'name': 'مصاريف وعمولات بنكية', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (oldVersion < 15) {
      // v15: Smart Inventory & Cloud Inbox
      try { await db.execute("ALTER TABLE items ADD COLUMN min_stock_level REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE items ADD COLUMN lead_time INTEGER DEFAULT 0"); } catch (_) {}
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS draft_invoices (
          id TEXT PRIMARY KEY,
          date TEXT,
          supplier_name TEXT,
          total_amount REAL,
          attachment_path TEXT,
          status TEXT DEFAULT 'pending',
          raw_ocr_json TEXT
        )
      ''');
    }

    if (oldVersion < 16) {
      // v16: Assets Custody & Maintenance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS asset_custody_log (
          id TEXT PRIMARY KEY,
          asset_id TEXT,
          employee_id TEXT,
          issued_date TEXT,
          returned_date TEXT,
          status TEXT,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS maintenance_schedules (
          id TEXT PRIMARY KEY,
          asset_id TEXT,
          scheduled_date TEXT,
          reason TEXT,
          status TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS damage_reports (
          id TEXT PRIMARY KEY,
          asset_id TEXT,
          employee_id TEXT,
          date TEXT,
          damage_reason TEXT,
          value_loss REAL,
          entry_id TEXT
        )
      ''');
      
      // New Accounts for v16
      await db.insert('accounts', {'id': 'ACC_LOSS_ASSETS', 'code': '505', 'name': 'خسائر وإعدام أصول', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_EMP_RECEIVABLE', 'code': '106', 'name': 'سلف وعُهد موظفين', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    if (oldVersion < 17) {
      // v17: Projects & Contracting Cost Centers
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cost_centers (
          id TEXT PRIMARY KEY,
          name TEXT,
          code TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id TEXT PRIMARY KEY,
          name TEXT,
          budget_amount REAL DEFAULT 0,
          cost_center_id TEXT,
          start_date TEXT,
          end_date TEXT,
          status TEXT DEFAULT 'active',
          manager_id TEXT
        )
      ''');

      // Alter existing tables to link them to projects for cost tracking
      try { await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN project_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE purchase_invoices ADD COLUMN project_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_payments ADD COLUMN project_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE invoices ADD COLUMN project_id TEXT"); } catch (_) {}
    }
    
    if (oldVersion < 18) {
      // v18: POS Shifts and Cart Tracking
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shifts (
          id TEXT PRIMARY KEY,
          cashier_id TEXT,
          start_time TEXT,
          end_time TEXT,
          opening_balance REAL DEFAULT 0,
          closing_balance REAL DEFAULT 0,
          status TEXT DEFAULT 'open'
        )
      ''');

      try { await db.execute("ALTER TABLE invoices ADD COLUMN shift_id TEXT"); } catch (_) {}
    }

    if (oldVersion < 19) {
      // v21: Supplier Statements & Aging (Migration)
      try {
        await db.execute("ALTER TABLE purchase_invoices ADD COLUMN due_date TEXT");
        // Update existing ones to have due_date same as issue_date if possible
        await db.execute("UPDATE purchase_invoices SET due_date = issue_date WHERE due_date IS NULL");
      } catch (_) {}
    }

    if (oldVersion < 20) {
      // v22: Expense Budgeting & Smart Control
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          account_id TEXT,
          project_id TEXT,
          allocated_amount REAL,
          period TEXT,
          created_at TEXT
        )
      ''');
    }

    if (oldVersion < 21) {
      // v23: Fixed Assets & Automated Depreciation
      try {
        await db.execute("ALTER TABLE assets ADD COLUMN useful_life_months INTEGER DEFAULT 60");
        await db.execute("ALTER TABLE assets ADD COLUMN salvage_value REAL DEFAULT 0");
        await db.execute("ALTER TABLE assets ADD COLUMN depreciation_method TEXT DEFAULT 'straight_line'");
        await db.execute("ALTER TABLE assets ADD COLUMN last_depreciation_date TEXT");
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS asset_depreciation_logs (
          id TEXT PRIMARY KEY,
          asset_id TEXT,
          date TEXT,
          amount REAL,
          entry_id TEXT
        )
      ''');

      // Seed Accounts for Depreciation
      await db.insert('accounts', {'id': 'ACC_DEPRECIATION_EXPENSE', 'code': '510', 'name': 'مصروف إهلاك الأصول', 'type': 'expense'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('accounts', {'id': 'ACC_ACCUMULATED_DEPRECIATION', 'code': '110', 'name': 'مجمع إهلاك الأصول المتراكم', 'type': 'asset'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (oldVersion < 22) {
      // v24: Smart HR & Payroll Migration
      try {
        await db.execute("ALTER TABLE employees ADD COLUMN housing_allowance REAL DEFAULT 0");
        await db.execute("ALTER TABLE employees ADD COLUMN transport_allowance REAL DEFAULT 0");
        await db.execute("ALTER TABLE employees ADD COLUMN insurance_deduction REAL DEFAULT 0");
        await db.execute("ALTER TABLE employees ADD COLUMN bank_name TEXT");
        await db.execute("ALTER TABLE employees ADD COLUMN iban TEXT");
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance_logs (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          date TEXT,
          status TEXT, -- 'present', 'absent', 'late', 'leave'
          notes TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS salary_slips (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          month TEXT, -- YYYY-MM
          basic_salary REAL,
          housing_allowance REAL,
          transport_allowance REAL,
          insurance_deduction REAL,
          absence_deduction REAL,
          net_salary REAL,
          payment_date TEXT,
          entry_id TEXT, -- Relation to Journal Entry
          status TEXT DEFAULT 'paid'
        )
      ''');
    }

    if (oldVersion < 23) {
      // v25: Cost Centers & Advanced Reporting Migration
      try {
        await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN cost_center_id TEXT");
        await db.execute("ALTER TABLE purchase_invoices ADD COLUMN cost_center_id TEXT");
        await db.execute("ALTER TABLE salary_slips ADD COLUMN cost_center_id TEXT");
        await db.execute("ALTER TABLE budgets ADD COLUMN cost_center_id TEXT");
        await db.execute("ALTER TABLE employees ADD COLUMN cost_center_id TEXT");
      } catch (_) {}

      // Seed Default Cost Centers
      await db.insert('cost_centers', {'id': 'CC_MGMT', 'name': 'الإدارة العامة', 'code': '100'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_SALES', 'name': 'قسم المبيعات', 'code': '200'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_OPS', 'name': 'إدارة التشغيل', 'code': '300'}, conflictAlgorithm: ConflictAlgorithm.replace);

      // Link existing projects to Operations by default
      await db.execute("UPDATE projects SET cost_center_id = 'CC_OPS' WHERE cost_center_id IS NULL");
      // Backfill existing invoices/slips to a cost center if needed (Optional, usually projects map to CCs)
    }

    if (oldVersion < 24) {
      // v26: Smart Asset Management & Integration
      try {
        await db.execute("ALTER TABLE assets ADD COLUMN cost_center_id TEXT");
        await db.execute("ALTER TABLE assets ADD COLUMN purchase_invoice_id TEXT");
        await db.execute("ALTER TABLE maintenance_schedules ADD COLUMN total_cost REAL DEFAULT 0");
        await db.execute("ALTER TABLE maintenance_schedules ADD COLUMN linked_invoice_id TEXT");
      } catch (_) {}

      // Default assets to the operations cost center if they aren't assigned
      await db.execute("UPDATE assets SET cost_center_id = 'CC_OPS' WHERE cost_center_id IS NULL");
    }

    if (oldVersion < 25) {
      // v27: Tax Engine & ZATCA Compliance (Credit Notes tracking)
      try {
        await db.execute("ALTER TABLE invoices ADD COLUMN is_return INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE purchase_invoices ADD COLUMN is_return INTEGER DEFAULT 0");
      } catch (_) {}
    }

    if (oldVersion < 26) {
      // v28: Global Warehouse & Barcode POS
      await db.execute('''
        CREATE TABLE IF NOT EXISTS warehouses (
          id TEXT PRIMARY KEY,
          name TEXT,
          location TEXT,
          cost_center_id TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_batches (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          warehouse_id TEXT,
          quantity REAL DEFAULT 0,
          expiry_date TEXT,
          batch_number TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_transfers (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          from_warehouse_id TEXT,
          to_warehouse_id TEXT,
          quantity REAL,
          date TEXT,
          status TEXT
        )
      ''');
      try {
        await db.execute("ALTER TABLE items ADD COLUMN barcode TEXT");
      } catch (_) {}
    }

    if (oldVersion < 27) {
      // v29: Manufacturing & Production BOM
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bom (
          id TEXT PRIMARY KEY,
          finished_good_item_id TEXT,
          name TEXT,
          description TEXT,
          estimated_overhead_cost REAL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bom_lines (
          id TEXT PRIMARY KEY,
          bom_id TEXT,
          raw_material_item_id TEXT,
          quantity_required REAL,
          waste_percentage REAL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_orders (
          id TEXT PRIMARY KEY,
          bom_id TEXT,
          status TEXT DEFAULT 'draft',
          qty_to_produce REAL,
          start_date TEXT,
          end_date TEXT,
          actual_material_cost REAL DEFAULT 0,
          actual_overhead_cost REAL DEFAULT 0,
          total_cost REAL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 28) {
      // v30 Fix: Adding missing attachment_path for Web/Mobile consistency
      try {
        await db.execute("ALTER TABLE invoices ADD COLUMN attachment_path TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE purchase_invoices ADD COLUMN attachment_path TEXT");
      } catch (_) {}
    }

    if (oldVersion < 29) {
      // v31: Smart Cheque Portfolio Module
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cheques (
            id TEXT PRIMARY KEY,
            cheque_number TEXT,
            bank_name TEXT,
            amount REAL,
            issue_date TEXT,
            due_date TEXT,
            type TEXT,
            partner_id TEXT,
            partner_name TEXT,
            partner_type TEXT,
            status TEXT,
            journal_entry_id TEXT,
            notes TEXT
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 30) {
      // v32: Custody Management Module (Financial & Assets)
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS financial_custodies (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            employee_name TEXT,
            amount REAL,
            issue_date TEXT,
            reason TEXT,
            status TEXT, -- 'معلقة' (Pending), 'مصفاة' (Cleared)
            journal_entry_issue TEXT,
            journal_entry_clear TEXT,
            clearance_date TEXT,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS asset_custody_logs (
            id TEXT PRIMARY KEY,
            asset_id TEXT,
            asset_name TEXT,
            employee_id TEXT,
            employee_name TEXT,
            issue_date TEXT,
            return_date TEXT,
            condition_on_issue TEXT,
            condition_on_return TEXT,
            status TEXT -- 'بحوزة الموظف', 'مسترجع'
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 31) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS employees (
            id TEXT PRIMARY KEY,
            name TEXT,
            job_title TEXT,
            basic_salary REAL,
            hiring_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cost_centers (
            id TEXT PRIMARY KEY,
            name TEXT
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 32) {
      try {
        await db.execute('ALTER TABLE journal_entries ADD COLUMN attachment_path TEXT');
      } catch (_) {}
    }

    if (oldVersion < 33) {
      try {
        await db.execute('ALTER TABLE assets ADD COLUMN cost_center_id TEXT');
      } catch (_) {}
    }

    if (oldVersion < 38) {
      // v36/37/38 Schema stabilization & tables recreation

      
      // v36 Final Recovery: Force standardized Sync Engine columns for all tables
      // This repeat is necessary because some users already hit version 35 without columns
      
      final tablesToUnify = [
        'companies', 'clients', 'items', 'invoices', 'invoice_lines', 
        'purchase_invoices', 'purchase_invoice_lines', 'journal_entries', 
        'journal_entry_lines', 'accounts', 'employees', 'salary_payments', 
        'attendance_logs', 'salary_slips', 'suppliers', 'payments', 
        'cost_centers', 'projects', 'budgets', 'assets', 'asset_depreciation_logs', 
        'warehouses', 'inventory_batches', 'inventory_transfers', 'bom', 
        'bom_lines', 'manufacturing_orders', 'cheques', 'financial_custodies', 
        'asset_custody_logs', 'asset_custody_log', 'channels', 'messages', 'shifts', 'tasks',
        'pos_sessions', 'users', 'draft_invoices'
      ];

      // Ensure these crucial tables exist before adding columns
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS pos_sessions (id TEXT PRIMARY KEY, cashier_id TEXT, start_time TEXT, end_time TEXT, opening_balance REAL, closing_balance REAL, status TEXT)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT, name TEXT, role TEXT, avatar_url TEXT)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS asset_depreciation_logs (id TEXT PRIMARY KEY, asset_id TEXT, date TEXT, amount REAL, entry_id TEXT)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS money_transfers (id TEXT PRIMARY KEY, from_account_id TEXT, to_account_id TEXT, from_name TEXT, to_name TEXT, amount REAL, fee REAL, date TEXT, notes TEXT, attachment_path TEXT)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS draft_invoices (id TEXT PRIMARY KEY, customer_name TEXT, total REAL, saved_at TEXT, data_json TEXT)''');
      } catch (_) {}

      // Explicitly ensure critical Cost Center and Project columns exist on Journal entries (Core Fix for FinancialReportsScreen)
      try { await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN cost_center_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN project_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE journal_entries ADD COLUMN cost_center_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE journal_entries ADD COLUMN project_id TEXT"); } catch (_) {}


      for (var table in tablesToUnify) {
        try { await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN device_id TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN is_deleted INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {
          try { await db.execute("UPDATE $table SET sync_status = 0 WHERE sync_status IS NULL OR sync_status = 'pending_sync'"); } catch (_) {}
        }
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_audit (
          id TEXT PRIMARY KEY,
          action_type TEXT,
          description TEXT,
          is_critical INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 39) {
      const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';
      
      // 1. HR - Leave Requests
      await db.execute('''
        CREATE TABLE IF NOT EXISTS leave_requests (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          type TEXT, -- SICK, ANNUAL, EMERGENCY
          start_date TEXT,
          end_date TEXT,
          reason TEXT,
          status TEXT DEFAULT 'PENDING',
          $metadata
        )
      ''');

      // 2. HR - Loans
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employee_loans (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          amount REAL,
          monthly_installment REAL,
          start_date TEXT,
          balance REAL,
          status TEXT DEFAULT 'ACTIVE',
          $metadata
        )
      ''');

      // 3. Real Estate - Units
      await db.execute('''
        CREATE TABLE IF NOT EXISTS real_estate_units (
          id TEXT PRIMARY KEY,
          name TEXT,
          type TEXT, -- APARTMENT, VILLA, STUDIO
          address TEXT,
          rent_amount REAL,
          status TEXT DEFAULT 'AVAILABLE', -- AVAILABLE, RENTED, MAINTENANCE
          $metadata
        )
      ''');

      // 4. Real Estate - Contracts
      await db.execute('''
        CREATE TABLE IF NOT EXISTS real_estate_contracts (
          id TEXT PRIMARY KEY,
          unit_id TEXT,
          tenant_name TEXT,
          tenant_phone TEXT,
          start_date TEXT,
          end_date TEXT,
          annual_rent REAL,
          payment_frequency TEXT, -- MONTHLY, QUARTERLY, ANNUAL
          security_deposit REAL,
          status TEXT DEFAULT 'ACTIVE',
          $metadata
        )
      ''');

       // 5. Attendance (Advanced)
       try {
         await db.execute("ALTER TABLE attendance_logs ADD COLUMN check_in TEXT");
         await db.execute("ALTER TABLE attendance_logs ADD COLUMN check_out TEXT");
       } catch (_) {}
    }

    if (oldVersion < 40) {
      const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';

      // 1. Investments
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investments (
          id TEXT PRIMARY KEY,
          name TEXT,
          type TEXT, -- STOCKS, REAL_ESTATE, BUSINESS
          initial_amount REAL,
          current_value REAL,
          status TEXT DEFAULT 'ACTIVE',
          $metadata
        )
      ''');

      // 2. Investment Transactions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investment_transactions (
          id TEXT PRIMARY KEY,
          investment_id TEXT,
          amount REAL,
          date TEXT,
          type TEXT, -- PROFIT, TOPUP, WITHDRAW
          $metadata
        )
      ''');

      // 3. Liquidation Requests
      await db.execute('''
        CREATE TABLE IF NOT EXISTS liquidation_requests (
          id TEXT PRIMARY KEY,
          asset_type TEXT, -- INVESTMENT, ASSET, REAL_ESTATE
          asset_id TEXT,
          reason TEXT,
          requested_amount REAL,
          status TEXT DEFAULT 'PENDING',
          $metadata
        )
      ''');
    }

    if (oldVersion < 41) {
       try {
         await db.execute("ALTER TABLE money_transfers ADD COLUMN reconciled INTEGER DEFAULT 0");
       } catch (_) {}
    }

    if (oldVersion < 42) {
      const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';

      // 1. Sales Targets & Commissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_targets (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          employee_id TEXT,
          target_amount REAL,
          achieved_amount REAL DEFAULT 0,
          start_date TEXT,
          end_date TEXT,
          status TEXT DEFAULT 'ACTIVE',
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commissions (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          invoice_id TEXT,
          amount REAL,
          percentage REAL,
          status TEXT DEFAULT 'PENDING',
          created_at TEXT,
          $metadata
        )
      ''');

      // 2. Promotions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotional_campaigns (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          discount_type TEXT,
          discount_value REAL,
          start_date TEXT,
          end_date TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT,
          $metadata
        )
      ''');

      // 3. Recruitment
      await db.execute('''
        CREATE TABLE IF NOT EXISTS job_applications (
          id TEXT PRIMARY KEY,
          applicant_name TEXT,
          phone TEXT,
          position TEXT,
          cv_path TEXT,
          status TEXT DEFAULT 'NEW',
          interview_date TEXT,
          created_at TEXT,
          $metadata
        )
      ''');

      // 4. Roles & Permissions (Auth System)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE,
          password_hash TEXT,
          employee_id TEXT,
          role TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 48) {
      // 1. Roles & Permissions (Auth System) - Ensure it exists with all columns
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE,
          name TEXT,
          email TEXT,
          password_hash TEXT,
          employee_id TEXT,
          role TEXT DEFAULT 'employee',
          avatar_url TEXT,
          is_active INTEGER DEFAULT 1,
          permissions TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          assigned_to TEXT,
          assigned_by TEXT,
          due_date TEXT,
          priority TEXT DEFAULT 'medium',
          status TEXT DEFAULT 'pending',
          project_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          id TEXT PRIMARY KEY,
          owner_type TEXT,
          owner_id TEXT,
          name TEXT,
          file_path TEXT,
          file_type TEXT,
          expiry_date TEXT,
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 49) {
      // v49: Advanced Accounting Tables & System Integrity
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotations (
          id TEXT PRIMARY KEY,
          client_id TEXT,
          client_name TEXT,
          issue_date TEXT,
          expiry_date TEXT,
          subtotal REAL DEFAULT 0,
          tax_amount REAL DEFAULT 0,
          total REAL DEFAULT 0,
          status TEXT DEFAULT 'draft',
          notes TEXT,
          converted_invoice_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotation_lines (
          id TEXT PRIMARY KEY,
          quotation_id TEXT,
          item_id TEXT,
          name TEXT,
          quantity REAL,
          price REAL,
          tax_rate REAL DEFAULT 0,
          total REAL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS receipt_vouchers (
          id TEXT PRIMARY KEY,
          client_id TEXT,
          client_name TEXT,
          amount REAL,
          payment_method TEXT,
          bank_account_id TEXT,
          invoice_id TEXT,
          date TEXT,
          notes TEXT,
          journal_entry_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_vouchers (
          id TEXT PRIMARY KEY,
          supplier_id TEXT,
          supplier_name TEXT,
          amount REAL,
          payment_method TEXT,
          bank_account_id TEXT,
          invoice_id TEXT,
          date TEXT,
          notes TEXT,
          journal_entry_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS credit_notes (
          id TEXT PRIMARY KEY,
          original_invoice_id TEXT,
          client_id TEXT,
          amount REAL,
          reason TEXT,
          date TEXT,
          journal_entry_id TEXT,
          status TEXT DEFAULT 'draft',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id TEXT PRIMARY KEY,
          type TEXT,
          template_data TEXT,
          frequency TEXT,
          next_run_date TEXT,
          last_run_date TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_trail (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          user_name TEXT,
          action TEXT,
          entity_type TEXT,
          entity_id TEXT,
          old_value TEXT,
          new_value TEXT,
          ip_address TEXT,
          timestamp TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS currency_rates (
          id TEXT PRIMARY KEY,
          from_currency TEXT,
          to_currency TEXT,
          rate REAL,
          date TEXT,
          source TEXT DEFAULT 'manual'
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS fiscal_years (
          id TEXT PRIMARY KEY,
          name TEXT,
          start_date TEXT,
          end_date TEXT,
          is_closed INTEGER DEFAULT 0,
          closing_entry_id TEXT,
          created_at TEXT
        )
      ''');
    }

    if (oldVersion < 50) {
      // Fix Pluralization and Sync Status integrity
      try {
        await db.execute("ALTER TABLE asset_custody_log RENAME TO asset_custody_logs");
      } catch (_) {}
      
      // Migration for sync_status (string 'pending' to integer 0)
      // This is a global fix for any table that might have used the old string constant
      final tablesToFix = ['draft_invoices', 'tasks', 'system_users', 'commissions'];
      for (var table in tablesToFix) {
        try {
          await db.execute("UPDATE $table SET sync_status = 0 WHERE sync_status = 'pending'");
        } catch (_) {}
      }
    }

    if (oldVersion < 56) {
      // Phase 14: Enterprise Security & Performance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_audit (
          id TEXT PRIMARY KEY,
          action_type TEXT,
          description TEXT,
          is_critical INTEGER DEFAULT 0,
          old_value TEXT,
          new_value TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT
        )
      ''');

      // Ensure inventory_transactions exists before indexing (fix for regression in v54-55)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_transactions (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          item_name TEXT,
          type TEXT,
          quantity REAL,
          reference_id TEXT,
          date TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // Performance Indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(issue_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_client ON invoices(client_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_logs(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_items_sku ON items(sku)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_tx_item ON inventory_transactions(item_id)');
    }

    if (oldVersion < 57) {
      // ══════════════════════════════════════════════════════════════════
      // v57: Comprehensive Schema Audit Fix
      // Fixes missing columns/tables discovered during production testing
      // ══════════════════════════════════════════════════════════════════

      // 1. Ensure 'documents' table exists (might be missing for users
      //    who upgraded through v48 with an already-existing DB)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          id TEXT PRIMARY KEY,
          owner_type TEXT,
          owner_id TEXT,
          name TEXT,
          file_path TEXT,
          file_type TEXT,
          expiry_date TEXT,
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 2. Fix security_audit: add missing columns from v35→v56 schema conflict
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN old_value TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN new_value TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN description TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN is_critical INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN device_id TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN updated_at TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN is_deleted INTEGER DEFAULT 0'); } catch (_) {}

      // 3. Add sync_status + device_id + updated_at to tables missing them
      final tablesNeedingSyncColumns = [
        'leave_requests',
        'employee_loans',
        'real_estate_units',
        'real_estate_contracts',
        'investments',
        'liquidation_requests',
        'sales_targets',
        'sales_agents',
      ];
      for (final table in tablesNeedingSyncColumns) {
        try { await db.execute('ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN device_id TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT'); } catch (_) {}
      }

      // 4. Ensure 'commissions' table exists with proper schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commissions (
          id TEXT PRIMARY KEY,
          agent_id TEXT,
          invoice_id TEXT,
          amount REAL,
          rate REAL,
          status TEXT DEFAULT 'pending',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 5. Ensure 'job_applications' table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS job_applications (
          id TEXT PRIMARY KEY,
          candidate_name TEXT,
          position TEXT,
          email TEXT,
          phone TEXT,
          status TEXT DEFAULT 'pending',
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 6. Add closing_date to companies if missing
      try { await db.execute('ALTER TABLE companies ADD COLUMN closing_date TEXT'); } catch (_) {}
    }

    if (oldVersion < 58) {
      // ══════════════════════════════════════════════════════════════════
      // v58: Schema Repair for Real Data Entry
      // Fixes 'table invoice_lines has no column named total'
      // ══════════════════════════════════════════════════════════════════
      
      // Fix invoice_lines
      try { await db.execute('ALTER TABLE invoice_lines ADD COLUMN item_id TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE invoice_lines ADD COLUMN total REAL DEFAULT 0'); } catch (_) {}

      // Fix purchase_invoice_lines
      try { await db.execute('ALTER TABLE purchase_invoice_lines ADD COLUMN total REAL DEFAULT 0'); } catch (_) {}
      
      debugPrint("✅ Database Migrated to v58: invoice_lines schema repaired.");
    }

    if (oldVersion < 59) {
      // ══════════════════════════════════════════════════════════════════
      // v59: Global Sync Schema Sweeper
      // Ensures ALL sync tables have required metadata columns
      // ══════════════════════════════════════════════════════════════════
      
      const List<String> syncTables = [
        'companies', 'clients', 'items', 'invoices', 'invoice_lines',
        'purchase_invoices', 'purchase_invoice_lines', 'journal_entries',
        'journal_entry_lines', 'accounts', 'employees', 'salary_payments',
        'salary_slips', 'attendance_logs', 'leave_requests', 'employee_loans',
        'suppliers', 'payments', 'cost_centers', 'projects', 'budgets',
        'assets', 'asset_depreciation_logs', 'warehouses', 'inventory_batches',
        'inventory_transfers', 'bom', 'bom_lines', 'manufacturing_orders',
        'cheques', 'financial_custodies', 'asset_custody_logs', 'money_transfers',
        'real_estate_units', 'real_estate_contracts', 'investments',
        'investment_transactions', 'sales_targets', 'commissions',
        'job_applications', 'system_users', 'security_audit',
        'performance_reviews', 'employee_contracts',
      ];

      for (final table in syncTables) {
        try { await db.execute('ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN device_id TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN is_deleted INTEGER DEFAULT 0'); } catch (_) {}
      }
      
      debugPrint("✅ Database Migrated to v59: Global sync schema sweep completed.");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Standard Metadata columns for ALL tables in v35
    const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';

    await db.execute('''
      CREATE TABLE companies (
        id TEXT PRIMARY KEY,
        name TEXT,
        industry_type TEXT,
        cr_number TEXT,
        vat_number TEXT,
        address TEXT,
        currency TEXT,
        country TEXT,
        tax_rate REAL,
        logo_path TEXT,
        letterhead_path TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT,
        cr_number TEXT,
        tax_id TEXT,
        address TEXT,
        user_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT,
        industry_type TEXT,
        base_price REAL,
        cost_price REAL DEFAULT 0,
        tax_type TEXT,
        quantity REAL DEFAULT 0,
        sku TEXT,
        barcode TEXT,
        min_stock_level REAL DEFAULT 0,
        lead_time INTEGER DEFAULT 3,
        user_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        issue_date TEXT,
        client_id TEXT,
        subtotal REAL,
        tax_amount REAL,
        total REAL,
        status TEXT,
        payment_type TEXT DEFAULT 'cash',
        due_date TEXT,
        user_id TEXT,
        project_id TEXT,
        shift_id TEXT,
        is_return INTEGER DEFAULT 0,
        attachment_path TEXT,
        sales_agent_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE security_audit (
        id TEXT PRIMARY KEY,
        action_type TEXT,
        description TEXT,
        is_critical INTEGER DEFAULT 0,
        old_value TEXT,
        new_value TEXT,
        $metadata
      )
    ''');
    
    await db.execute('''
      CREATE TABLE warehouses (
        id TEXT PRIMARY KEY,
        name TEXT,
        location TEXT,
        cost_center_id TEXT,
        $metadata
      )
    ''');
    
    await db.execute('''
      CREATE TABLE inventory_batches (
        id TEXT PRIMARY KEY,
        item_id TEXT,
        warehouse_id TEXT,
        quantity REAL DEFAULT 0,
        expiry_date TEXT,
        batch_number TEXT,
        $metadata
      )
    ''');
      
    await db.execute('''
      CREATE TABLE inventory_transfers (
        id TEXT PRIMARY KEY,
        item_id TEXT,
        from_warehouse_id TEXT,
        to_warehouse_id TEXT,
        quantity REAL,
        date TEXT,
        status TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_lines (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        item_id TEXT,
        name TEXT,
        quantity REAL,
        price_at_sale REAL,
        total REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_invoice_lines (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        item_id TEXT,
        name TEXT,
        quantity REAL,
        price_at_purchase REAL,
        total REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT,
        deadline TEXT,
        status TEXT,
        user_id TEXT,
        $metadata
      )
    ''');
    
    await db.execute('''
      CREATE TABLE channels (
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        created_at TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        channel_id TEXT,
        sender_id TEXT,
        sender_name TEXT,
        content TEXT,
        created_at TEXT,
        is_task INTEGER DEFAULT 0,
        task_id TEXT,
        $metadata
      )
    ''');
    
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        cashier_id TEXT,
        start_time TEXT,
        end_time TEXT,
        opening_balance REAL DEFAULT 0,
        closing_balance REAL DEFAULT 0,
        status TEXT DEFAULT 'open',
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        code TEXT,
        name TEXT,
        type TEXT,
        balance REAL DEFAULT 0,
        parent_id TEXT,
        $metadata
      )
    ''');
    
    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT,
        barcode TEXT,
        serial_number TEXT,
        location TEXT,
        image_path TEXT,
        cost_price REAL DEFAULT 0,
        status TEXT,
        assigned_to TEXT,
        purchase_date TEXT,
        useful_life_months INTEGER DEFAULT 60,
        salvage_value REAL DEFAULT 0,
        depreciation_method TEXT DEFAULT 'straight_line',
        last_depreciation_date TEXT,
        cost_center_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT,
        description TEXT,
        reference_id TEXT,
        attachment_path TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entry_lines (
        id TEXT PRIMARY KEY,
        entry_id TEXT,
        account_id TEXT,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        project_id TEXT,
        cost_center_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY,
        name TEXT,
        job_title TEXT,
        basic_salary REAL,
        hiring_date TEXT,
        housing_allowance REAL DEFAULT 0,
        transport_allowance REAL DEFAULT 0,
        insurance_deduction REAL DEFAULT 0,
        bank_name TEXT,
        iban TEXT,
        cost_center_id TEXT,
        manager_id TEXT,
        nationality TEXT,
        phone TEXT,
        email TEXT,
        id_number TEXT,
        id_expiry_date TEXT,
        passport_number TEXT,
        passport_expiry_date TEXT,
        insurance_number TEXT,
        emergency_phone TEXT,
        department TEXT,
        personal_email TEXT,
        employee_id TEXT,
        status TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE salary_payments (
        id TEXT PRIMARY KEY,
        employee_id TEXT,
        pay_period TEXT,
        amount REAL,
        payment_date TEXT,
        project_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_logs (
        id TEXT PRIMARY KEY,
        employee_id TEXT,
        date TEXT,
        status TEXT,
        notes TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE salary_slips (
        id TEXT PRIMARY KEY,
        employee_id TEXT,
        month TEXT,
        basic_salary REAL,
        housing_allowance REAL,
        transport_allowance REAL,
        overtime REAL DEFAULT 0,
        custom_earnings REAL DEFAULT 0,
        insurance_deduction REAL,
        tax_deduction REAL DEFAULT 0,
        absence_deduction REAL,
        loan_deduction REAL DEFAULT 0,
        custom_deductions REAL DEFAULT 0,
        net_salary REAL,
        payment_date TEXT,
        entry_id TEXT,
        status TEXT DEFAULT 'paid',
        payment_status TEXT DEFAULT 'draft',
        cost_center_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT,
        contact_info TEXT,
        tax_id TEXT,
        balance REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_invoices (
        id TEXT PRIMARY KEY,
        issue_date TEXT,
        supplier_id TEXT,
        subtotal REAL,
        tax_amount REAL,
        total REAL,
        payment_type TEXT DEFAULT 'credit',
        project_id TEXT,
        due_date TEXT,
        cost_center_id TEXT,
        is_return INTEGER DEFAULT 0,
        attachment_path TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        partner_id TEXT,
        partner_type TEXT,
        amount REAL,
        type TEXT,
        date TEXT,
        attachment_path TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE cost_centers (
        id TEXT PRIMARY KEY,
        name TEXT,
        code TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT,
        budget_amount REAL DEFAULT 0,
        cost_center_id TEXT,
        start_date TEXT,
        end_date TEXT,
        status TEXT DEFAULT 'active',
        manager_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_custody_logs (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        employee_id TEXT,
        issued_date TEXT,
        returned_date TEXT,
        status TEXT,
        notes TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_schedules (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        scheduled_date TEXT,
        reason TEXT,
        status TEXT,
        total_cost REAL DEFAULT 0,
        linked_invoice_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE damage_reports (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        employee_id TEXT,
        date TEXT,
        damage_reason TEXT,
        value_loss REAL,
        entry_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE money_transfers (
        id TEXT PRIMARY KEY,
        from_account_id TEXT,
        to_account_id TEXT,
        amount REAL,
        fee REAL DEFAULT 0,
        date TEXT,
        attachment_path TEXT,
        notes TEXT,
        reconciled INTEGER DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_invoices (
        id TEXT PRIMARY KEY,
        date TEXT,
        supplier_name TEXT,
        total_amount REAL,
        attachment_path TEXT,
        status INTEGER DEFAULT 0,
        raw_ocr_json TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        account_id TEXT,
        project_id TEXT,
        allocated_amount REAL,
        period TEXT,
        created_at TEXT,
        cost_center_id TEXT,
        $metadata
      )
    ''');

    // v48: System Users & Tasks & Documents
    await db.execute('''
      CREATE TABLE system_users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        name TEXT,
        email TEXT,
        password_hash TEXT,
        employee_id TEXT,
        role TEXT DEFAULT 'employee',
        avatar_url TEXT,
        is_active INTEGER DEFAULT 1,
        permissions TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        assigned_to TEXT,
        assigned_by TEXT,
        due_date TEXT,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        project_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        owner_type TEXT, -- 'employee', 'company', 'asset'
        owner_id TEXT,
        name TEXT,
        file_path TEXT,
        file_type TEXT,
        expiry_date TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // v49: Advanced Accounting
    await db.execute('''
      CREATE TABLE quotations (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        client_name TEXT,
        issue_date TEXT,
        expiry_date TEXT,
        subtotal REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total REAL DEFAULT 0,
        status TEXT DEFAULT 'draft',
        notes TEXT,
        converted_invoice_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE quotation_lines (
        id TEXT PRIMARY KEY,
        quotation_id TEXT,
        item_id TEXT,
        name TEXT,
        quantity REAL,
        price REAL,
        tax_rate REAL DEFAULT 0,
        total REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE receipt_vouchers (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        client_name TEXT,
        amount REAL,
        payment_method TEXT,
        bank_account_id TEXT,
        invoice_id TEXT,
        date TEXT,
        notes TEXT,
        journal_entry_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_vouchers (
        id TEXT PRIMARY KEY,
        supplier_id TEXT,
        supplier_name TEXT,
        amount REAL,
        payment_method TEXT,
        bank_account_id TEXT,
        invoice_id TEXT,
        date TEXT,
        notes TEXT,
        journal_entry_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE credit_notes (
        id TEXT PRIMARY KEY,
        original_invoice_id TEXT,
        client_id TEXT,
        amount REAL,
        reason TEXT,
        date TEXT,
        journal_entry_id TEXT,
        status TEXT DEFAULT 'draft',
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        type TEXT, -- 'invoice', 'expense', 'journal'
        template_data TEXT, -- JSON
        frequency TEXT, -- 'daily', 'weekly', 'monthly', 'yearly'
        next_run_date TEXT,
        last_run_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_trail (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        user_name TEXT,
        action TEXT, -- 'create', 'update', 'delete', 'login', 'logout'
        entity_type TEXT, -- 'invoice', 'employee', 'journal', etc
        entity_id TEXT,
        old_value TEXT, -- JSON
        new_value TEXT, -- JSON
        ip_address TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE currency_rates (
        id TEXT PRIMARY KEY,
        from_currency TEXT,
        to_currency TEXT,
        rate REAL,
        date TEXT,
        source TEXT DEFAULT 'manual'
      )
    ''');

    await db.execute('''
      CREATE TABLE fiscal_years (
        id TEXT PRIMARY KEY,
        name TEXT,
        start_date TEXT,
        end_date TEXT,
        is_closed INTEGER DEFAULT 0,
        closing_entry_id TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_depreciation_logs (
        id TEXT PRIMARY KEY,
        asset_id TEXT,
        date TEXT,
        amount REAL,
        entry_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE bom (
        id TEXT PRIMARY KEY,
        finished_good_item_id TEXT,
        name TEXT,
        description TEXT,
        estimated_overhead_cost REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE bom_lines (
        id TEXT PRIMARY KEY,
        bom_id TEXT,
        raw_material_item_id TEXT,
        quantity_required REAL,
        waste_percentage REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE manufacturing_orders (
        id TEXT PRIMARY KEY,
        bom_id TEXT,
        status TEXT DEFAULT 'draft',
        qty_to_produce REAL,
        start_date TEXT,
        end_date TEXT,
        actual_material_cost REAL DEFAULT 0,
        actual_overhead_cost REAL DEFAULT 0,
        total_cost REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE cheques (
        id TEXT PRIMARY KEY,
        cheque_number TEXT,
        bank_name TEXT,
        amount REAL,
        issue_date TEXT,
        due_date TEXT,
        type TEXT,
        partner_id TEXT,
        partner_name TEXT,
        partner_type TEXT,
        status TEXT,
        journal_entry_id TEXT,
        notes TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_custodies (
        id TEXT PRIMARY KEY,
        employee_id TEXT,
        employee_name TEXT,
        amount REAL,
        issue_date TEXT,
        reason TEXT,
        status TEXT,
        journal_entry_issue TEXT,
        journal_entry_clear TEXT,
        clearance_date TEXT,
        notes TEXT,
        $metadata
      )
    ''');
    
    // v42 & Advanced Tables
    await db.execute('''
      CREATE TABLE sales_targets (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        employee_id TEXT,
        target_amount REAL,
        achieved_amount REAL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT,
        $metadata
      )
    ''');
    await db.execute('''
      CREATE TABLE commissions (
        id TEXT PRIMARY KEY,
        employee_id TEXT,
        invoice_id TEXT,
        amount REAL,
        percentage REAL,
        status TEXT DEFAULT 'PENDING',
        created_at TEXT,
        $metadata
      )
    ''');
    await db.execute('''
      CREATE TABLE promotional_campaigns (
        id TEXT PRIMARY KEY,
        item_id TEXT,
        discount_type TEXT,
        discount_value REAL,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        $metadata
      )
    ''');
    await db.execute('''
      CREATE TABLE job_applications (
        id TEXT PRIMARY KEY,
        applicant_name TEXT,
        phone TEXT,
        position TEXT,
        cv_path TEXT,
        status TEXT DEFAULT 'NEW',
        interview_date TEXT,
        created_at TEXT,
        $metadata
      )
    ''');

    // 🌟 THE MAGIC SPRINT FIX 🌟
    // Apply all iterative upgrades to guarantee no table is left behind!
    await _onUpgrade(db, 0, version);

    await _seedDefaultAccounts(db); 
    await _seedDefaultCostCenters(db);
  }

  static Future<void> _seedDefaultAccounts(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM accounts');
    if ((count.first['count'] as int) == 0) {
      // Use general template for initial seeding if empty
      final templateAccounts = COATemplate.getTemplateAccounts(IndustryType.general);
      for (var account in templateAccounts) {
        await db.insert('accounts', {
          'id': account['id'] ?? 'ACC_${account['code']}',
          'code': account['code'],
          'name': account['name'],
          'type': account['type'],
          'sync_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
          'device_id': 'system_seed',
          'is_deleted': 0
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  /// Checks if industry can be changed (i.e., no financial transactions exist)
  Future<bool> canChangeIndustry() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM journal_entries');
    return (count.first['count'] as int) == 0;
  }

  /// Seeds industry-specific accounts after clearing existing ones (if safe)
  Future<void> seedIndustryAccounts(IndustryType type) async {
    final db = await database;
    
    // 1. Logic Check (Senior Level Requirement)
    if (!await canChangeIndustry()) {
      throw Exception('TRANSACTIONS_EXIST');
    }

    try {
      await db.transaction((txn) async {
        // 2. Clear existing accounts safely
        await txn.delete('accounts');

        // 3. Get specialized template
        final templateAccounts = COATemplate.getTemplateAccounts(type);
        
        // 4. Batch Insert (Production Ready with Metadata)
        final String now = DateTime.now().toIso8601String();
        for (var account in templateAccounts) {
          await txn.insert('accounts', {
            'id': account['id'] ?? 'ACC_${account['code']}',
            'code': account['code'],
            'name': account['name'],
            'type': account['type'],
            'sync_status': 'pending',
            'updated_at': now,
            'device_id': 'onboarding_init',
            'is_deleted': 0
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      print('Database Seeding Error: $e');
      rethrow;
    }
  }

  // --- Utility for Current Company Context & Settings ---
  
  // --- Database Logic (CRUD) ---

  Future<void> _seedDefaultCostCenters(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM cost_centers');
    if ((count.first['count'] as int) == 0) {
      await db.insert('cost_centers', {'id': 'CC_MAIN', 'name': 'المركز الرئيسي', 'code': '100'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_SALES', 'name': 'قسم المبيعات', 'code': '200'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static const String _companyIdKey = 'current_company_id';
  static const String _industryTypeKey = 'current_industry_type';
  static const String _taxRateKey = 'current_tax_rate';
  static const String _currencyKey = 'current_currency';
  static const String _countryKey = 'current_country';
  static const String _logoPathKey = 'current_company_logo';
  static const String _vatNumberKey = 'current_vat_number'; 
  static const String _addressKey = 'current_address'; 
  static const String _closingDateKey = 'current_closing_date';
  static const String _lastSyncKey = 'last_sync_timestamp';

  Future<String> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey) ?? '1970-01-01T00:00:00Z';
  }

  Future<void> setLastSyncTimestamp(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, timestamp);
  }

  Future<void> setCurrentCompany(String companyId, String industryType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyIdKey, companyId);
    await prefs.setString(_industryTypeKey, industryType);
  }

  Future<void> setCompanySettings({
    required double taxRate,
    required String currency,
    required String country,
    String? vatNumber,
    String? address,
    String? logoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_taxRateKey, taxRate);
    await prefs.setString(_currencyKey, currency);
    await prefs.setString(_countryKey, country);
    if (vatNumber != null) await prefs.setString(_vatNumberKey, vatNumber);
    if (address != null) await prefs.setString(_addressKey, address);
    if (logoPath != null) await prefs.setString(_logoPathKey, logoPath);
  }

  Future<void> setClosingDate(String? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (date == null) {
      await prefs.remove(_closingDateKey);
    } else {
      await prefs.setString(_closingDateKey, date);
    }
  }

  Future<String?> getClosingDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_closingDateKey);
  }

  Future<bool> isDateLocked(String dateStr) async {
    final closingDateStr = await getClosingDate();
    if (closingDateStr == null) return false;
    
    try {
      final date = DateTime.parse(dateStr);
      final closingDate = DateTime.parse(closingDateStr);
      // Locked if the target date is on or before the closing date
      return date.isBefore(closingDate) || date.isAtSameMomentAs(closingDate);
    } catch (_) {
      return false;
    }
  }

  String _sanitizeCountry(String? country) {
    if (country == null) return 'Saudi Arabia';
    final map = {
      'السعودية': 'Saudi Arabia',
      'مصر': 'Egypt',
      'الكويت': 'Kuwait',
      'الامارات': 'UAE',
      'الاردن': 'Jordan',
    };
    return map[country] ?? country;
  }

  String _sanitizeCurrency(String? currency) {
    if (currency == null) return 'sar';
    final map = {
      'ر.س': 'sar',
      'ج.م': 'egp',
      'د.ك': 'kwd',
    };
    return map[currency] ?? currency;
  }

  Future<Map<String, dynamic>> getCurrentCompanyContext() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCurrency = prefs.getString(_currencyKey);
    final rawCountry = prefs.getString(_countryKey);
    
    return {
      'company_id': prefs.getString(_companyIdKey) ?? 'DEMO_COMP',
      'industry_type': prefs.getString(_industryTypeKey) ?? 'عام',
      'tax_rate': prefs.getDouble(_taxRateKey) ?? 14.0,
      'currency': _sanitizeCurrency(rawCurrency),
      'country': _sanitizeCountry(rawCountry),
      'vat_number': prefs.getString(_vatNumberKey) ?? '300000000000003',
      'address': prefs.getString(_addressKey) ?? 'الرياض، المملكة العربية السعودية',
      'logo_path': prefs.getString(_logoPathKey),
      'name': prefs.getString(_companyIdKey) ?? 'مؤسسة الرياض التجارية',
    };
  }

  Future<void> saveInvoiceWithLines({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> lines,
    String? paymentAccountId,
  }) async {
    // 🛡️ QuickBooks Rule: Check if the period is closed
    if (await isDateLocked(invoice['issue_date'] ?? '')) {
      throw Exception("لا يمكن إضافة فاتورة في فترة محاسبية مغلقة (حتى تاريخ الإغلاق).");
    }
    final db = await database;
    await db.transaction((txn) async {
      // Use provided account or default to Cash
      final String finalAccount = paymentAccountId ?? (invoice['payment_type'] == 'credit' ? 'ACC_RECEIVABLE' : 'ACC_CASH');

      final nowStr = DateTime.now().toIso8601String();
      final deviceId = await getDeviceFingerprint();

      // 1. Insert Invoice Header with Sync Metadata
      await txn.insert('invoices', {
        ...invoice,
        'sync_status': 0,
        'updated_at': nowStr,
        'device_id': deviceId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
      // 2. Insert Invoice Lines and deduct inventory
      double totalCogs = 0.0;
      for (var line in lines) {
        await txn.insert('invoice_lines', line, conflictAlgorithm: ConflictAlgorithm.replace);
        
        // Fetch cost_price from items table to calculate COGS
        final itemRes = await txn.query('items', columns: ['cost_price'], where: 'name = ?', whereArgs: [line['name']]);
        if (itemRes.isNotEmpty) {
           final double unitCost = (itemRes.first['cost_price'] as num?)?.toDouble() ?? 0.0;
           totalCogs += unitCost * (line['quantity'] as num).toDouble();
        }

        // 3. Inventory Sync
        
        // 3. Inventory Sync & Logging (Phase 7.2)
        await txn.rawUpdate(
          'UPDATE items SET quantity = quantity - ? WHERE name = ?',
          [line['quantity'], line['name']]
        );

        await txn.insert('inventory_transactions', {
          'id': 'ITX_${DateTime.now().microsecondsSinceEpoch}',
          'item_id': line['item_id'] ?? line['name'],
          'item_name': line['name'],
          'type': 'sale',
          'quantity': -(line['quantity'] as num).toDouble(),
          'reference_id': invoice['id'],
          'date': invoice['issue_date'] ?? nowStr,
          'created_at': nowStr,
          'updated_at': nowStr,
        });

      }

      // 4. GENERATE JOURNAL ENTRY
      final String entryId = "JE_${DateTime.now().millisecondsSinceEpoch}";
      final String invoiceId = invoice['id'];
      
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': invoice['issue_date']?.split('T')?[0] ?? nowStr.split('T')[0],
        'description': "تسجيل مبيعات الفاتورة رقم $invoiceId",
        'reference_id': invoiceId,
        'attachment_path': invoice['attachment_path'],
        'sync_status': 0,
        'updated_at': nowStr,
        'device_id': deviceId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final double total = invoice['total'] ?? 0.0;
      final double subtotal = invoice['subtotal'] ?? 0.0;
      final double taxAmount = invoice['tax_amount'] ?? 0.0;

      // Line 1: Debit Selected Account (Asset)
      await txn.insert('journal_entry_lines', {
        'id': "${entryId}_L1",
        'entry_id': entryId,
        'account_id': finalAccount,
        'debit': total,
        'credit': 0.0,
        'project_id': invoice['project_id'],
        'cost_center_id': invoice['cost_center_id'],
      });

      // Line 2: Credit Sales Revenue
      await txn.insert('journal_entry_lines', {
        'id': "${entryId}_L2",
        'project_id': invoice['project_id'],
        'cost_center_id': invoice['cost_center_id'],
        'entry_id': entryId,
        'account_id': 'ACC_SALES',
        'debit': 0.0,
        'credit': subtotal,
      });

      // Line 3: Credit VAT
      if (taxAmount > 0) {
        await txn.insert('journal_entry_lines', {
          'id': "${entryId}_L3",
        'project_id': invoice['project_id'],
        'cost_center_id': invoice['cost_center_id'],
          'entry_id': entryId,
          'account_id': 'ACC_VAT',
          'debit': 0.0,
          'credit': taxAmount,
        });
      }

      // COGS Entry
      if (totalCogs > 0) {
         await txn.insert('journal_entry_lines', { 'id': "${entryId}_L4",
        'project_id': invoice['project_id'],
        'cost_center_id': invoice['cost_center_id'], 'entry_id': entryId, 'account_id': 'ACC_COGS', 'debit': totalCogs, 'credit': 0.0 });
         await txn.insert('journal_entry_lines', { 'id': "${entryId}_L5",
        'project_id': invoice['project_id'],
        'cost_center_id': invoice['cost_center_id'], 'entry_id': entryId, 'account_id': 'ACC_INVENTORY', 'debit': 0.0, 'credit': totalCogs });
         await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [totalCogs, 'ACC_COGS']);
         await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [totalCogs, 'ACC_INVENTORY']);
      }

      // Update balances
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [total, finalAccount]);
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [subtotal, 'ACC_SALES']);
      if (taxAmount > 0) await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [taxAmount, 'ACC_VAT']);
    });
  }

  // --- Process Payment (Pay to Supplier / Receive from Client) ---
  Future<void> processPayment({
    required String partnerId,
    required String partnerType, // 'client' or 'supplier'
    required double amount,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      
      final paymentId = "PMT_${DateTime.now().millisecondsSinceEpoch}";
      final String dateIso = DateTime.now().toIso8601String();
      
      final nowStr = DateTime.now().toIso8601String();
      final deviceId = await getDeviceFingerprint();

      await txn.insert('payments', {
        'id': paymentId,
        'partner_id': partnerId,
        'partner_type': partnerType,
        'amount': amount,
        'type': partnerType == 'supplier' ? 'pay' : 'receive',
        'date': dateIso,
        'sync_status': 0,
        'updated_at': nowStr,
        'device_id': deviceId,
      });

      // التحقق من المعاملات الكبيرة للتنبيه (Phase 4)
      if (amount >= 5000) {
        NotificationService().notifySensitiveAction("معاملة مالية كبيرة", "تم تسجيل $partnerType بقيمة $amount للطرف $partnerId");
      }

      final entryId = "JE_PMT_$paymentId";
      
      if (partnerType == 'supplier') { // Payment TO Supplier
        final nowStr = DateTime.now().toIso8601String();
        final deviceId = await getDeviceFingerprint();

        await txn.insert('journal_entries', {
          'id': entryId,
          'date': dateIso,
          'description': "سداد دفعة نقدية لمورد ($partnerId)",
          'reference_id': paymentId,
          'sync_status': 0,
          'updated_at': nowStr,
          'device_id': deviceId,
        });
        
        // Debit Payable (Liability goes down)
        await txn.insert('journal_entry_lines', { 'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_PAYABLE', 'debit': amount, 'credit': 0.0 });
        // Credit Cash (Asset goes down)
        await txn.insert('journal_entry_lines', { 'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': 'ACC_CASH', 'debit': 0.0, 'credit': amount });
        
        // Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_PAYABLE']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_CASH']);
        await txn.rawUpdate('UPDATE suppliers SET balance = balance - ? WHERE id = ?', [amount, partnerId]);
        
      } else { // Receive FROM Client
        final nowStr = DateTime.now().toIso8601String();
        final deviceId = await getDeviceFingerprint();

        await txn.insert('journal_entries', {
          'id': entryId,
          'date': dateIso,
          'description': "تحصيل دفعة نقدية من عميل ($partnerId)",
          'reference_id': paymentId,
          'sync_status': 0,
          'updated_at': nowStr,
          'device_id': deviceId,
        });
        
        // Debit Cash (Asset goes up)
        await txn.insert('journal_entry_lines', { 'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_CASH', 'debit': amount, 'credit': 0.0 });
        // Credit Receivable (Asset goes down)
        await txn.insert('journal_entry_lines', { 'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': 'ACC_RECEIVABLE', 'debit': 0.0, 'credit': amount });
        
        // Update Balances
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, 'ACC_CASH']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_RECEIVABLE']);
      }
    });

    // Sync on Save
    SyncService().performFullSync();
  }

  Future<void> seedDemoProducts() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM items');
    if ((count.first['count'] as int) == 0) {
      await db.execute("INSERT INTO items (id, name, base_price, cost_price, quantity, tax_type, min_stock_level, lead_time) VALUES ('ITM1', 'ورق طباعة A4', 120.0, 80.0, 15.0, '15%', 10.0, 3)");
      await db.execute("INSERT INTO items (id, name, base_price, cost_price, quantity, tax_type, min_stock_level, lead_time) VALUES ('ITM2', 'أحبار HP 652', 450.0, 320.0, 2.0, '15%', 5.0, 5)");
      await db.execute("INSERT INTO items (id, name, base_price, cost_price, quantity, tax_type, min_stock_level, lead_time) VALUES ('ITM3', 'ماوس احترافي', 85.0, 45.0, 40.0, '15%', 5.0, 2)");
      
      // Seed Demo Clients/Suppliers for Lifecycle Testing
      await db.execute("INSERT INTO clients (id, name, cr_number) VALUES ('CLI_001', 'مؤسسة الحلول الذكية', '1010000123')");
      await db.execute("INSERT INTO suppliers (id, name, balance) VALUES ('SUP_001', 'شركة توريدات الحاسب', 5000.0)");
      await db.execute("INSERT INTO cost_centers (id, name, code) VALUES ('CC_001', 'المقر الرئيسي', 'HQ')");
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({String? query}) async {
    final db = await database;
    if (query == null || query.isEmpty) {
      return await db.query('items');
    }
    return await db.query('items', where: 'name LIKE ?', whereArgs: ['%$query%']);
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return await db.query('clients');
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await database;
    return await db.query('suppliers');
  }

  // Alias for getProducts
  Future<List<Map<String, dynamic>>> getItems() => getProducts();

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('items', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.update(
      'items',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
    await AuditService.log(action: 'delete', entityType: 'product', entityId: id);
  }

  Future<String> insertLocalInvoice(Map<String, dynamic> invoiceData) async {
    final db = await database;
    final id = invoiceData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    invoiceData['id'] = id;
    invoiceData['sync_status'] = 'pending_sync';
    await db.insert('invoices', invoiceData, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<int> insertLocalInvoiceLine(Map<String, dynamic> lineData) async {
    final db = await database;
    final id = lineData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    lineData['id'] = id;
    return await db.insert('invoice_lines', lineData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingInvoices() async {
    final db = await database;
    return await db.query('invoices', where: 'sync_status = ?', whereArgs: ['pending_sync']);
  }

  Future<void> markInvoiceSynced(String id) async {
    final db = await database;
    await db.update('invoices', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [id]);
  }

  // --- الرقابة الأمنية وبصمة الجهاز (Phase 4) ---

  Future<List<Map<String, dynamic>>> getSecurityAuditLogs() async {
    final db = await database;
    // جلب آخر 50 حركة حساسة + التنبيهات الأمنية الفورية مع بصمة الجهاز
    return await db.rawQuery('''
      SELECT 'تنبيه أمني' as action_type, description, updated_at, device_id FROM security_audit
      UNION ALL
      SELECT 'فاتورة مبيعات' as action_type, 'رقم: ' || id || ' - بقيمة: ' || total as description, updated_at, device_id FROM invoices
      UNION ALL
      SELECT 'فاتورة مشتريات' as action_type, 'رقم: ' || id || ' - بقيمة: ' || total as description, updated_at, device_id FROM purchase_invoices
      UNION ALL
      SELECT 'حركة شيك' as action_type, 'شيك رقم: ' || cheque_number || ' - ' || status as description, updated_at, device_id FROM cheques
      UNION ALL
      SELECT 'صرف عهدة' as action_type, 'للموظف: ' || employee_name || ' - مبلغ: ' || amount as description, updated_at, device_id FROM financial_custodies
      UNION ALL
      SELECT 'عملية دفع' as action_type, 'مبلغ: ' || amount || ' - نوع: ' || type as description, updated_at, device_id FROM payments
      UNION ALL
      SELECT 'شؤون موظفين' as action_type, 'تعديل بيانات الموظف: ' || name as description, updated_at, device_id FROM employees
      ORDER BY updated_at DESC
      LIMIT 50
    ''');
  }

  // --- Statistics for Dashboard ---

  // --- Statistics for Dashboard (v14) ---
  
  Future<Map<String, double>> getCEOStats(String startDate, String endDate) async {
    final db = await database;

    // 1. Profit (Revenue - COGS - Expenses)
    final pnl = await getPNLSummary(startDate, endDate);
    double profit = pnl['net_profit'] ?? 0.0;

    // 2. Liquidity (Bank + Cash)
    final accounts = await db.query('accounts', 
      where: 'id LIKE ? OR id LIKE ? OR id = ?', 
      whereArgs: ['%BANK%', '%CASH%', 'ACC_CASH']);
    double liquidity = accounts.fold(0.0, (sum, acc) => sum + ((acc['balance'] as num?) ?? 0.0).toDouble());

    // 3. Inventory Value (Quantity * Cost)
    double inventoryVal = await getInventoryValue();

    // 4. Expenses (Sum of specific expense types in period)
    double expenses = (pnl['general_expenses'] ?? 0.0) + (pnl['salaries'] ?? 0.0);

    return {
      'profit': profit,
      'liquidity': liquidity,
      'inventory': inventoryVal,
      'expenses': expenses,
      'revenue': pnl['revenue'] ?? 0.0,
    };
  }

  Future<double> getInventoryValue() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(quantity * cost_price) as total FROM items');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getMonthlyAnalytics(String startDate, String endDate) async {
    final db = await database;
    
    // Grouping by DATE to aggregate multiple invoices in the same day
    final sales = await db.rawQuery('''
      SELECT DATE(issue_date) as date, SUM(total) as amount FROM invoices 
      WHERE issue_date BETWEEN ? AND ? 
      GROUP BY DATE(issue_date) ORDER BY DATE(issue_date) ASC
    ''', [startDate, endDate]);

    final purchases = await db.rawQuery('''
      SELECT DATE(issue_date) as date, SUM(total) as amount FROM purchase_invoices 
      WHERE issue_date BETWEEN ? AND ? 
      GROUP BY DATE(issue_date) ORDER BY DATE(issue_date) ASC
    ''', [startDate, endDate]);

    return [
      {'label': 'Sales', 'data': sales},
      {'label': 'Purchases', 'data': purchases},
    ];
  }
  
  Future<double> getTodaySalesTotal() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final res = await db.rawQuery('SELECT SUM(total) as total FROM invoices WHERE DATE(issue_date) = ?', [today]);
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getAccountBalance(String id) async {
    final db = await database;
    final res = await db.query('accounts', columns: ['balance'], where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return 0.0;
    return (res.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getDashboardStats() async {
    // Keep for backward compatibility or refactor to use getCEOStats
    return getCEOStats(
      DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
      DateTime.now().toIso8601String().split('T')[0]
    );
  }

  /// ⚠️ DANGER ZONE: Clears all transactional data to start fresh for "Real Data" phase.
  /// Preserves Master Data like Accounts, but resets their balances.
  Future<void> factoryReset() async {
    final db = await database;
    await db.transaction((txn) async {
      final tablesToClear = [
        'invoices', 'invoice_lines', 'purchase_invoices', 'purchase_invoice_lines',
        'journal_entries', 'journal_entry_lines', 'inventory_transactions',
        'attendance_logs', 'salary_payments', 'salary_slips', 'payments',
        'cheques', 'financial_custodies', 'damage_reports', 'maintenance_schedules',
        'money_transfers', 'draft_invoices', 'quotations', 'quotation_lines',
        'receipt_vouchers', 'payment_vouchers', 'credit_notes', 'recurring_transactions',
        'audit_trail', 'security_audit', 'leave_requests', 'employee_loans',
        'investment_transactions', 'investments', 'liquidation_requests',
        'sales_targets', 'commissions', 'job_applications', 'tasks', 'documents',
        'shifts', 'pos_sessions', 'companies' // Clearing companies triggers onboarding
      ];

      for (var table in tablesToClear) {
        try {
          await txn.delete(table);
        } catch (e) {
          debugPrint("Safe skip clearing table $table: $e");
        }
      }

      // Reset Items quantity and cost mapping
      await txn.update('items', {'quantity': 0, 'cost_price': 0});
      
      // Reset Accounts balances to zero
      await txn.update('accounts', {'balance': 0});
      
      // Clear specific master data that might be demo-only
      await txn.delete('suppliers');
      await txn.delete('clients');
    });
    
    // Clear sync metadata and other cached states if necessary
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Reset onboarding modules and other flags
  }

  Future<double> getClientBalance(String clientId) async {
    final db = await database;
    final invoicesRes = await db.query('invoices', where: 'client_id = ? AND payment_type = ?', whereArgs: [clientId, 'credit']);
    final paymentsRes = await db.query('payments', where: 'partner_id = ? AND type = ?', whereArgs: [clientId, 'receive']);
    
    double totalCredit = invoicesRes.fold(0.0, (sum, item) => sum + ((item['total'] as num?) ?? 0.0));
    double totalPaid = paymentsRes.fold(0.0, (sum, item) => sum + ((item['amount'] as num?) ?? 0.0));
    return totalCredit - totalPaid;
  }

  Future<List<Map<String, dynamic>>> getSalesByDay() async {
    final db = await database;
    // Simple grouping by date
    return await db.rawQuery('''
      SELECT substr(issue_date, 1, 10) as date, SUM(total) as total 
      FROM invoices 
      GROUP BY date 
      ORDER BY date ASC 
      LIMIT 7
    ''');
  }

  // --- HR & Payroll Methods ---

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final db = await database;
    return await db.query('employees', where: 'is_deleted = 0', orderBy: 'name ASC');
  }

  Future<void> addEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    final nowStr = DateTime.now().toIso8601String();
    
    final Map<String, dynamic> data = Map<String, dynamic>.from(employee);
    // Generate a unique id if not provided (TEXT PRIMARY KEY doesn't auto-increment)
    data['id'] ??= 'EMP_${DateTime.now().millisecondsSinceEpoch}';
    data['sync_status'] = 0;
    data['updated_at'] = nowStr;
    data['device_id'] = deviceId;
    data['is_deleted'] = 0;

    debugPrint('📝 addEmployee data keys: ${data.keys.toList()}');
    await db.insert('employees', data, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ Employee inserted into SQLite successfully');

    // Sync on Save
    SyncService().performFullSync();
  }

  Future<void> updateEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    final nowStr = DateTime.now().toIso8601String();

    final Map<String, dynamic> data = Map<String, dynamic>.from(employee);
    data['sync_status'] = 0;
    data['updated_at'] = nowStr;
    data['device_id'] = deviceId;

    await db.update(
      'employees',
      data,
      where: 'id = ?',
      whereArgs: [employee['id']],
    );

    // Sync on Save
    SyncService().performFullSync();
  }

  Future<void> deleteEmployee(String id) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    final nowStr = DateTime.now().toIso8601String();

    await db.update(
      'employees', 
      {
        'is_deleted': 1,
        'sync_status': 0,
        'updated_at': nowStr,
        'device_id': deviceId,
      }, 
      where: 'id = ?', 
      whereArgs: [id]
    );

    // تريجر التنبيه الذكي للمدير
    NotificationService().notifySensitiveAction("حذف موظف", "تم حذف الموظف رقم $id نهائياً من النظام.");

    // Sync on Save
    await AuditService.log(action: 'delete', entityType: 'employee', entityId: id);
    SyncService().performFullSync();
  }

  Future<bool> payEmployeeSalary(String employeeId, double amount, String payPeriod, String employeeName, [String? projectId]) async {
    final db = await database;
    
    // Check if already paid for this period
    final existing = await db.query('salary_payments', 
      where: 'employee_id = ? AND pay_period = ?', 
      whereArgs: [employeeId, payPeriod]);
      
    if (existing.isNotEmpty) {
      return false; // Already paid
    }

    await db.transaction((txn) async {
      // 1. Log Payment
      final paymentId = "PAY_${DateTime.now().millisecondsSinceEpoch}";
      final dateIso = DateTime.now().toIso8601String();
      await txn.insert('salary_payments', {
        'id': paymentId,
        'employee_id': employeeId,
        'pay_period': payPeriod,
        'amount': amount,
        'payment_date': dateIso,
        'project_id': projectId,
      });

      await AuditService.log(
        action: 'payroll_payment', 
        entityType: 'salary', 
        entityId: paymentId,
        description: "دفع راتب للموظف $employeeName بقيمة $amount لفترة $payPeriod",
        isCritical: true,
      );

      // 2. Generate Journal Entry
      final entryId = "JE_PAY_$paymentId";
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': dateIso,
        'description': "صرف راتب الموظف $employeeName لشهر $payPeriod",
        'reference_id': paymentId,
      });

      // Debit Expense (increase)
      await txn.insert('journal_entry_lines', {
        'id': "${entryId}_L1",
        'entry_id': entryId,
        'account_id': 'ACC_EXPENSES_SALARY', // مدين
        'debit': amount,
        'credit': 0.0,
        'project_id': projectId,
      });

      // Credit Cash (decrease asset)
      await txn.insert('journal_entry_lines', {
        'id': "${entryId}_L2",
        'entry_id': entryId,
        'account_id': 'ACC_CASH', // دائن
        'debit': 0.0,
        'credit': amount,
        'project_id': projectId,
      });

      // 3. Update Balances
      await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_CASH']);
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, 'ACC_EXPENSES_SALARY']);
    });
    
    return true;
  }

  // --- Purchase Module Integration ---
  
  Future<bool> savePurchaseInvoice({
    required String supplierId,
    required double total,
    required String paymentType,
    required List<Map<String, dynamic>> lines,
    String? paymentAccountId,
    String? attachmentPath,
    String? projectId,
    String? costCenterId,
    String? assetId,
    bool isMaintenance = false,
  }) async {
    // 🛡️ QuickBooks Rule: Check if the period is closed
    final issueDate = DateTime.now().toIso8601String().split('T')[0];
    if (await isDateLocked(issueDate)) {
      throw Exception("لا يمكن إضافة مشتريات في فترة محاسبية مغلقة.");
    }
    final db = await database;
    final invoiceId = 'PINV_${DateTime.now().millisecondsSinceEpoch}';
    
    // Default account logic
    final String finalAccount = paymentAccountId ?? (paymentType == 'cash' ? 'ACC_CASH' : 'ACC_PAYABLE');

    // Calculate Tax
    double taxRate = 0.15; 
    double subtotal = total / (1 + taxRate);
    double taxAmount = total - subtotal;

    await db.transaction((txn) async {
      await txn.insert('purchase_invoices', {
        'id': invoiceId,
        'issue_date': issueDate,
        'supplier_id': supplierId,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'total': total,
        'payment_type': paymentType,
        'attachment_path': attachmentPath,
        'project_id': projectId,
        'cost_center_id': costCenterId,
      });

      int lineCounter = 0;
      for (var line in lines) {
        lineCounter++;
        await txn.insert('purchase_invoice_lines', {
          'id': 'PIL_${DateTime.now().microsecondsSinceEpoch}_$lineCounter',
          'invoice_id': invoiceId,
          'item_id': line['item_id'],
          'name': line['name'],
          'quantity': line['quantity'],
          'price_at_purchase': line['price'],
          'total': (line['quantity'] as num).toDouble() * (line['price'] as num).toDouble(),
          'sync_status': 0,
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (line['item_id'] != null) {
           
         if (line['item_id'] != null) {
            await txn.rawUpdate('UPDATE items SET quantity = quantity + ?, cost_price = ? WHERE id = ?', [line['quantity'], line['price'], line['item_id']]);
            
            await txn.insert('inventory_transactions', {
              'id': 'PUR_ITX_${DateTime.now().microsecondsSinceEpoch}',
              'item_id': line['item_id'],
              'item_name': line['name'],
              'type': 'purchase',
              'quantity': (line['quantity'] as num).toDouble(),
              'reference_id': invoiceId,
              'date': issueDate,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
         }

        }
      }

      final entryId = 'JRN_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': issueDate,
        'description': isMaintenance ? 'فاتورة صيانة أصل ($assetId)' : 'فاتورة مشتريات رقم $invoiceId',
        'reference_id': invoiceId,
        'attachment_path': attachmentPath,
      });

      // Debit: Inventory & VAT (Or Maintenance Expense if isMaintenance)
      String debitAccount = isMaintenance ? 'ACC_EXPENSES_GENERAL' : 'ACC_INVENTORY';
      await txn.insert('journal_entry_lines', { 'id': 'JEL1_${DateTime.now().microsecondsSinceEpoch}', 'entry_id': entryId, 'account_id': debitAccount, 'debit': subtotal, 'credit': 0, 'project_id': projectId, 'cost_center_id': costCenterId });
      await txn.insert('journal_entry_lines', { 'id': 'JEL_VAT_${DateTime.now().microsecondsSinceEpoch}', 'entry_id': entryId, 'account_id': 'ACC_VAT', 'debit': taxAmount, 'credit': 0, 'project_id': projectId, 'cost_center_id': costCenterId });

      // Credit: Selected Account
      await txn.insert('journal_entry_lines', { 'id': 'JEL2_${DateTime.now().microsecondsSinceEpoch}', 'entry_id': entryId, 'account_id': finalAccount, 'debit': 0, 'credit': total, 'project_id': projectId, 'cost_center_id': costCenterId });

      // Update Balances
      if (!isMaintenance) {
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [subtotal, 'ACC_INVENTORY']);
      } else {
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [subtotal, 'ACC_EXPENSES_GENERAL']);
      }
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [taxAmount, 'ACC_VAT']); 
      
      if (finalAccount == 'ACC_PAYABLE') {
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [total, 'ACC_PAYABLE']);
        await txn.rawUpdate('UPDATE suppliers SET balance = balance + ? WHERE id = ?', [total, supplierId]);
      } else {
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [total, finalAccount]);
      }

      // If it's a maintenance invoice, link it to the asset's maintenance schedule
      if (isMaintenance && assetId != null) {
        await txn.insert('maintenance_schedules', {
          'id': 'MAINT_INV_${DateTime.now().millisecondsSinceEpoch}',
          'asset_id': assetId,
          'scheduled_date': issueDate,
          'reason': 'صيانة عبر فاتورة مشتريات $invoiceId',
          'status': 'completed',
          'total_cost': total,
          'linked_invoice_id': invoiceId,
        });
      }

      // If it's the initial purchase of an asset, link the asset to this invoice
      if (!isMaintenance && assetId != null) {
        await txn.update('assets', 
          {'purchase_invoice_id': invoiceId},
          where: 'id = ?',
          whereArgs: [assetId]
        );
      }
    });
    return true;
  }

  // --- Wallet & Bank Logic (v13) ---

  Future<void> transferFunds({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    double fee = 0,
    String? attachmentPath,
    String? notes,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
       final transferId = 'XFER_${DateTime.now().millisecondsSinceEpoch}';
       final dateStr = DateTime.now().toIso8601String().split('T')[0];

       await txn.insert('money_transfers', {
         'id': transferId,
         'from_account_id': fromAccountId,
         'to_account_id': toAccountId,
         'amount': amount,
         'fee': fee,
         'date': dateStr,
         'attachment_path': attachmentPath,
         'notes': notes,
       });

       final entryId = 'JE_XFER_$transferId';
       await txn.insert('journal_entries', {
         'id': entryId,
         'date': dateStr,
         'description': "تحويل مالي: ${notes ?? ''}",
         'reference_id': transferId,
         'attachment_path': attachmentPath,
       });

       // 1. Credit From Account (Decrease Asset)
       await txn.insert('journal_entry_lines', { 'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': fromAccountId, 'debit': 0, 'credit': amount + fee });
       // 2. Debit To Account (Increase Asset)
       await txn.insert('journal_entry_lines', { 'id': "${entryId}_L2", 'entry_id': entryId, 'account_id': toAccountId, 'debit': amount, 'credit': 0 });
       // 3. Debit Bank Expense (Increase Expense)
       if (fee > 0) {
         await txn.insert('journal_entry_lines', { 'id': "${entryId}_L3", 'entry_id': entryId, 'account_id': 'ACC_EXPENSES_BANK', 'debit': fee, 'credit': 0 });
       }

       // Update Balances
       await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount + fee, fromAccountId]);
       await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [amount, toAccountId]);
       if (fee > 0) {
         await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [fee, 'ACC_EXPENSES_BANK']);
       }
    });
  }

  Future<void> setReconciliationStatus(String id, bool status) async {
    final db = await database;
    await db.update('money_transfers', {'reconciled': status ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCostCenters() async {
    final db = await database;
    return await db.query('cost_centers');
  }

  Future<List<Map<String, dynamic>>> getWalletAccounts() async {
    final db = await database;
    // We only want Cash and Bank accounts for the wallet UI
    return await db.query('accounts', 
      where: 'id LIKE ? OR id LIKE ? OR id = ?', 
      whereArgs: ['%BANK%', '%CASH%', 'ACC_CASH'],
      orderBy: 'code ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT mt.*, fa.name as from_name, ta.name as to_name
      FROM money_transfers mt
      JOIN accounts fa ON mt.from_account_id = fa.id
      JOIN accounts ta ON mt.to_account_id = ta.id
      ORDER BY mt.date DESC
    ''');
  }

  // --- Financial Intelligence & Reports Data ---

  Future<Map<String, double>> getPNLSummary(String startDate, String endDate) async {
    final db = await database;
    
    // Revenue (Sum of Credit in ACC_SALES for period)
    final revenueRes = await db.rawQuery('''
      SELECT SUM(credit - debit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_SALES' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    // COGS (Sum of Debit in ACC_COGS)
    final cogsRes = await db.rawQuery('''
      SELECT SUM(debit - credit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_COGS' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    // Salaries (Sum of Debit in ACC_EXPENSES_SALARY)
    final salariesRes = await db.rawQuery('''
      SELECT SUM(debit - credit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_EXPENSES_SALARY' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    // General Expenses (Sum of Debit in ACC_EXPENSES_GENERAL)
    final generalRes = await db.rawQuery('''
      SELECT SUM(debit - credit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_EXPENSES_GENERAL' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    // Total Purchases (Information only, for checking)
    final purchasesRes = await db.rawQuery('''
      SELECT SUM(total) as total FROM purchase_invoices 
      WHERE issue_date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    double revenue = (revenueRes.first['total'] as num?)?.toDouble() ?? 0.0;
    double cogs = (cogsRes.first['total'] as num?)?.toDouble() ?? 0.0;
    double salaries = (salariesRes.first['total'] as num?)?.toDouble() ?? 0.0;
    double general = (generalRes.first['total'] as num?)?.toDouble() ?? 0.0;
    double totalPurchases = (purchasesRes.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'revenue': revenue,
      'cogs': cogs,
      'gross_profit': revenue - cogs,
      'salaries': salaries,
      'general_expenses': general,
      'net_profit': revenue - cogs - salaries - general,
      'total_purchases': totalPurchases,
    };
  }

  Future<Map<String, double>> getVATSummary(String startDate, String endDate) async {
    final db = await database;
    
    // VAT Collected (Sales Output - Credit)
    final outputRes = await db.rawQuery('''
      SELECT SUM(jel.credit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_VAT' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    // VAT Paid (Purchase Input - Debit)
    final inputRes = await db.rawQuery('''
      SELECT SUM(jel.debit) as total FROM journal_entry_lines jel 
      JOIN journal_entries je ON jel.entry_id = je.id 
      WHERE jel.account_id = 'ACC_VAT' AND je.date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    double outputVat = (outputRes.first['total'] as num?)?.toDouble() ?? 0.0;
    double inputVat = (inputRes.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'output_vat': outputVat,
      'input_vat': inputVat,
      'net_payable': outputVat - inputVat,
    };
  }

  Future<Map<String, double>> getBalanceSheet(String endDate) async {
    final db = await database;
    
    // Assets (Type: asset) - Debit Balance
    final assetsRes = await db.rawQuery('''
      SELECT SUM(jel.debit - jel.credit) as balance FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'asset' AND je.date <= ?
    ''', [endDate]);

    // Liabilities (Type: liability) - Credit Balance
    final liabilitiesRes = await db.rawQuery('''
      SELECT SUM(jel.credit - jel.debit) as balance FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'liability' AND je.date <= ?
    ''', [endDate]);

    // Equity (Type: equity) - Credit Balance
    final equityRes = await db.rawQuery('''
      SELECT SUM(jel.credit - jel.debit) as balance FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'equity' AND je.date <= ?
    ''', [endDate]);

    // All-time profit (Revenue - Expenses) up to date
    final profitRes = await db.rawQuery('''
      SELECT SUM(jel.credit - jel.debit) as profit FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE (a.type = 'income' OR a.type = 'expense') AND je.date <= ?
    ''', [endDate]);

    double assets = (assetsRes.first['balance'] as num?)?.toDouble() ?? 0.0;
    double liabilities = (liabilitiesRes.first['balance'] as num?)?.toDouble() ?? 0.0;
    double equity = (equityRes.first['balance'] as num?)?.toDouble() ?? 0.0;
    double cumulativeProfit = (profitRes.first['profit'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_assets': assets,
      'total_liabilities': liabilities,
      'total_equity': equity,
      'retained_earnings': cumulativeProfit,
      'total_liabilities_equity': liabilities + equity + cumulativeProfit,
    };
  }

  Future<Map<String, dynamic>> getFinancialIQ(String startDate, String endDate) async {
    final currentPnl = await getPNLSummary(startDate, endDate);
    
    // Calculate previous period of same duration
    DateTime start = DateTime.parse(startDate);
    DateTime end = DateTime.parse(endDate);
    Duration duration = end.difference(start);
    String prevEnd = start.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    String prevStart = DateTime.parse(prevEnd).subtract(duration).toIso8601String().split('T')[0];

    final prevPnl = await getPNLSummary(prevStart, prevEnd);

    double currentRev = currentPnl['revenue'] ?? 0;
    double prevRev = prevPnl['revenue'] ?? 0;
    double currentExp = (currentPnl['salaries'] ?? 0) + (currentPnl['general_expenses'] ?? 0);
    double prevExp = (prevPnl['salaries'] ?? 0) + (prevPnl['general_expenses'] ?? 0);

    double revGrowth = prevRev > 0 ? ((currentRev - prevRev) / prevRev) : 0;
    double expGrowth = prevExp > 0 ? ((currentExp - prevExp) / prevExp) : 0;
    
    double expenseRatio = currentRev > 0 ? (currentExp / currentRev) : 0;

    return {
      'current': currentPnl,
      'previous': prevPnl,
      'revenue_growth': revGrowth,
      'expense_growth': expGrowth,
      'expense_ratio': expenseRatio,
      'is_healthy': revGrowth >= expGrowth && expenseRatio < 0.7,
    };
  }

  // --- Smart Inventory & Stock Analytics (v15) ---

  Future<void> updateWeightedAverageCost(String itemId, double newQty, double newUnitPrice) async {
    final db = await database;
    final item = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
    if (item.isEmpty) return;

    double currentQty = (item.first['quantity'] as num?)?.toDouble() ?? 0.0;
    double currentCost = (item.first['cost_price'] as num?)?.toDouble() ?? 0.0;

    // Formula: (Current Total Cost + New Purchase Cost) / Total Quantity
    double totalOldValue = currentQty * currentCost;
    double totalNewValue = newQty * newUnitPrice;
    double totalNewQty = currentQty + newQty;

    double newWAC = totalNewQty > 0 ? (totalOldValue + totalNewValue) / totalNewQty : newUnitPrice;

    await db.update('items', {
      'cost_price': newWAC,
      'quantity': totalNewQty,
    }, where: 'id = ?', whereArgs: [itemId]);
  }

  Future<Map<String, dynamic>> getItemPredictiveAnalytics(String itemId) async {
    final db = await database;
    final item = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
    if (item.isEmpty) return {};

    double currentQty = (item.first['quantity'] as num?)?.toDouble() ?? 0.0;
    double safetyStock = (item.first['min_stock_level'] as num?)?.toDouble() ?? 0.0;

    // Calculate Average Daily Sales (ADS) for last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    
    // We search in invoice_lines for matches to our item ID
    // Note: since itemId is a string ID, we use LIKE for robust matching if needed
    final salesRes = await db.rawQuery('''
      SELECT SUM(il.quantity) as total_sold FROM invoice_lines il
      JOIN invoices i ON il.invoice_id = i.id
      WHERE il.name LIKE ? AND i.issue_date >= ?
    ''', ["%${item.first['name']}%", thirtyDaysAgo]);

    double totalSold = (salesRes.first['total_sold'] as num?)?.toDouble() ?? 0.0;
    double ads = totalSold / 30.0;

    // Days Until Stockout: Current Qty / ADS
    double daysRemaining = ads > 0 ? currentQty / ads : double.infinity;

    return {
      'current_qty': currentQty,
      'safety_stock': safetyStock,
      'ads': ads,
      'days_remaining': daysRemaining,
      'is_critical': currentQty <= safetyStock || daysRemaining <= 7,
    };
  }

  Future<List<Map<String, dynamic>>> getDraftInvoices() async {
    final db = await database;
    return await db.query('draft_invoices', orderBy: 'date DESC');
  }

  Future<void> saveDraftInvoice(Map<String, dynamic> draft) async {
    final db = await database;
    await db.insert('draft_invoices', draft, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Assets Custody & Maintenance (v16) ---

  Future<void> assignAssetCustody(String assetId, String employeeId, String notes) async {
    final db = await database;
    final logId = 'CST_${DateTime.now().millisecondsSinceEpoch}';
    final dateIso = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      await txn.update('assets', {
        'status': 'in_use',
        'assigned_to': employeeId
      }, where: 'id = ?', whereArgs: [assetId]);

      await txn.insert('asset_custody_log', {
        'id': logId,
        'asset_id': assetId,
        'employee_id': employeeId,
        'issued_date': dateIso,
        'status': 'active',
        'notes': notes
      });
    });
  }

  Future<void> returnAssetCustody(String assetId) async {
    final db = await database;
    final dateIso = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      await txn.update('assets', {
        'status': 'available',
        'assigned_to': null
      }, where: 'id = ?', whereArgs: [assetId]);

      await txn.rawUpdate('''
        UPDATE asset_custody_log 
        SET status = 'returned', returned_date = ? 
        WHERE asset_id = ? AND status = 'active'
      ''', [dateIso, assetId]);
    });
  }

  Future<void> reportAssetDamage(String assetId, String employeeId, String reason, bool deductFromEmployee) async {
    final db = await database;
    final dateIso = DateTime.now().toIso8601String();
    
    // Fetch asset cost to record the loss
    final assetRes = await db.query('assets', columns: ['cost_price', 'name'], where: 'id = ?', whereArgs: [assetId]);
    if (assetRes.isEmpty) return;
    
    final double valueLoss = (assetRes.first['cost_price'] as num?)?.toDouble() ?? 0.0;
    final String assetName = assetRes.first['name'] as String? ?? 'Asset';
    
    final entryId = "JE_DMG_${DateTime.now().millisecondsSinceEpoch}";
    final reportId = "DMG_${DateTime.now().millisecondsSinceEpoch}";

    await db.transaction((txn) async {
      // 1. Update Asset Status to scrap
      await txn.update('assets', {
        'status': 'scrap'
      }, where: 'id = ?', whereArgs: [assetId]);
      
      // 2. Return custody if active
      await txn.rawUpdate('''
        UPDATE asset_custody_log 
        SET status = 'returned', returned_date = ? 
        WHERE asset_id = ? AND status = 'active'
      ''', [dateIso, assetId]);

      // 3. Record Damage Report
      await txn.insert('damage_reports', {
        'id': reportId,
        'asset_id': assetId,
        'employee_id': employeeId,
        'date': dateIso,
        'damage_reason': reason,
        'value_loss': valueLoss,
        'entry_id': entryId
      });

      // 4. Accounting Journal Entry for Loss
      if (valueLoss > 0) {
        await txn.insert('journal_entries', {
          'id': entryId,
          'date': dateIso.split('T')[0],
          'description': "إهلاك أصل تالف: $assetName ($reason)",
          'reference_id': reportId,
        });

        if (deductFromEmployee) {
          // Debit Employee Receivable
          await txn.insert('journal_entry_lines', { 'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_EMP_RECEIVABLE', 'debit': valueLoss, 'credit': 0.0 });
          // Update Account Balance
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [valueLoss, 'ACC_EMP_RECEIVABLE']);
        } else {
          // Debit Loss / Expense
          await txn.insert('journal_entry_lines', { 'id': "${entryId}_L1", 'entry_id': entryId, 'account_id': 'ACC_LOSS_ASSETS', 'debit': valueLoss, 'credit': 0.0 });
          // Update Account Balance
          await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [valueLoss, 'ACC_LOSS_ASSETS']);
        }
      }
    });
  }

  Future<void> scheduleMaintenance(String assetId, String date, String reason) async {
    final db = await database;
    final scheduleId = 'MNT_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('maintenance_schedules', {
      'id': scheduleId,
      'asset_id': assetId,
      'scheduled_date': date,
      'reason': reason,
      'status': 'pending'
    });
  }

  Future<List<Map<String, dynamic>>> getMaintenanceCalendar() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, a.name as asset_name, a.location 
      FROM maintenance_schedules m
      JOIN assets a ON m.asset_id = a.id
      ORDER BY m.scheduled_date ASC
    ''');
  }

  // --- Projects & Contracting (v17) ---

  Future<void> createProject(Map<String, dynamic> projectData) async {
    final db = await database;
    await db.insert('projects', projectData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query('projects', orderBy: 'start_date DESC');
  }

  Future<Map<String, dynamic>> getProjectFinancials(String projectId) async {
    final db = await database;
    
    // Calculate total costs assigned to this project via Journal Entry Lines
    // Any debit against an expense account (starting with '5' or explicitly expense) with this project_id
    final result = await db.rawQuery('''
      SELECT SUM(jel.debit) as total_cost 
      FROM journal_entry_lines jel
      JOIN accounts a ON jel.account_id = a.id
      WHERE jel.project_id = ? AND a.type = 'expense'
    ''', [projectId]);

    double actualCost = (result.first['total_cost'] as num?)?.toDouble() ?? 0.0;
    
    // Fetch budget
    final projRes = await db.query('projects', columns: ['budget_amount'], where: 'id = ?', whereArgs: [projectId]);
    double budget = 0.0;
    if (projRes.isNotEmpty) {
      budget = (projRes.first['budget_amount'] as num?)?.toDouble() ?? 0.0;
    }

    double spentPercentage = budget > 0 ? (actualCost / budget) : 0.0;

    return {
      'actual_cost': actualCost,
      'budget': budget,
      'spent_percentage': spentPercentage,
      'is_critical': spentPercentage >= 0.8  // Alert threshold 80%
    };
  }

  // --- POS Cashier System (v18) ---

  Future<Map<String, dynamic>?> getActiveShift(String cashierId) async {
    final db = await database;
    final res = await db.query('shifts', where: 'cashier_id = ? AND status = ?', whereArgs: [cashierId, 'open']);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<String> openShift(String cashierId, double openingBalance) async {
    final db = await database;
    final shiftId = 'SHIFT_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('shifts', {
      'id': shiftId,
      'cashier_id': cashierId,
      'start_time': DateTime.now().toIso8601String(),
      'opening_balance': openingBalance,
      'status': 'open'
    });
    return shiftId;
  }

  Future<void> closeShift(String shiftId, double closingBalance) async {
    final db = await database;
    await db.update('shifts', {
      'end_time': DateTime.now().toIso8601String(),
      'closing_balance': closingBalance,
      'status': 'closed'
    }, where: 'id = ?', whereArgs: [shiftId]);
  }

  Future<void> savePosReceipt({
    required List<Map<String, dynamic>> lines,
    required double total,
    required double taxAmount,
    required double subtotal,
    required String shiftId,
  }) async {
    // 🛡️ QuickBooks Rule: Check if the period is closed
    final issueDate = DateTime.now().toIso8601String().split('T')[0];
    if (await isDateLocked(issueDate)) {
      throw Exception("لا يمكن إضافة مبيعات في فترة محاسبية مغلقة.");
    }
    final db = await database;
    final invoiceId = 'POS_${DateTime.now().millisecondsSinceEpoch}';

    await db.transaction((txn) async {
      // 1. Insert Invoice connected to Shift
      await txn.insert('invoices', {
        'id': invoiceId,
        'issue_date': issueDate,
        'client_id': 'WALK_IN_CUSTOMER',
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'total': total,
        'status': 'paid',
        'payment_type': 'cash',
        'shift_id': shiftId,
      });

      // 2. Insert Invoice Lines and Update Inventory
      for (var line in lines) {
        String itemId = line['item_id'];
        double qty = line['quantity'];
        double price = line['price'];

        await txn.insert('invoice_lines', {
          'id': 'POSL_${DateTime.now().microsecondsSinceEpoch}',
          'invoice_id': invoiceId,
          'name': line['name'],
          'quantity': qty,
          'price_at_sale': price,
        });

        // Drain Inventory
        
        // 3. Inventory & COGS Logging (Phase 7.1)
        final itemDetails = await txn.query('items', where: 'id = ?', columns: ['name', 'quantity', 'min_stock_level']);
        if (itemDetails.isNotEmpty) {
           double newQty = ((itemDetails.first['quantity'] as num?) ?? 0) - qty;
           double minQty = (itemDetails.first['min_stock_level'] as num?)?.toDouble() ?? 0;
           String itemName = itemDetails.first['name'] as String;

           // Alert if below min level (Handled via logging or app could check this ITX)
           if (newQty < minQty) {
              debugPrint("⚠️ LOW STOCK ALERT: $itemName is below min level ($newQty < $minQty)");
           }
        }

        await txn.rawUpdate('UPDATE items SET quantity = quantity - ? WHERE id = ?', [qty, itemId]);
        
        await txn.insert('inventory_transactions', {
          'id': 'POS_ITX_${DateTime.now().microsecondsSinceEpoch}',
          'item_id': itemId,
          'item_name': line['name'],
          'type': 'sale',
          'quantity': -qty,
          'reference_id': invoiceId,
          'date': issueDate,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

      }

      // 3. Accounting Entries
      final entryId = 'JRN_$invoiceId';
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': issueDate,
        'description': 'مبيعات نقاط البيع (POS) $invoiceId',
        'reference_id': invoiceId,
      });

      // Debit Cash (Asset Up)
      await txn.insert('journal_entry_lines', { 'id': '${entryId}_L1', 'entry_id': entryId, 'account_id': 'ACC_CASH', 'debit': total, 'credit': 0 });
      // Credit Revenue
      await txn.insert('journal_entry_lines', { 'id': '${entryId}_L2', 'entry_id': entryId, 'account_id': 'ACC_REVENUE', 'debit': 0, 'credit': subtotal });
      // Credit VAT
      if (taxAmount > 0) {
        await txn.insert('journal_entry_lines', { 'id': '${entryId}_L3', 'entry_id': entryId, 'account_id': 'ACC_VAT', 'debit': 0, 'credit': taxAmount });
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [taxAmount, 'ACC_VAT']);
      }

      // We approximate COGS using COGS logic based on item cost (Simplified for POS context right now)
      double totalCogs = 0.0;
      for (var line in lines) {
         final res = await txn.query('items', columns: ['cost_price'], where: 'id = ?', whereArgs: [line['item_id']]);
         if (res.isNotEmpty) {
           double cost = (res.first['cost_price'] as num?)?.toDouble() ?? 0.0;
           totalCogs += cost * (line['quantity'] as num).toDouble();
         }
      }

      if (totalCogs > 0) {
        // Debit COGS
        await txn.insert('journal_entry_lines', { 'id': '${entryId}_COGS_D', 'entry_id': entryId, 'account_id': 'ACC_COGS', 'debit': totalCogs, 'credit': 0 });
        // Credit Inventory
        await txn.insert('journal_entry_lines', { 'id': '${entryId}_INV_C', 'entry_id': entryId, 'account_id': 'ACC_INVENTORY', 'debit': 0, 'credit': totalCogs });
        
        await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [totalCogs, 'ACC_COGS']);
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [totalCogs, 'ACC_INVENTORY']);
      }

      // Update Balances
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [total, 'ACC_CASH']);
      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [subtotal, 'ACC_REVENUE']);
    });
  }

  Future<List<Map<String, dynamic>>> getUnifiedFinancialRecords(String searchQuery) async {
    final db = await database;
    String q = '%$searchQuery%';
    
    String sql = '''
      SELECT 
        id, 
        issue_date as date, 
        'sales' as type, 
        id as title, 
        total as amount, 
        status 
      FROM invoices
      WHERE id LIKE ? OR (client_id IS NOT NULL AND client_id LIKE ?)
      
      UNION ALL
      
      SELECT 
        id, 
        issue_date as date, 
        'purchase' as type, 
        id as title, 
        total as amount, 
        'paid' as status 
      FROM purchase_invoices
      WHERE id LIKE ? OR (supplier_id IS NOT NULL AND supplier_id LIKE ?)
      
      UNION ALL
      
      SELECT 
        je.id, 
        je.date, 
        'entry' as type, 
        je.description as title, 
        (SELECT COALESCE(SUM(debit), 0) FROM journal_entry_lines WHERE entry_id = je.id) as amount, 
        'posted' as status
      FROM journal_entries je
      WHERE je.id LIKE ? OR (je.description IS NOT NULL AND je.description LIKE ?)
      
      ORDER BY date DESC
    ''';
    
    return await db.rawQuery(sql, [q, q, q, q, q, q]);
  }

  Future<void> saveManualJournalEntry({
    required String date,
    required String description,
    required List<Map<String, dynamic>> lines,
  }) async {
    // 🛡️ QuickBooks Rule: Check if the period is closed
    if (await isDateLocked(date)) {
      throw Exception("لا يمكن إضافة قيد في فترة محاسبية مغلقة.");
    }
    final db = await database;
    final entryId = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';

    await db.transaction((txn) async {
      // 1. Insert Header
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': date,
        'description': description,
        'reference_id': 'MANUAL',
      });

      // 2. Insert Lines & Update Account Balances
      int lineCounter = 0;
      for (var line in lines) {
        lineCounter++;
        String accountId = line['account_id'];
        double debit = (line['debit'] as num?)?.toDouble() ?? 0.0;
        double credit = (line['credit'] as num?)?.toDouble() ?? 0.0;
        String? projectId = line['project_id'];
        String? costCenterId = line['cost_center_id'];

        await txn.insert('journal_entry_lines', {
          'id': 'JEL_${DateTime.now().microsecondsSinceEpoch}_$lineCounter',
          'entry_id': entryId,
          'account_id': accountId,
          'debit': debit,
          'credit': credit,
          'project_id': projectId,
          'cost_center_id': costCenterId,
        });

        // Update Account Balance
        // Logic: Add Debit, Subtract Credit (Normal for Assets/Expenses)
        // Note: For Liabilities/Equity/Revenue, we should be careful, but here we'll use simple +/-
        // and let the Financial Reports handle the meaning of the signed balance.
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? - ? WHERE id = ?',
          [debit, credit, accountId]
        );
      }
    });
  }

  Future<Map<String, dynamic>> getSupplierSummary(String supplierId) async {
    final db = await database;
    
    // 1. Current Balance from suppliers table (cached/synced)
    final supplierRes = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
    final double balance = (supplierRes.first['balance'] as num?)?.toDouble() ?? 0.0;

    // 2. Overdue Amount (where due_date < now and unpaid)
    // For simplicity, we assume if it's in purchase_invoices, it's a debt unless payment is separate.
    // In this system, payments are tracked in 'payments' table.
    final now = DateTime.now().toIso8601String().split('T')[0];
    final overdueRes = await db.rawQuery('''
      SELECT SUM(total) as overdue 
      FROM purchase_invoices 
      WHERE supplier_id = ? AND due_date < ?
    ''', [supplierId, now]);
    
    // 3. Prepayments (Payments where type is 'advance' or just sum of all payments vs sum of all invoices)
    final paymentsRes = await db.rawQuery('SELECT SUM(amount) as total_paid FROM payments WHERE partner_id = ? AND partner_type = "supplier"', [supplierId]);
    final double totalPaid = (paymentsRes.first['total_paid'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'balance': balance,
      'overdue': (overdueRes.first['overdue'] as num?)?.toDouble() ?? 0.0,
      'total_paid': totalPaid,
    };
  }

  Future<List<double>> getSupplierAging(String supplierId) async {
    final db = await database;
    final now = DateTime.now();
    
    // Categories: [0-30, 31-60, 60+]
    List<double> aging = [0.0, 0.0, 0.0];
    
    final invoices = await db.query('purchase_invoices', where: 'supplier_id = ?', whereArgs: [supplierId]);
    
    for (var inv in invoices) {
      final dueDateStr = inv['due_date'] as String?;
      if (dueDateStr == null) continue;
      
      final dueDate = DateTime.parse(dueDateStr);
      final diff = now.difference(dueDate).inDays;
      final amount = (inv['total'] as num?)?.toDouble() ?? 0.0;
      
      if (diff <= 30) {
        aging[0] += amount;
      } else if (diff <= 60) {
        aging[1] += amount;
      } else {
        aging[2] += amount;
      }
    }
    
    return aging;
  }

  Future<List<Map<String, dynamic>>> getSupplierTransactions(String supplierId) async {
    final db = await database;
    
    // Combined Statement: Invoices + Payments
    final sql = '''
      SELECT id, issue_date as date, 'فاتورة مشتريات' as type, total as amount, 'out' as direction
      FROM purchase_invoices
      WHERE supplier_id = ?
      
      UNION ALL
      
      SELECT id, date, 'دفعة نقدية' as type, amount, 'in' as direction
      FROM payments
      WHERE partner_id = ? AND partner_type = 'supplier'
      
      ORDER BY date DESC
    ''';
    
    return await db.rawQuery(sql, [supplierId, supplierId]);
  }

  // --- Budgeting Logic (v22) ---

  Future<List<Map<String, dynamic>>> getBudgets(String period) async {
    final db = await database;
    
    // Join with accounts and projects names for the UI
    final sql = '''
      SELECT 
        b.*, 
        a.name as account_name,
        COALESCE(p.name, 'بدون مشروع') as project_name,
        (
          SELECT COALESCE(SUM(jel.debit - jel.credit), 0)
          FROM journal_entry_lines jel
          JOIN journal_entries je ON jel.entry_id = je.id
          WHERE jel.account_id = b.account_id 
          AND (b.project_id IS NULL OR jel.project_id = b.project_id)
          AND je.date LIKE ?
        ) as spent_amount
      FROM budgets b
      JOIN accounts a ON b.account_id = a.id
      LEFT JOIN projects p ON b.project_id = p.id
      WHERE b.period = ?
    ''';
    
    return await db.rawQuery(sql, ['$period%', period]);
  }

  Future<void> upsertBudget({
    required String accountId,
    String? projectId,
    required double amount,
    required String period,
  }) async {
    final db = await database;
    final id = 'BGT_${accountId}_${projectId ?? "ALL"}_$period';
    
    await db.insert('budgets', {
      'id': id,
      'account_id': accountId,
      'project_id': projectId,
      'allocated_amount': amount,
      'period': period,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns a map with {is_exceeded: bool, message: String, variance: percentage}
  Future<Map<String, dynamic>> checkBudgetExceedance(String accountId, double newAmount, {String? projectId}) async {
    final db = await database;
    final period = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
    
    final budgets = await db.query('budgets', 
      where: 'account_id = ? AND period = ? AND (project_id = ? OR project_id IS NULL)',
      whereArgs: [accountId, period, projectId],
      orderBy: 'project_id DESC' // Specific project budget takes priority if both exist
    );
    
    if (budgets.isEmpty) return {'is_exceeded': false};

    final budget = budgets.first;
    final double allocated = (budget['allocated_amount'] as num).toDouble();
    
    // Calculate current spent
    final spentRes = await db.rawQuery('''
      SELECT SUM(jel.debit - jel.credit) as total
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      WHERE jel.account_id = ? AND je.date LIKE ? AND (jel.project_id = ? OR ? IS NULL)
    ''', [accountId, '$period%', projectId, projectId]);
    
    final double currentSpent = (spentRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final double totalWithNew = currentSpent + newAmount;
    
    if (totalWithNew > allocated) {
      final double exceedPercent = ((totalWithNew / allocated) - 1) * 100;
      return {
        'is_exceeded': true,
        'message': '⚠️ تجاوزت الميزانية! إجمالي المصروف لهذا البند سيصل لـ ${totalWithNew.toStringAsFixed(0)} من أصل $allocated.',
        'variance': exceedPercent,
        'allocated': allocated,
        'new_total': totalWithNew,
      };
    }
    
    return {'is_exceeded': false};
  }

  /// Validates multiple lines at once, returning a list of warnings
  Future<List<Map<String, dynamic>>> validateEntryBudgets(List<Map<String, dynamic>> lines) async {
    List<Map<String, dynamic>> warnings = [];
    
    for (var line in lines) {
      final double debit = (line['debit'] as num?)?.toDouble() ?? 0.0;
      final String accountId = line['account_id'];
      final String? projectId = line['project_id'];

      if (debit > 0) {
        final check = await checkBudgetExceedance(accountId, debit, projectId: projectId);
        if (check['is_exceeded'] == true) {
          warnings.add(check);
        }
      }
    }
    return warnings;
  }

  // --- Security Audit Logging (v35) ---

  Future<void> logSecurityAlert(String type, String description, {bool isCritical = false}) async {
    final db = await database;
    final id = 'SEC_${DateTime.now().millisecondsSinceEpoch}';
    final deviceId = await getDeviceFingerprint();
    final now = DateTime.now().toIso8601String();

    await db.insert('security_audit', {
      'id': id,
      'action_type': type,
      'description': description,
      'is_critical': isCritical ? 1 : 0,
      'updated_at': now,
      'device_id': deviceId,
      'sync_status': 0, // Pending Sync
    });
    
    // Notify Listeners (if any through a Stream or Provider, handled in main.dart)
    NotificationService().notifySensitiveAction(type, description);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  LEAVE REQUESTS (HR Module - QuickBooks Time-Off)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getLeaveRequests({String? employeeId}) async {
    final db = await database;
    if (employeeId != null) {
      return await db.query('leave_requests',
        where: 'employee_id = ? AND is_deleted = 0',
        whereArgs: [employeeId],
        orderBy: 'start_date DESC');
    }
    return await db.query('leave_requests',
      where: 'is_deleted = 0',
      orderBy: 'start_date DESC');
  }

  Future<void> addLeaveRequest(Map<String, dynamic> request) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    final nowStr = DateTime.now().toIso8601String();
    request['id'] ??= 'LR_${DateTime.now().millisecondsSinceEpoch}';
    request['sync_status'] = 0;
    request['updated_at'] = nowStr;
    request['device_id'] = deviceId;
    request['is_deleted'] = 0;
    await db.insert('leave_requests', request, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLeaveRequestStatus(String id, String status) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    await db.update('leave_requests', {
      'status': status,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
      'device_id': deviceId,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLeaveRequest(String id) async {
    final db = await database;
    await db.update('leave_requests', {
      'is_deleted': 1,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  EMPLOYEE LOANS (HR Module)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getEmployeeLoans({String? employeeId}) async {
    final db = await database;
    if (employeeId != null) {
      return await db.query('employee_loans',
        where: 'employee_id = ? AND is_deleted = 0',
        whereArgs: [employeeId],
        orderBy: 'start_date DESC');
    }
    return await db.query('employee_loans',
      where: 'is_deleted = 0',
      orderBy: 'start_date DESC');
  }

  Future<void> addEmployeeLoan(Map<String, dynamic> loan) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    final nowStr = DateTime.now().toIso8601String();
    loan['id'] ??= 'LOAN_${DateTime.now().millisecondsSinceEpoch}';
    loan['sync_status'] = 0;
    loan['updated_at'] = nowStr;
    loan['device_id'] = deviceId;
    loan['is_deleted'] = 0;

    await db.insert('employee_loans', loan, conflictAlgorithm: ConflictAlgorithm.replace);

    // Create journal entry for loan disbursement
    if (loan['status'] == 'ACTIVE') {
      final double amount = (loan['amount'] as num).toDouble();
      await saveManualJournalEntry(
        date: nowStr.split('T')[0],
        description: 'صرف سلفة للموظف ${loan['employee_id']}',
        lines: [
          {'account_id': 'ACC_EMP_RECEIVABLE', 'debit': amount, 'credit': 0.0},
          {'account_id': 'ACC_CASH', 'debit': 0.0, 'credit': amount},
        ],
      );
    }
  }

  Future<void> deductLoanInstallment(String loanId, double installment) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE employee_loans SET balance = balance - ?, sync_status = 0, updated_at = ? WHERE id = ?',
      [installment, DateTime.now().toIso8601String(), loanId],
    );
    // Mark as PAID if balance <= 0
    await db.rawUpdate(
      "UPDATE employee_loans SET status = 'PAID' WHERE id = ? AND balance <= 0",
      [loanId],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  ATTENDANCE (HR Module - Check-in/Check-out)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAttendanceLogs({String? employeeId, String? date}) async {
    final db = await database;
    String where = 'is_deleted = 0';
    List<dynamic> args = [];
    if (employeeId != null) {
      where += ' AND employee_id = ?';
      args.add(employeeId);
    }
    if (date != null) {
      where += ' AND date = ?';
      args.add(date);
    }
    return await db.query('attendance_logs', where: where, whereArgs: args, orderBy: 'date DESC');
  }

  Future<void> recordCheckIn(String employeeId) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    final dateStr = nowStr.split('T')[0];
    final timeStr = nowStr.split('T')[1].substring(0, 5);
    final deviceId = await getDeviceFingerprint();

    await db.insert('attendance_logs', {
      'id': 'ATT_${DateTime.now().millisecondsSinceEpoch}',
      'employee_id': employeeId,
      'date': dateStr,
      'check_in': timeStr,
      'status': 'present',
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': deviceId,
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordCheckOut(String attendanceId) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    final timeStr = nowStr.split('T')[1].substring(0, 5);
    await db.update('attendance_logs', {
      'check_out': timeStr,
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [attendanceId]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  REAL ESTATE (Units + Contracts)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getRealEstateUnits() async {
    final db = await database;
    return await db.query('real_estate_units', where: 'is_deleted = 0', orderBy: 'name ASC');
  }

  Future<void> addRealEstateUnit(Map<String, dynamic> unit) async {
    final db = await database;
    unit['id'] ??= 'REU_${DateTime.now().millisecondsSinceEpoch}';
    unit['sync_status'] = 0;
    unit['updated_at'] = DateTime.now().toIso8601String();
    unit['device_id'] = await getDeviceFingerprint();
    unit['is_deleted'] = 0;
    await db.insert('real_estate_units', unit, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRealEstateUnit(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('real_estate_units', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteRealEstateUnit(String id) async {
    final db = await database;
    await db.update('real_estate_units', {
      'is_deleted': 1, 'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRealEstateContracts({String? unitId}) async {
    final db = await database;
    if (unitId != null) {
      return await db.query('real_estate_contracts',
        where: 'unit_id = ? AND is_deleted = 0', whereArgs: [unitId],
        orderBy: 'start_date DESC');
    }
    return await db.query('real_estate_contracts', where: 'is_deleted = 0', orderBy: 'start_date DESC');
  }

  Future<void> addRealEstateContract(Map<String, dynamic> contract) async {
    final db = await database;
    contract['id'] ??= 'REC_${DateTime.now().millisecondsSinceEpoch}';
    contract['sync_status'] = 0;
    contract['updated_at'] = DateTime.now().toIso8601String();
    contract['device_id'] = await getDeviceFingerprint();
    contract['is_deleted'] = 0;
    await db.insert('real_estate_contracts', contract, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update unit status to RENTED
    if (contract['unit_id'] != null) {
      await db.update('real_estate_units', {'status': 'RENTED'}, where: 'id = ?', whereArgs: [contract['unit_id']]);
    }
  }

  Future<void> collectRent(String contractId, double amount) async {
    final nowStr = DateTime.now().toIso8601String();
    await saveManualJournalEntry(
      date: nowStr.split('T')[0],
      description: 'تحصيل إيجار عقد رقم $contractId',
      lines: [
        {'account_id': 'ACC_CASH', 'debit': amount, 'credit': 0.0},
        {'account_id': 'ACC_SALES', 'debit': 0.0, 'credit': amount},
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  INVESTMENTS (Portfolio Management)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getInvestments() async {
    final db = await database;
    return await db.query('investments', where: 'is_deleted = 0', orderBy: 'name ASC');
  }

  Future<void> addInvestment(Map<String, dynamic> investment) async {
    final db = await database;
    investment['id'] ??= 'INV_${DateTime.now().millisecondsSinceEpoch}';
    investment['sync_status'] = 0;
    investment['updated_at'] = DateTime.now().toIso8601String();
    investment['device_id'] = await getDeviceFingerprint();
    investment['is_deleted'] = 0;
    await db.insert('investments', investment, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateInvestmentValue(String id, double newValue) async {
    final db = await database;
    await db.update('investments', {
      'current_value': newValue,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addInvestmentTransaction(Map<String, dynamic> txn) async {
    final db = await database;
    txn['id'] ??= 'ITXN_${DateTime.now().millisecondsSinceEpoch}';
    txn['sync_status'] = 0;
    txn['updated_at'] = DateTime.now().toIso8601String();
    txn['device_id'] = await getDeviceFingerprint();
    txn['is_deleted'] = 0;
    await db.insert('investment_transactions', txn, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getInvestmentTransactions(String investmentId) async {
    final db = await database;
    return await db.query('investment_transactions',
      where: 'investment_id = ?', whereArgs: [investmentId],
      orderBy: 'date DESC');
  }

  Future<void> liquidateInvestment(String id, String reason, double amount) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    await db.update('investments', {
      'status': 'LIQUIDATED',
      'sync_status': 0,
      'updated_at': nowStr,
    }, where: 'id = ?', whereArgs: [id]);

    await db.insert('liquidation_requests', {
      'id': 'LIQ_${DateTime.now().millisecondsSinceEpoch}',
      'asset_type': 'INVESTMENT',
      'asset_id': id,
      'reason': reason,
      'requested_amount': amount,
      'status': 'APPROVED',
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': await getDeviceFingerprint(),
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  MANUFACTURING & BOM (Production Module)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getBOMs() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.*, i.name as finished_good_name
      FROM bom b
      LEFT JOIN items i ON b.finished_good_item_id = i.id
      ORDER BY b.name ASC
    ''');
  }

  Future<void> addBOM(Map<String, dynamic> bom) async {
    final db = await database;
    bom['id'] ??= 'BOM_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('bom', bom, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addBOMLine(Map<String, dynamic> line) async {
    final db = await database;
    line['id'] ??= 'BL_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('bom_lines', line, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBOMLines(String bomId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT bl.*, i.name as material_name, i.cost_price, i.quantity as available_qty
      FROM bom_lines bl
      LEFT JOIN items i ON bl.raw_material_item_id = i.id
      WHERE bl.bom_id = ?
    ''', [bomId]);
  }

  Future<void> executeManufacturingOrder({
    required String bomId,
    required double qtyToProduce,
  }) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    final orderId = 'MO_${DateTime.now().millisecondsSinceEpoch}';

    await db.transaction((txn) async {
      // Get BOM and its lines
      final bomRes = await txn.query('bom', where: 'id = ?', whereArgs: [bomId]);
      if (bomRes.isEmpty) return;
      final bom = bomRes.first;
      final String? finishedItemId = bom['finished_good_item_id'] as String?;
      final double overhead = (bom['estimated_overhead_cost'] as num?)?.toDouble() ?? 0;

      final bomLines = await txn.query('bom_lines', where: 'bom_id = ?', whereArgs: [bomId]);
      double totalMaterialCost = 0;

      // 1. Deduct raw materials
      for (var line in bomLines) {
        final String rawItemId = line['raw_material_item_id'] as String;
        final double qtyRequired = (line['quantity_required'] as num).toDouble();
        final double waste = (line['waste_percentage'] as num?)?.toDouble() ?? 0;
        final double totalQty = qtyRequired * qtyToProduce * (1 + waste / 100);

        // Get current cost
        final itemRes = await txn.query('items', where: 'id = ?', whereArgs: [rawItemId]);
        if (itemRes.isNotEmpty) {
          final double unitCost = (itemRes.first['cost_price'] as num?)?.toDouble() ?? 0;
          totalMaterialCost += unitCost * totalQty;
        }

        // Deduct stock
        await txn.rawUpdate(
          'UPDATE items SET quantity = quantity - ? WHERE id = ?',
          [totalQty, rawItemId],
        );
      }

      // 2. Add finished goods to inventory
      final double totalCost = totalMaterialCost + (overhead * qtyToProduce);
      final double unitCost = qtyToProduce > 0 ? totalCost / qtyToProduce : 0;

      if (finishedItemId != null) {
        await txn.rawUpdate(
          'UPDATE items SET quantity = quantity + ?, cost_price = ? WHERE id = ?',
          [qtyToProduce, unitCost, finishedItemId],
        );
      }

      // 3. Create manufacturing order record
      await txn.insert('manufacturing_orders', {
        'id': orderId,
        'bom_id': bomId,
        'status': 'completed',
        'qty_to_produce': qtyToProduce,
        'start_date': nowStr,
        'end_date': nowStr,
        'actual_material_cost': totalMaterialCost,
        'actual_overhead_cost': overhead * qtyToProduce,
        'total_cost': totalCost,
      });

      // 4. Journal entry
      final entryId = 'JE_MO_$orderId';
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': nowStr.split('T')[0],
        'description': 'أمر تصنيع $orderId - إنتاج $qtyToProduce وحدة',
        'reference_id': orderId,
      });
      await txn.insert('journal_entry_lines', {
        'id': '${entryId}_D', 'entry_id': entryId,
        'account_id': 'ACC_INVENTORY', 'debit': totalCost, 'credit': 0,
      });
      await txn.insert('journal_entry_lines', {
        'id': '${entryId}_C',
        'entry_id': entryId,
        'account_id': 'ACC_INVENTORY', 'debit': 0, 'credit': totalMaterialCost,
      });
      if (overhead > 0) {
        await txn.insert('journal_entry_lines', {
          'id': '${entryId}_OH', 'entry_id': entryId,
          'account_id': 'ACC_EXPENSES_GENERAL', 'debit': 0, 'credit': overhead * qtyToProduce,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getManufacturingOrders() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT mo.*, b.name as bom_name
      FROM manufacturing_orders mo
      LEFT JOIN bom b ON mo.bom_id = b.id
      ORDER BY mo.start_date DESC
    ''');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  WAREHOUSE & INVENTORY OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await database;
    return await db.query('warehouses', orderBy: 'name ASC');
  }

  Future<void> addWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    warehouse['id'] ??= 'WH_${DateTime.now().millisecondsSinceEpoch}';
    warehouse['sync_status'] = 0;
    warehouse['updated_at'] = DateTime.now().toIso8601String();
    warehouse['device_id'] = await getDeviceFingerprint();
    warehouse['is_deleted'] = 0;
    await db.insert('warehouses', warehouse, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getInventoryBatches({String? warehouseId, String? itemId}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (warehouseId != null) { where += ' AND warehouse_id = ?'; args.add(warehouseId); }
    if (itemId != null) { where += ' AND item_id = ?'; args.add(itemId); }
    return await db.query('inventory_batches', where: where, whereArgs: args, orderBy: 'expiry_date ASC');
  }

  Future<void> addInventoryBatch(Map<String, dynamic> batch) async {
    final db = await database;
    batch['id'] ??= 'BATCH_${DateTime.now().millisecondsSinceEpoch}';
    batch['sync_status'] = 0;
    batch['updated_at'] = DateTime.now().toIso8601String();
    batch['device_id'] = await getDeviceFingerprint();
    batch['is_deleted'] = 0;
    await db.insert('inventory_batches', batch, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> transferInventory({
    required String itemId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required double quantity,
  }) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    await db.insert('inventory_transfers', {
      'id': 'XFER_${DateTime.now().millisecondsSinceEpoch}',
      'item_id': itemId,
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'quantity': quantity,
      'date': nowStr,
      'status': 'completed',
      'sync_status': 0,
      'updated_at': nowStr,
      'device_id': await getDeviceFingerprint(),
      'is_deleted': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getInventoryTransfers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT it.*, i.name as item_name, fw.name as from_name, tw.name as to_name
      FROM inventory_transfers it
      LEFT JOIN items i ON it.item_id = i.id
      LEFT JOIN warehouses fw ON it.from_warehouse_id = fw.id
      LEFT JOIN warehouses tw ON it.to_warehouse_id = tw.id
      ORDER BY it.date DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getExpiringItems({int daysThreshold = 30}) async {
    final db = await database;
    final threshold = DateTime.now().add(Duration(days: daysThreshold)).toIso8601String().split('T')[0];
    return await db.rawQuery('''
      SELECT ib.*, i.name as item_name, w.name as warehouse_name
      FROM inventory_batches ib
      LEFT JOIN items i ON ib.item_id = i.id
      LEFT JOIN warehouses w ON ib.warehouse_id = w.id
      WHERE ib.expiry_date IS NOT NULL AND ib.expiry_date <= ? AND ib.quantity > 0
      ORDER BY ib.expiry_date ASC
    ''', [threshold]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  SYSTEM USERS & PERMISSIONS (Auth Module)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getSystemUsers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT su.*, e.name as employee_name
      FROM system_users su
      LEFT JOIN employees e ON su.employee_id = e.id
      WHERE su.is_active = 1
      ORDER BY su.username ASC
    ''');
  }

  Future<void> addSystemUser(Map<String, dynamic> user) async {
    final db = await database;
    user['id'] ??= 'USR_${DateTime.now().millisecondsSinceEpoch}';
    user['created_at'] = DateTime.now().toIso8601String();
    user['is_active'] = 1;
    await db.insert('system_users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSystemUser(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('system_users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deactivateSystemUser(String id) async {
    final db = await database;
    await db.update('system_users', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> authenticateSystemUser(String username, String passwordHash) async {
    final db = await database;
    final res = await db.query('system_users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash]);
    return res.isNotEmpty ? res.first : null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  SALES AGENTS & COMMISSIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getSalesAgents() async {
    final db = await database;
    return await db.query('sales_agents', where: "status = 'active'", orderBy: 'name ASC');
  }

  Future<void> addSalesAgent(Map<String, dynamic> agent) async {
    final db = await database;
    agent['id'] ??= 'SA_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('sales_agents', agent, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSalesTargets({String? agentId}) async {
    final db = await database;
    if (agentId != null) {
      return await db.query('sales_targets', where: 'agent_id = ?', whereArgs: [agentId], orderBy: 'month DESC');
    }
    return await db.query('sales_targets', orderBy: 'start_date DESC');
  }

  Future<void> addSalesTarget(Map<String, dynamic> target) async {
    final db = await database;
    target['id'] ??= 'ST_${DateTime.now().millisecondsSinceEpoch}';
    target['created_at'] = DateTime.now().toIso8601String();
    await db.insert('sales_targets', target, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCommissions({String? employeeId}) async {
    final db = await database;
    if (employeeId != null) {
      return await db.query('commissions', where: 'employee_id = ?', whereArgs: [employeeId], orderBy: 'created_at DESC');
    }
    return await db.query('commissions', orderBy: 'created_at DESC');
  }

  Future<void> addCommission(Map<String, dynamic> commission) async {
    final db = await database;
    commission['id'] ??= 'COM_${DateTime.now().millisecondsSinceEpoch}';
    commission['created_at'] = DateTime.now().toIso8601String();
    await db.insert('commissions', commission, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> calculateSalesCommission(String invoiceId, String employeeId, double percentage) async {
    final db = await database;
    final inv = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    if (inv.isEmpty) return;

    final double total = (inv.first['total'] as num?)?.toDouble() ?? 0;
    final double commissionAmount = total * (percentage / 100);

    await addCommission({
      'employee_id': employeeId,
      'invoice_id': invoiceId,
      'amount': commissionAmount,
      'percentage': percentage,
      'status': 'PENDING',
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  JOB APPLICATIONS (Recruitment Module)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getJobApplications({String? status}) async {
    final db = await database;
    if (status != null) {
      return await db.query('job_applications', where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
    }
    return await db.query('job_applications', orderBy: 'created_at DESC');
  }

  Future<void> addJobApplication(Map<String, dynamic> app) async {
    final db = await database;
    app['id'] ??= 'JA_${DateTime.now().millisecondsSinceEpoch}';
    app['created_at'] = DateTime.now().toIso8601String();
    app['status'] ??= 'NEW';
    await db.insert('job_applications', app, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateJobApplicationStatus(String id, String status, {String? interviewDate}) async {
    final db = await database;
    final data = <String, dynamic>{'status': status};
    if (interviewDate != null) data['interview_date'] = interviewDate;
    await db.update('job_applications', data, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  PROMOTIONAL CAMPAIGNS (Marketing Module)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getPromotionalCampaigns({bool activeOnly = true}) async {
    final db = await database;
    if (activeOnly) {
      return await db.query('promotional_campaigns', where: 'is_active = 1', orderBy: 'start_date DESC');
    }
    return await db.query('promotional_campaigns', orderBy: 'start_date DESC');
  }

  Future<void> addPromotionalCampaign(Map<String, dynamic> campaign) async {
    final db = await database;
    campaign['id'] ??= 'PROMO_${DateTime.now().millisecondsSinceEpoch}';
    campaign['created_at'] = DateTime.now().toIso8601String();
    campaign['is_active'] = 1;
    await db.insert('promotional_campaigns', campaign, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  ACCOUNTS (Chart of Accounts - Full CRUD)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAccounts({String? type}) async {
    final db = await database;
    if (type != null) {
      return await db.query('accounts', where: 'type = ?', whereArgs: [type], orderBy: 'code ASC');
    }
    return await db.query('accounts', orderBy: 'code ASC');
  }

  Future<void> addAccount(Map<String, dynamic> account) async {
    final db = await database;
    await db.insert('accounts', account, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  TRIAL BALANCE & FINANCIAL STATEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getTrialBalance(String endDate) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        a.id, a.code, a.name, a.type,
        COALESCE(SUM(jel.debit), 0) as total_debit,
        COALESCE(SUM(jel.credit), 0) as total_credit,
        COALESCE(SUM(jel.debit) - SUM(jel.credit), 0) as balance
      FROM accounts a
      LEFT JOIN journal_entry_lines jel ON a.id = jel.account_id
      LEFT JOIN journal_entries je ON jel.entry_id = je.id AND je.date <= ?
      GROUP BY a.id, a.code, a.name, a.type
      HAVING total_debit > 0 OR total_credit > 0
      ORDER BY a.code ASC
    ''', [endDate]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  CLIENTS CRUD (Full Management)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addClient(Map<String, dynamic> client) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    client['id'] ??= 'CLI_${DateTime.now().millisecondsSinceEpoch}';
    client['sync_status'] = 0;
    client['updated_at'] = DateTime.now().toIso8601String();
    client['device_id'] = deviceId;
    client['is_deleted'] = 0;
    await db.insert('clients', client, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('clients', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.update('clients', {
      'is_deleted': 1, 'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    await AuditService.log(action: 'delete', entityType: 'client', entityId: id);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  SUPPLIERS CRUD (Full Management)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    supplier['id'] ??= 'SUP_${DateTime.now().millisecondsSinceEpoch}';
    supplier['sync_status'] = 0;
    supplier['updated_at'] = DateTime.now().toIso8601String();
    supplier['device_id'] = await getDeviceFingerprint();
    supplier['is_deleted'] = 0;
    await db.insert('suppliers', supplier, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('suppliers', data, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  INVOICES (Full Query Methods)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getInvoices({String? clientId, String? status, int limit = 50}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (clientId != null) { where += ' AND client_id = ?'; args.add(clientId); }
    if (status != null) { where += ' AND status = ?'; args.add(status); }
    return await db.query('invoices', where: where, whereArgs: args, orderBy: 'issue_date DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getInvoiceLines(String invoiceId) async {
    final db = await database;
    return await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  Future<List<Map<String, dynamic>>> getPurchaseInvoices({String? supplierId, int limit = 50}) async {
    final db = await database;
    if (supplierId != null) {
      return await db.query('purchase_invoices', where: 'supplier_id = ?', whereArgs: [supplierId], orderBy: 'issue_date DESC', limit: limit);
    }
    return await db.query('purchase_invoices', orderBy: 'issue_date DESC', limit: limit);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  ASSETS (Full CRUD + Depreciation)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAssets({String? status}) async {
    final db = await database;
    if (status != null) {
      return await db.query('assets', where: 'status = ?', whereArgs: [status], orderBy: 'name ASC');
    }
    return await db.query('assets', orderBy: 'name ASC');
  }

  Future<void> addAsset(Map<String, dynamic> asset) async {
    final db = await database;
    final deviceId = await getDeviceFingerprint();
    asset['id'] ??= 'ASSET_${DateTime.now().millisecondsSinceEpoch}';
    asset['sync_status'] = 0;
    asset['updated_at'] = DateTime.now().toIso8601String();
    asset['device_id'] = deviceId;
    asset['is_deleted'] = 0;
    await db.insert('assets', asset, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAsset(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('assets', data, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  JOURNAL ENTRIES (Full Query)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getJournalEntries({int limit = 50}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT je.*, COALESCE(SUM(jel.debit), 0) as total_debit
      FROM journal_entries je
      LEFT JOIN journal_entry_lines jel ON je.id = jel.entry_id
      GROUP BY je.id
      ORDER BY je.date DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getJournalEntryLines(String entryId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT jel.*, a.name as account_name, a.code as account_code
      FROM journal_entry_lines jel
      LEFT JOIN accounts a ON jel.account_id = a.id
      WHERE jel.entry_id = ?
    ''', [entryId]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  SALARY SLIPS (Payroll)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getSalarySlips({String? employeeId, String? month}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (employeeId != null) { where += ' AND employee_id = ?'; args.add(employeeId); }
    if (month != null) { where += ' AND month = ?'; args.add(month); }
    return await db.query('salary_slips', where: where, whereArgs: args, orderBy: 'month DESC');
  }

  Future<void> generateSalarySlip(Map<String, dynamic> slip) async {
    final db = await database;
    slip['id'] ??= 'SS_${DateTime.now().millisecondsSinceEpoch}';
    slip['status'] = 'paid';
    slip['payment_date'] = DateTime.now().toIso8601String();
    await db.insert('salary_slips', slip, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  COST CENTERS (Full CRUD)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addCostCenter(Map<String, dynamic> cc) async {
    final db = await database;
    cc['id'] ??= 'CC_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('cost_centers', cc, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCostCenter(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('cost_centers', data, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  PROJECTS (Full CRUD)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final db = await database;
    data['sync_status'] = 0;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('projects', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.update('projects', {
      'status': 'archived', 'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    await AuditService.log(action: 'delete', entityType: 'project', entityId: id);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  LOW STOCK ALERTS (QuickBooks Inventory Alerts)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM items
      WHERE quantity <= min_stock_level AND quantity >= 0
      ORDER BY quantity ASC
    ''');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ██  CHEQUES (Full CRUD)
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getCheques({String? status, String? type}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];
    if (status != null) { where += ' AND status = ?'; args.add(status); }
    if (type != null) { where += ' AND type = ?'; args.add(type); }
    return await db.query('cheques', where: where, whereArgs: args, orderBy: 'due_date ASC');
  }

  Future<void> addCheque(Map<String, dynamic> cheque) async {
    final db = await database;
    cheque['id'] ??= 'CHQ_${DateTime.now().millisecondsSinceEpoch}';
    cheque['sync_status'] = 0;
    cheque['updated_at'] = DateTime.now().toIso8601String();
    cheque['device_id'] = await getDeviceFingerprint();
    cheque['is_deleted'] = 0;
    await db.insert('cheques', cheque, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateChequeStatus(String id, String status) async {
    final db = await database;
    await db.update('cheques', {
      'status': status,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // Phase 2: Core Feature Gap Methods
  // ============================================================

  /// Register a payment to a supplier (reduces supplier balance + journal entry)
  Future<void> registerSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentAccountId,
    String? notes,
  }) async {
    final db = await database;
    final paymentId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
    final dateIso = DateTime.now().toIso8601String().split('T')[0];

    await db.transaction((txn) async {
      // 1. Record Payment
      await txn.insert('payments', {
        'id': paymentId,
        'partner_id': supplierId,
        'partner_type': 'supplier',
        'amount': amount,
        'type': 'payment',
        'date': dateIso,
      });

      // 2. Reduce Supplier Balance
      await txn.rawUpdate(
        'UPDATE suppliers SET balance = balance - ? WHERE id = ?',
        [amount, supplierId],
      );

      // 3. Journal Entry: Debit Payable, Credit Bank/Cash
      final entryId = 'JRN_PAY_${DateTime.now().millisecondsSinceEpoch}';
      await txn.insert('journal_entries', {
        'id': entryId,
        'date': dateIso,
        'description': 'سداد مورد - $paymentId${notes != null ? " ($notes)" : ""}',
        'reference_id': paymentId,
      });
      await txn.insert('journal_entry_lines', {
        'id': 'JEL_D_${DateTime.now().microsecondsSinceEpoch}',
        'entry_id': entryId,
        'account_id': 'ACC_PAYABLE',
        'debit': amount,
        'credit': 0,
      });
      await txn.insert('journal_entry_lines', {
        'id': 'JEL_C_${DateTime.now().microsecondsSinceEpoch}',
        'entry_id': entryId,
        'account_id': paymentAccountId,
        'debit': 0,
        'credit': amount,
      });

      // 4. Update Account Balances
      await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, 'ACC_PAYABLE']);
      await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, paymentAccountId]);
    });
  }

  /// Recalculate commissions for all agents in a given month (YYYY-MM)
  Future<void> recalculateAgentCommissions(String month) async {
    final db = await database;

    // 1. Get all sales from invoices grouped by agent
    final sales = await db.rawQuery('''
      SELECT sales_agent_id, SUM(total) as total_sales
      FROM invoices
      WHERE sales_agent_id IS NOT NULL
        AND issue_date LIKE ?
        AND is_return = 0
      GROUP BY sales_agent_id
    ''', ['$month%']);

    for (var row in sales) {
      final agentId = row['sales_agent_id'] as String;
      final totalSales = (row['total_sales'] as num?)?.toDouble() ?? 0.0;

      // 2. Get agent commission rate
      final agentRes = await db.query('sales_agents', where: 'id = ?', whereArgs: [agentId]);
      if (agentRes.isEmpty) continue;
      final rate = (agentRes.first['commission_rate'] as num?)?.toDouble() ?? 0.0;
      final commissionEarned = totalSales * rate / 100;

      // 3. Update or create sales target for this month
      final targetId = 'TGT_${agentId}_$month';
      final existingTarget = await db.query('sales_targets', where: 'id = ?', whereArgs: [targetId]);

      if (existingTarget.isNotEmpty) {
        await db.update('sales_targets', {
          'achieved_amount': totalSales,
          'commission_earned': commissionEarned,
          'status': totalSales >= (existingTarget.first['target_amount'] as num? ?? 0) ? 'achieved' : 'pending',
        }, where: 'id = ?', whereArgs: [targetId]);
      } else {
        await db.insert('sales_targets', {
          'id': targetId,
          'agent_id': agentId,
          'month': month,
          'target_amount': 0,
          'achieved_amount': totalSales,
          'commission_earned': commissionEarned,
          'status': 'pending',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  /// Get invoices linked to a specific sales agent in a given month
  Future<List<Map<String, dynamic>>> getAgentInvoices(String agentId, String month) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT i.*, c.name as client_name
      FROM invoices i
      LEFT JOIN clients c ON i.client_id = c.id
      WHERE i.sales_agent_id = ?
        AND i.issue_date LIKE ?
        AND i.is_return = 0
      ORDER BY i.issue_date DESC
    ''', [agentId, '$month%']);
  }


  /// Create a promotional campaign for an expiring product
  Future<void> createExpiryPromotion({
    required String itemId,
    required double discountPercent,
    required int campaignDays,
  }) async {
    final db = await database;
    final now = DateTime.now();
    await db.insert('promotional_campaigns', {
      'id': 'PROMO_${now.millisecondsSinceEpoch}',
      'item_id': itemId,
      'discount_type': 'percentage',
      'discount_value': discountPercent,
      'start_date': now.toIso8601String().split('T')[0],
      'end_date': now.add(Duration(days: campaignDays)).toIso8601String().split('T')[0],
      'is_active': 1,
      'created_at': now.toIso8601String(),
    });
  }

  /// Transfer an inventory batch to another warehouse
  Future<void> transferBatch({
    required String batchId,
    required String toWarehouseId,
  }) async {
    final db = await database;
    final dateIso = DateTime.now().toIso8601String().split('T')[0];

    await db.transaction((txn) async {
      // 1. Get batch info
      final batch = await txn.query('inventory_batches', where: 'id = ?', whereArgs: [batchId]);
      if (batch.isEmpty) return;
      final fromWarehouseId = batch.first['warehouse_id'] as String;
      final itemId = batch.first['item_id'] as String;
      final quantity = (batch.first['quantity'] as num?)?.toDouble() ?? 0;

      // 2. Update batch warehouse
      await txn.update('inventory_batches', {
        'warehouse_id': toWarehouseId,
      }, where: 'id = ?', whereArgs: [batchId]);

      // 3. Record transfer
      await txn.insert('inventory_transfers', {
        'id': 'TRF_${DateTime.now().millisecondsSinceEpoch}',
        'item_id': itemId,
        'from_warehouse_id': fromWarehouseId,
        'to_warehouse_id': toWarehouseId,
        'quantity': quantity,
        'date': dateIso,
        'status': 'completed',
      });
    });
  }

  /// Approve a draft invoice — create real purchase invoice from draft data
  Future<bool> approveDraftInvoice(String draftId) async {
    final db = await database;

    final drafts = await db.query('draft_invoices', where: 'id = ?', whereArgs: [draftId]);
    if (drafts.isEmpty) return false;
    final draft = drafts.first;

    final total = (draft['total_amount'] as num?)?.toDouble() ?? 0;
    final supplierName = draft['supplier_name'] as String? ?? 'مورد غير معروف';

    // 1. Find or create supplier
    var suppliers = await db.query('suppliers', where: 'name = ?', whereArgs: [supplierName]);
    String supplierId;
    if (suppliers.isEmpty) {
      supplierId = 'SUP_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('suppliers', {
        'id': supplierId,
        'name': supplierName,
        'balance': 0,
      });
    } else {
      supplierId = suppliers.first['id'] as String;
    }

    // 2. Create purchase invoice (QuickBooks style: total only, items added later)
    await savePurchaseInvoice(
      supplierId: supplierId,
      total: total,
      paymentType: 'credit',
      lines: [],
    );

    // 3. Mark draft as approved
    await db.update('draft_invoices', {
      'status': 'approved',
    }, where: 'id = ?', whereArgs: [draftId]);

    return true;
  }

  /// Reject/archive a draft invoice
  Future<void> rejectDraftInvoice(String draftId) async {
    final db = await database;
    await db.update('draft_invoices', {
      'status': 'rejected',
    }, where: 'id = ?', whereArgs: [draftId]);
  }

  // ══════════════════════════════════════════════════════════════════
  // 🔒 الأنظمة الأربعة الأساسية — قاعدة بيانات شاملة
  // ══════════════════════════════════════════════════════════════════

  /// Ensure core tables exist for the 4 systems
  Future<void> _ensureCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feasibility_studies (
        id TEXT PRIMARY KEY,
        project_name TEXT NOT NULL,
        sector TEXT,
        country TEXT,
        capital REAL DEFAULT 0,
        monthly_costs REAL DEFAULT 0,
        monthly_revenue REAL DEFAULT 0,
        study_years INTEGER DEFAULT 5,
        discount_rate REAL DEFAULT 0.10,
        npv REAL,
        irr REAL,
        payback_months INTEGER,
        success_rate REAL,
        scenario TEXT DEFAULT 'moderate',
        notes TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tax_filings (
        id TEXT PRIMARY KEY,
        period_label TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        country TEXT DEFAULT 'السعودية',
        tax_rate REAL DEFAULT 0.15,
        total_sales_tax REAL DEFAULT 0,
        total_purchase_tax REAL DEFAULT 0,
        net_tax_due REAL DEFAULT 0,
        status TEXT DEFAULT 'draft',
        filed_at TEXT,
        notes TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
  }

  // ─────────────────────────────────────────────────
  // 📊 1. نظام الحسابات الشامل
  // ─────────────────────────────────────────────────

  /// Get the full Chart of Accounts
  Future<List<Map<String, dynamic>>> getChartOfAccounts() async {
    final db = await database;
    return await db.query('accounts', orderBy: 'code ASC');
  }

  /// Update an existing account
  Future<void> updateAccount(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('accounts', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete an account (only if no journal lines reference it)
  Future<bool> deleteAccount(String id) async {
    final db = await database;
    final refs = await db.rawQuery(
      'SELECT COUNT(*) as c FROM journal_entry_lines WHERE account_id = ?', [id]
    );
    if ((refs.first['c'] as int) > 0) return false;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  /// Get ledger (all movements) for a specific account
  Future<List<Map<String, dynamic>>> getAccountLedger(String accountId, {String? fromDate, String? toDate}) async {
    final db = await database;
    String where = 'jl.account_id = ?';
    List<dynamic> args = [accountId];
    if (fromDate != null) { where += ' AND je.date >= ?'; args.add(fromDate); }
    if (toDate != null) { where += ' AND je.date <= ?'; args.add(toDate); }
    
    return await db.rawQuery('''
      SELECT jl.*, je.date, je.description,
        COALESCE(a.name, jl.account_name, 'غير محدد') as display_name
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      LEFT JOIN accounts a ON jl.account_id = a.id
      WHERE $where
      ORDER BY je.date DESC
    ''', args);
  }

  /// Get financial position (Balance Sheet) 
  Future<Map<String, dynamic>> getFinancialPosition() async {
    final db = await database;
    
    // Assets
    final assets = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'asset'
    ''');
    // Liabilities
    final liabilities = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'liability'
    ''');
    // Revenue
    final revenue = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'revenue'
    ''');
    // Expenses
    final expenses = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE type = 'expense'
    ''');
    
    final totalAssets = (assets.first['total'] as num?)?.toDouble() ?? 0;
    final totalLiabilities = (liabilities.first['total'] as num?)?.toDouble() ?? 0;
    final totalRevenue = (revenue.first['total'] as num?)?.toDouble() ?? 0;
    final totalExpenses = (expenses.first['total'] as num?)?.toDouble() ?? 0;
    final netProfit = totalRevenue - totalExpenses;
    final equity = totalAssets - totalLiabilities;
    
    // Get individual accounts by type
    final assetAccounts = await db.query('accounts', where: 'type = ?', whereArgs: ['asset'], orderBy: 'code ASC');
    final liabilityAccounts = await db.query('accounts', where: 'type = ?', whereArgs: ['liability'], orderBy: 'code ASC');
    final revenueAccounts = await db.query('accounts', where: 'type = ?', whereArgs: ['revenue'], orderBy: 'code ASC');
    final expenseAccounts = await db.query('accounts', where: 'type = ?', whereArgs: ['expense'], orderBy: 'code ASC');
    
    return {
      'total_assets': totalAssets,
      'total_liabilities': totalLiabilities,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'equity': equity,
      'asset_accounts': assetAccounts,
      'liability_accounts': liabilityAccounts,
      'revenue_accounts': revenueAccounts,
      'expense_accounts': expenseAccounts,
    };
  }

  /// Get Income Statement (P&L) for a period
  Future<Map<String, dynamic>> getIncomeStatement({String? fromDate, String? toDate}) async {
    final db = await database;
    String dateFilter = '';
    List<dynamic> args = [];
    if (fromDate != null && toDate != null) {
      dateFilter = 'AND je.date BETWEEN ? AND ?';
      args = [fromDate, toDate];
    }

    final revenue = await db.rawQuery('''
      SELECT a.id, a.code, a.name, COALESCE(SUM(jl.credit - jl.debit), 0) as net_amount
      FROM accounts a
      LEFT JOIN journal_entry_lines jl ON a.id = jl.account_id
      LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id
      WHERE a.type = 'revenue' $dateFilter
      GROUP BY a.id
      ORDER BY a.code
    ''', args);

    final expenses = await db.rawQuery('''
      SELECT a.id, a.code, a.name, COALESCE(SUM(jl.debit - jl.credit), 0) as net_amount
      FROM accounts a
      LEFT JOIN journal_entry_lines jl ON a.id = jl.account_id
      LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id
      WHERE a.type = 'expense' $dateFilter
      GROUP BY a.id
      ORDER BY a.code
    ''', args);

    final totalRevenue = revenue.fold<double>(0, (s, r) => s + ((r['net_amount'] as num?)?.toDouble() ?? 0));
    final totalExpenses = expenses.fold<double>(0, (s, r) => s + ((r['net_amount'] as num?)?.toDouble() ?? 0));

    return {
      'revenue_items': revenue,
      'expense_items': expenses,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': totalRevenue - totalExpenses,
    };
  }

  // ─────────────────────────────────────────────────
  // 🧾 2. نظام الضرائب الشامل
  // ─────────────────────────────────────────────────

  /// Get tax summary: sales VAT vs purchase VAT from real invoices
  Future<Map<String, dynamic>> getTaxSummary({String? fromDate, String? toDate}) async {
    final db = await database;
    String dateFilter = '';
    List<dynamic> args = [];
    if (fromDate != null && toDate != null) {
      dateFilter = "WHERE issue_date BETWEEN ? AND ?";
      args = [fromDate, toDate];
    }

    // Sales VAT (collected)
    final salesVat = await db.rawQuery('''
      SELECT COALESCE(SUM(tax_amount), 0) as total,
             COUNT(*) as invoice_count,
             COALESCE(SUM(total), 0) as total_sales
      FROM invoices $dateFilter
    ''', args);
    
    // Purchase VAT (paid) 
    final purchaseVat = await db.rawQuery('''
      SELECT COALESCE(SUM(tax_amount), 0) as total,
             COUNT(*) as invoice_count,
             COALESCE(SUM(total), 0) as total_purchases
      FROM purchase_invoices ${dateFilter.isNotEmpty ? dateFilter : ''}
    ''', dateFilter.isNotEmpty ? args : []);

    final salesTax = (salesVat.first['total'] as num?)?.toDouble() ?? 0;
    final purchaseTax = (purchaseVat.first['total'] as num?)?.toDouble() ?? 0;
    
    return {
      'sales_tax': salesTax,
      'purchase_tax': purchaseTax,
      'net_tax_due': salesTax - purchaseTax,
      'sales_count': salesVat.first['invoice_count'] ?? 0,
      'purchase_count': purchaseVat.first['invoice_count'] ?? 0,
      'total_sales': (salesVat.first['total_sales'] as num?)?.toDouble() ?? 0,
      'total_purchases': (purchaseVat.first['total_purchases'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Get all taxable invoices for a period
  Future<List<Map<String, dynamic>>> getTaxableInvoices({String? fromDate, String? toDate, String type = 'all'}) async {
    final db = await database;
    List<Map<String, dynamic>> result = [];
    
    if (type == 'all' || type == 'sales') {
      String where = 'tax_amount > 0';
      List<dynamic> args = [];
      if (fromDate != null) { where += ' AND issue_date >= ?'; args.add(fromDate); }
      if (toDate != null) { where += ' AND issue_date <= ?'; args.add(toDate); }
      final sales = await db.query('invoices', where: where, whereArgs: args, orderBy: 'issue_date DESC');
      for (var s in sales) { result.add({...s, 'inv_type': 'sales'}); }
    }
    
    if (type == 'all' || type == 'purchase') {
      String where = 'tax_amount > 0';
      List<dynamic> args = [];
      if (fromDate != null) { where += ' AND issue_date >= ?'; args.add(fromDate); }
      if (toDate != null) { where += ' AND issue_date <= ?'; args.add(toDate); }
      final purchases = await db.query('purchase_invoices', where: where, whereArgs: args, orderBy: 'issue_date DESC');
      for (var p in purchases) { result.add({...p, 'inv_type': 'purchase'}); }
    }
    
    result.sort((a, b) => (b['issue_date'] ?? '').compareTo(a['issue_date'] ?? ''));
    return result;
  }

  /// Save a tax filing record
  Future<void> saveTaxFiling(Map<String, dynamic> filing) async {
    final db = await database;
    await _ensureCoreTables(db);
    await db.insert('tax_filings', filing, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all tax filings
  Future<List<Map<String, dynamic>>> getTaxFilings() async {
    final db = await database;
    await _ensureCoreTables(db);
    return await db.query('tax_filings', orderBy: 'start_date DESC');
  }

  // ─────────────────────────────────────────────────
  // 🔍 3. نظام التدقيق الشامل
  // ─────────────────────────────────────────────────

  /// Find unbalanced journal entries (debit != credit)
  Future<List<Map<String, dynamic>>> getUnbalancedEntries() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT je.id, je.description, je.date,
        SUM(jl.debit) as total_debit, 
        SUM(jl.credit) as total_credit,
        ABS(SUM(jl.debit) - SUM(jl.credit)) as imbalance
      FROM journal_entries je
      JOIN journal_entry_lines jl ON je.id = jl.journal_entry_id
      GROUP BY je.id
      HAVING ABS(SUM(jl.debit) - SUM(jl.credit)) > 0.01
      ORDER BY je.date DESC
    ''');
  }

  /// Find potential duplicate payments (same amount + same date + same supplier)
  Future<List<Map<String, dynamic>>> getDuplicatePayments() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT supplier_name, total, issue_date, COUNT(*) as occurrence_count,
        GROUP_CONCAT(id) as invoice_ids
      FROM purchase_invoices
      WHERE total > 0
      GROUP BY supplier_name, total, issue_date
      HAVING COUNT(*) > 1
      ORDER BY issue_date DESC
    ''');
  }

  /// Find budget overruns (actual > budget for any account)
  Future<List<Map<String, dynamic>>> getBudgetOverruns() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.account_id, a.name as account_name, a.code,
        b.budget_amount,
        COALESCE(SUM(jl.debit), 0) as actual_amount,
        COALESCE(SUM(jl.debit), 0) - b.budget_amount as overrun
      FROM budgets b
      JOIN accounts a ON b.account_id = a.id
      LEFT JOIN journal_entry_lines jl ON b.account_id = jl.account_id
      LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id
        AND je.date BETWEEN b.start_date AND b.end_date
      GROUP BY b.account_id
      HAVING COALESCE(SUM(jl.debit), 0) > b.budget_amount
    ''');
  }

  /// Get audit trail — recent changes and suspicious activity
  Future<Map<String, dynamic>> getAuditSummary() async {
    final db = await database;
    
    final unbalanced = await getUnbalancedEntries();
    final duplicates = await getDuplicatePayments();
    final overruns = await getBudgetOverruns();
    
    // Large individual transactions (top 10)
    final largeTransactions = await db.rawQuery('''
      SELECT je.id, je.description, je.date, jl.debit, jl.credit, 
        COALESCE(a.name, jl.account_name) as account_name
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      LEFT JOIN accounts a ON jl.account_id = a.id
      WHERE jl.debit > 10000 OR jl.credit > 10000
      ORDER BY COALESCE(jl.debit, 0) + COALESCE(jl.credit, 0) DESC
      LIMIT 10
    ''');
    
    // Total entries and recent entries count
    final totalEntries = await db.rawQuery('SELECT COUNT(*) as c FROM journal_entries');
    final recentEntries = await db.rawQuery('''
      SELECT COUNT(*) as c FROM journal_entries 
      WHERE date >= date('now', '-30 days')
    ''');
    
    final totalIssues = unbalanced.length + duplicates.length + overruns.length;
    final safetyScore = totalIssues == 0 ? 100.0 : 
      (100.0 - (totalIssues * 5)).clamp(0.0, 100.0);
    
    return {
      'unbalanced_entries': unbalanced,
      'duplicate_payments': duplicates,
      'budget_overruns': overruns,
      'large_transactions': largeTransactions,
      'total_entries': (totalEntries.first['c'] as int?) ?? 0,
      'recent_entries': (recentEntries.first['c'] as int?) ?? 0,
      'total_issues': totalIssues,
      'safety_score': safetyScore,
    };
  }

  // ─────────────────────────────────────────────────
  // 📈 4. نظام دراسات الجدوى
  // ─────────────────────────────────────────────────

  /// Save a feasibility study
  Future<void> saveFeasibilityStudy(Map<String, dynamic> study) async {
    final db = await database;
    await _ensureCoreTables(db);
    await db.insert('feasibility_studies', study, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all saved feasibility studies
  Future<List<Map<String, dynamic>>> getFeasibilityStudies() async {
    final db = await database;
    await _ensureCoreTables(db);
    return await db.query('feasibility_studies', orderBy: 'created_at DESC');
  }

  /// Delete a feasibility study
  // ─────────────────────────────────────────────────
  // 📄 5. نظام عروض الأسعار (Quotations)
  // ─────────────────────────────────────────────────

  Future<void> addQuotation(Map<String, dynamic> quotation, List<Map<String, dynamic>> lines) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('quotations', quotation, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var line in lines) {
        await txn.insert('quotation_lines', line, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getQuotations() async {
    final db = await database;
    return await db.query('quotations', where: 'is_deleted = 0', orderBy: 'issue_date DESC');
  }

  Future<void> convertQuotationToInvoice(String quotationId, String invoiceId) async {
    final db = await database;
    await db.update('quotations', {
      'status': 'converted',
      'converted_invoice_id': invoiceId,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [quotationId]);
  }

  // ─────────────────────────────────────────────────
  // 💸 6. سندات القبض والدفع (Vouchers)
  // ─────────────────────────────────────────────────

  Future<void> addReceiptVoucher(Map<String, dynamic> voucher) async {
    if (await isDateLocked(voucher['date'] ?? '')) {
      throw Exception("لا يمكن إضافة سند قبض في فترة محاسبية مغلقة.");
    }
    final db = await database;
    await db.insert('receipt_vouchers', voucher, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getReceiptVouchers() async {
    final db = await database;
    return await db.query('receipt_vouchers', where: 'is_deleted = 0', orderBy: 'date DESC');
  }

  Future<void> addPaymentVoucher(Map<String, dynamic> voucher) async {
    if (await isDateLocked(voucher['date'] ?? '')) {
      throw Exception("لا يمكن إضافة سند صرف في فترة محاسبية مغلقة.");
    }
    final db = await database;
    await db.insert('payment_vouchers', voucher, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPaymentVouchers() async {
    final db = await database;
    return await db.query('payment_vouchers', where: 'is_deleted = 0', orderBy: 'date DESC');
  }

  // ─────────────────────────────────────────────────
  // 🔄 7. الإشعارات الدائنة والمدينة (Credit Notes)
  // ─────────────────────────────────────────────────

  Future<void> addCreditNote(Map<String, dynamic> note) async {
    final db = await database;
    await db.insert('credit_notes', note, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCreditNotes() async {
    final db = await database;
    return await db.query('credit_notes', where: 'is_deleted = 0', orderBy: 'date DESC');
  }

  // ─────────────────────────────────────────────────
  // 📝 8. إدارة المهام (Tasks)
  // ─────────────────────────────────────────────────

  Future<void> addTask(Map<String, dynamic> task) async {
    final db = await database;
    await db.insert('tasks', task, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTasks({String? assignedTo}) async {
    final db = await database;
    if (assignedTo != null) {
      return await db.query('tasks', where: 'assigned_to = ? AND is_deleted = 0', whereArgs: [assignedTo]);
    }
    return await db.query('tasks', where: 'is_deleted = 0');
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final db = await database;
    await db.update('tasks', {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [taskId]);
  }

  // ─────────────────────────────────────────────────
  // 📂 9. إدارة المستندات (Documents)
  // ─────────────────────────────────────────────────

  Future<void> addDocument(Map<String, dynamic> doc) async {
    final db = await database;
    await db.insert('documents', doc, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getDocuments(String ownerId, String ownerType) async {
    final db = await database;
    return await db.query('documents', 
      where: 'owner_id = ? AND owner_type = ? AND is_deleted = 0', 
      whereArgs: [ownerId, ownerType]);
  }

  // ─────────────────────────────────────────────────
  // 🛡️ 10. سجل تتبع النظام (Audit Trail)
  // ─────────────────────────────────────────────────

  Future<void> addAuditTrailEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('audit_trail', entry);
  }

  Future<List<Map<String, dynamic>>> getAuditTrail({int limit = 100}) async {
    final db = await database;
    return await db.query('audit_trail', orderBy: 'timestamp DESC', limit: limit);
  }

  // ─────────────────────────────────────────────────
  // 🌍 11. العملات والسنة المالية
  // ─────────────────────────────────────────────────

  Future<void> addCurrencyRate(Map<String, dynamic> rate) async {
    final db = await database;
    await db.insert('currency_rates', rate, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<double> convertCurrency(String from, String to, double amount) async {
    final db = await database;
    final res = await db.query('currency_rates', 
      where: 'from_currency = ? AND to_currency = ?', 
      whereArgs: [from, to],
      orderBy: 'date DESC',
      limit: 1);
    
    if (res.isEmpty) return amount; // Default to 1:1 if no rate found
    final rate = (res.first['rate'] as num).toDouble();
    return amount * rate;
  }

  Future<void> addFiscalYear(Map<String, dynamic> fy) async {
    final db = await database;
    await db.insert('fiscal_years', fy, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> closeFiscalYear(String id, String journalEntryId) async {
    final db = await database;
    await db.update('fiscal_years', {
      'is_closed': 1,
      'closing_entry_id': journalEntryId,
    }, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a feasibility study
  Future<void> deleteFeasibilityStudy(String id) async {
    final db = await database;
    await db.delete('feasibility_studies', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────
  // 🏦 12. نظام التسوية البنكية (Bank Reconciliation)
  // ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAccountTransactions(String accountId, {String? fromDate, String? toDate}) async {
    final db = await database;
    String where = 'jl.account_id = ?';
    List<dynamic> args = [accountId];
    
    if (fromDate != null) {
      where += ' AND je.date >= ?';
      args.add(fromDate);
    }
    if (toDate != null) {
      where += ' AND je.date <= ?';
      args.add(toDate);
    }

    return await db.rawQuery('''
      SELECT jl.id as line_id, je.id as entry_id, je.date, je.description, 
             jl.debit, jl.credit, jl.reconciled
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      WHERE $where
      ORDER BY je.date DESC, je.id DESC
    ''', args);
  }

  Future<void> markAsReconciled(String lineId, int reconciled) async {
    final db = await database;
    await db.update('journal_entry_lines', {'reconciled': reconciled}, where: 'id = ?', whereArgs: [lineId]);
  }

  // ─────────────────────────────────────────────────
  // 🤖 13. AI Assistant Helper Methods
  // ─────────────────────────────────────────────────

  /// Fuzzy match account balance by name (e.g., 'خزينة' matches 'الخزينة العامة')
  Future<Map<String, dynamic>?> getAccountBalanceByName(String name) async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT name, balance FROM accounts WHERE name LIKE ? OR name LIKE ? OR name LIKE ? LIMIT 1",
      ['%$name%', '$name%', '%$name']
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Get pending (unpaid) invoices statistic
  Future<Map<String, dynamic>> getPendingInvoicesStats() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count, SUM(total) as total FROM invoices WHERE status != 'paid' AND is_deleted = 0"
    );
    return {
      'count': res.first['count'] ?? 0,
      'total': (res.first['total'] as num?)?.toDouble() ?? 0.0
    };
  }

  /// Check stock level for a product by name
  Future<Map<String, dynamic>?> checkProductStock(String productName) async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT name, quantity, unit FROM items WHERE name LIKE ? AND is_deleted = 0 LIMIT 1",
      ['%$productName%']
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Returns the absolute path to the database file (for backups)
  Future<String> getDatabasePath() async {
    if (Platform.isWindows) {
      final appSupportDir = await getApplicationSupportDirectory();
      return join(appSupportDir.path, _databaseName);
    } else {
      return join(await getDatabasesPath(), 'hisabati_offline.db');
    }
  }
}

