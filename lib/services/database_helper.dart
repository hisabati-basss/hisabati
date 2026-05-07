import 'dart:async';
import 'dart:convert';
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
import 'sync_engine.dart';
import 'notification_service.dart';
import '../core/accounting/coa_template.dart';
import 'industry_provider.dart';
import 'audit_service.dart';
import 'package:http/http.dart' as http;

// Mixin Imports
import 'db/mixins/db_base_mixin.dart';
import 'db/mixins/db_sales_mixin.dart';
import 'db/mixins/db_purchase_mixin.dart';
import 'db/mixins/db_hr_mixin.dart';
import 'db/mixins/db_accounting_mixin.dart';
import 'db/mixins/db_inventory_mixin.dart';
import 'db/mixins/db_real_estate_mixin.dart';
import 'db/mixins/db_medical_mixin.dart';
import 'db/mixins/db_manufacturing_mixin.dart';
import 'db/mixins/db_audit_mixin.dart';
import 'db/mixins/db_common_mixin.dart';
import 'db/mixins/db_specialized_mixin.dart';
import 'db/mixins/db_fleet_mixin.dart';
import 'db/mixins/db_approval_mixin.dart';
import 'db/mixins/db_contracting_mixin.dart';
import 'db/mixins/db_hospitality_mixin.dart';
import 'db/mixins/db_ecommerce_mixin.dart';
import 'db/mixins/db_agriculture_mixin.dart';
import 'db/mixins/db_office_services_mixin.dart';

class DatabaseHelper with 
    DbBaseMixin, 
    DbSalesMixin, 
    DbPurchaseMixin, 
    DbHrMixin, 
    DbAccountingMixin, 
    DbInventoryMixin, 
    DbRealEstateMixin, 
    DbManufacturingMixin, 
    DbAuditMixin, 
    DbCommonMixin,
    DbFleetMixin,
    DbApprovalMixin,
    DbContractingMixin,
    DbEcommerceMixin,
    DbMedicalMixin,
    DbHospitalityMixin,
    DbAgricultureMixin,
    DbOfficeServicesMixin,
    DbSpecializedMixin {

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
  static const int DB_VERSION = 143;

  Future<Database> _initDatabase() async {
    debugPrint("📂 Initializing database: version $DB_VERSION");
    
    // Force Web FFI
    if (kIsWeb) {
      debugPrint("🌐 Platform: Web (using sqlite3_ffi_web)");
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        _databaseName,
        version: DB_VERSION,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // Force FFI on desktop platforms if not already set
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      debugPrint("💻 Platform: Desktop (using sqlite3_ffi)");
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
    
    debugPrint("📍 Database path: $dbPath");

    final db = await openDatabase(
      dbPath,
      version: DB_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 🚀 INITIALIZE SYNC ENGINE
    try {
      final fingerprint = await getDeviceFingerprint();
      await SyncEngine().init(db, fingerprint);
      debugPrint("🚀 SyncEngine initialized successfully.");
    } catch (e) {
      debugPrint("⚠️ SyncEngine initialization failed: $e");
    }

    return db;
  }

  // Define metadata columns once to avoid repetition
  static const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, created_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';

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

    if (oldVersion < 138) {
      // v138: Professional Fleet & Agriculture Extensions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fleet_fuel_logs (
          id TEXT PRIMARY KEY,
          vehicle_id TEXT,
          liter_count REAL DEFAULT 0,
          cost REAL DEFAULT 0,
          date TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS fleet_maintenance_logs (
          id TEXT PRIMARY KEY,
          vehicle_id TEXT,
          type TEXT,
          cost REAL DEFAULT 0,
          date TEXT,
          notes TEXT,
          status TEXT DEFAULT 'Completed',
          $metadata
        )
      ''');
      
      // Migrate existing fleet_maintenance data if any
      try {
        await db.execute("INSERT INTO fleet_maintenance_logs (id, vehicle_id, type, cost, date, status) SELECT id, vehicle_id, task_name, date, cost, status FROM fleet_maintenance");
      } catch (_) {}
    }

    if (oldVersion < 102) {
      // v102: Multi-Branch & Bank Linking Support
      try { await db.execute("ALTER TABLE journal_entries ADD COLUMN branch_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE journal_entry_lines ADD COLUMN branch_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE assets ADD COLUMN current_branch_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE accounts ADD COLUMN bank_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE accounts ADD COLUMN bank_account_number TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE accounts ADD COLUMN iban TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE accounts ADD COLUMN branch_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE salary_slips ADD COLUMN branch_id TEXT"); } catch (_) {}
    }

    if (oldVersion < 103) {
      // Loan & Investment enhanced tracking
      try { await db.execute("ALTER TABLE employee_loans ADD COLUMN interest_rate REAL DEFAULT 0;"); } catch(_) {}
      try { await db.execute("ALTER TABLE employee_loans ADD COLUMN total_payable REAL DEFAULT 0;"); } catch(_) {}
      try { await db.execute("ALTER TABLE investments ADD COLUMN interest_rate REAL DEFAULT 0;"); } catch(_) {}
      try { await db.execute("ALTER TABLE inventory_transactions ADD COLUMN branch_id TEXT;"); } catch(_) {}
    }

    if (oldVersion < 104) {
      // --- HR Support ---
      await db.execute("CREATE TABLE IF NOT EXISTS departments (id TEXT PRIMARY KEY, name TEXT, manager_id TEXT, description TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS positions (id TEXT PRIMARY KEY, title TEXT, department_id TEXT, grade TEXT, salary_range TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS job_applications (id TEXT PRIMARY KEY, applicant_name TEXT, email TEXT, phone TEXT, position_id TEXT, status TEXT, applied_date TEXT, cv_path TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS employee_documents (id TEXT PRIMARY KEY, employee_id TEXT, title TEXT, type TEXT, expiry_date TEXT, file_path TEXT, is_deleted INTEGER DEFAULT 0)");
      
      // --- CRM Support ---
      await db.execute("CREATE TABLE IF NOT EXISTS crm_leads (id TEXT PRIMARY KEY, name TEXT, company TEXT, email TEXT, phone TEXT, source TEXT, status TEXT, assigned_to TEXT, created_at TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS crm_interactions (id TEXT PRIMARY KEY, lead_id TEXT, type TEXT, notes TEXT, date TEXT, next_follow_up TEXT, is_deleted INTEGER DEFAULT 0)");

      // --- Ops & Support ---
      await db.execute("CREATE TABLE IF NOT EXISTS support_tickets (id TEXT PRIMARY KEY, subject TEXT, description TEXT, priority TEXT, status TEXT, category TEXT, created_by TEXT, assigned_to TEXT, created_at TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS meetings (id TEXT PRIMARY KEY, title TEXT, date TEXT, time TEXT, location TEXT, attendees TEXT, minutes TEXT, status TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS workflows (id TEXT PRIMARY KEY, name TEXT, trigger_type TEXT, actions TEXT, is_active INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS approval_requests (id TEXT PRIMARY KEY, module TEXT, reference_id TEXT, requester_id TEXT, approver_id TEXT, status TEXT, notes TEXT, created_at TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS reminders (id TEXT PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT, priority TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS kpi_definitions (id TEXT PRIMARY KEY, title TEXT, target REAL, actual REAL, unit TEXT, period TEXT, department_id TEXT, is_deleted INTEGER DEFAULT 0)");
    }

    if (oldVersion < 105) {
      // --- Manufacturing Professional ---
      await db.execute("CREATE TABLE IF NOT EXISTS manufacturing_bom (id TEXT PRIMARY KEY, product_id TEXT, material_id TEXT, quantity REAL, cost_at_time REAL, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS manufacturing_stages (id TEXT PRIMARY KEY, order_id TEXT, stage_name TEXT, status TEXT, start_date TEXT, end_date TEXT, assigned_to TEXT, is_deleted INTEGER DEFAULT 0)");
      
      // --- Projects Professional ---
      await db.execute("CREATE TABLE IF NOT EXISTS project_stages (id TEXT PRIMARY KEY, project_id TEXT, title TEXT, status TEXT, progress REAL, start_date TEXT, end_date TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS project_payments (id TEXT PRIMARY KEY, project_id TEXT, title TEXT, amount REAL, due_date TEXT, status TEXT, is_deleted INTEGER DEFAULT 0)");

      // --- Real Estate Professional ---
      await db.execute("CREATE TABLE IF NOT EXISTS real_estate_rent_logs (id TEXT PRIMARY KEY, contract_id TEXT, period TEXT, amount REAL, due_date TEXT, status TEXT, paid_date TEXT, is_deleted INTEGER DEFAULT 0)");

      // --- Specialized Sectors ---
      await db.execute("CREATE TABLE IF NOT EXISTS hotel_rooms (id TEXT PRIMARY KEY, room_number TEXT, type TEXT, status TEXT, price_per_night REAL, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS hotel_bookings (id TEXT PRIMARY KEY, room_id TEXT, guest_name TEXT, check_in TEXT, check_out TEXT, total_price REAL, status TEXT, is_deleted INTEGER DEFAULT 0)");
      
      await db.execute("CREATE TABLE IF NOT EXISTS medical_patients (id TEXT PRIMARY KEY, name TEXT, phone TEXT, medical_history TEXT, created_at TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS medical_appointments (id TEXT PRIMARY KEY, patient_id TEXT, doctor_id TEXT, date TEXT, time TEXT, status TEXT, notes TEXT, is_deleted INTEGER DEFAULT 0)");

      await db.execute("CREATE TABLE IF NOT EXISTS fleet_vehicles (id TEXT PRIMARY KEY, plate_number TEXT, model TEXT, year INTEGER, chassis_number TEXT, status TEXT, last_service_date TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS fleet_maintenance (id TEXT PRIMARY KEY, vehicle_id TEXT, task_name TEXT, date TEXT, cost REAL, status TEXT, is_deleted INTEGER DEFAULT 0)");

      // --- Logistics ---
      await db.execute("CREATE TABLE IF NOT EXISTS shipments (id TEXT PRIMARY KEY, tracking_number TEXT, sender TEXT, receiver TEXT, origin TEXT, destination TEXT, status TEXT, estimated_delivery TEXT, is_deleted INTEGER DEFAULT 0)");
      
      // --- Joint Ventures ---
      await db.execute("CREATE TABLE IF NOT EXISTS joint_ventures (id TEXT PRIMARY KEY, name TEXT, total_capital REAL, status TEXT, created_at TEXT, is_deleted INTEGER DEFAULT 0)");
      await db.execute("CREATE TABLE IF NOT EXISTS joint_venture_partners (id TEXT PRIMARY KEY, venture_id TEXT, partner_name TEXT, share_percentage REAL, is_deleted INTEGER DEFAULT 0)");
    }

    if (oldVersion < 106) {
      // --- Contracting & Advanced Invoicing (Mustakhalasat) ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contracting_projects (
          id TEXT PRIMARY KEY, 
          name TEXT, 
          client_id TEXT, 
          total_value REAL, 
          advance_payment_pct REAL DEFAULT 0, 
          retention_pct REAL DEFAULT 0, 
          start_date TEXT, 
          end_date TEXT, 
          status TEXT DEFAULT 'active',
          current_completion_pct REAL DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS project_invoices (
          id TEXT PRIMARY KEY, 
          project_id TEXT, 
          invoice_number INTEGER, 
          period_start TEXT, 
          period_end TEXT, 
          work_completed_pct REAL, 
          total_completed_pct REAL, 
          material_on_site REAL DEFAULT 0, 
          advance_deduction REAL DEFAULT 0, 
          retention_deduction REAL DEFAULT 0, 
          net_amount REAL, 
          status TEXT DEFAULT 'draft',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS subcontractors (
          id TEXT PRIMARY KEY, 
          name TEXT, 
          trade TEXT, 
          phone TEXT, 
          email TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 107) {
      // --- Ecommerce System ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ecommerce_orders (
          id TEXT PRIMARY KEY, 
          order_number TEXT, 
          customer_name TEXT, 
          customer_phone TEXT, 
          total_amount REAL, 
          status TEXT DEFAULT 'pending',
          payment_status TEXT DEFAULT 'unpaid',
          shipping_address TEXT,
          platform TEXT DEFAULT 'Local',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ecommerce_order_items (
          id TEXT PRIMARY KEY, 
          order_id TEXT, 
          product_id TEXT, 
          product_name TEXT, 
          quantity REAL, 
          price REAL, 
          total REAL,
          $metadata
        )
      ''');
    }

    if (oldVersion < 108) {
      // --- Branch Management ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS branches (
          id TEXT PRIMARY KEY, 
          name TEXT, 
          location TEXT, 
          phone TEXT, 
          manager_id TEXT, 
          status TEXT DEFAULT 'active',
          $metadata
        )
      ''');
    }

    if (oldVersion < 109) {
      // --- Advanced Manufacturing ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_boms (
          id TEXT PRIMARY KEY,
          name TEXT,
          product_id TEXT,
          description TEXT,
          total_cost REAL DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_bom_lines (
          id TEXT PRIMARY KEY,
          bom_id TEXT,
          item_id TEXT,
          quantity REAL,
          unit_cost REAL,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_orders (
          id TEXT PRIMARY KEY,
          order_no TEXT,
          product_name TEXT,
          bom_id TEXT,
          qty_to_produce REAL,
          actual_qty_produced REAL DEFAULT 0,
          actual_material_cost REAL DEFAULT 0,
          actual_overhead_cost REAL DEFAULT 0,
          total_cost REAL DEFAULT 0,
          status TEXT DEFAULT 'pending',
          start_date TEXT,
          completed_at TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_cut_list (
          id TEXT PRIMARY KEY,
          order_id TEXT,
          width REAL,
          height REAL,
          quantity INTEGER,
          is_cut INTEGER DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS manufacturing_specifications (
          id TEXT PRIMARY KEY,
          order_id TEXT,
          type TEXT,
          value TEXT,
          $metadata
        )
      ''');
    }
    if (oldVersion < 110) {
      // --- Medical & Healthcare ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_patients (
          id TEXT PRIMARY KEY,
          name TEXT,
          phone TEXT,
          email TEXT,
          dob TEXT,
          gender TEXT,
          blood_group TEXT,
          medical_history TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_appointments (
          id TEXT PRIMARY KEY,
          patient_id TEXT,
          doctor_id TEXT,
          date TEXT,
          time TEXT,
          reason TEXT,
          status TEXT DEFAULT 'scheduled',
          notes TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_invoices (
          id TEXT PRIMARY KEY,
          patient_id TEXT,
          appointment_id TEXT,
          total_amount REAL,
          tax_amount REAL,
          discount REAL,
          net_amount REAL,
          status TEXT DEFAULT 'unpaid',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_medicines (
          id TEXT PRIMARY KEY,
          name TEXT,
          generic_name TEXT,
          category TEXT,
          stock_qty REAL,
          unit_price REAL,
          expiry_date TEXT,
          $metadata
        )
      ''');
    }
    if (oldVersion < 111) {
      // --- Hospitality & Hotel Management ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hotel_rooms (
          id TEXT PRIMARY KEY,
          room_number TEXT,
          type TEXT,
          floor TEXT,
          price_per_night REAL,
          status TEXT DEFAULT 'available', -- available, occupied, maintenance, dirty
          last_cleaned TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS hotel_bookings (
          id TEXT PRIMARY KEY,
          room_id TEXT, guest_name TEXT,
          guest_phone TEXT,
          check_in TEXT,
          check_out TEXT,
          total_price REAL,
          status TEXT DEFAULT 'confirmed', -- confirmed, checked_in, checked_out, cancelled
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS hotel_housekeeping (
          id TEXT PRIMARY KEY,
          room_id TEXT,
          staff_id TEXT,
          action TEXT, -- cleaning, laundry, repair
          status TEXT,
          notes TEXT,
          $metadata
        )
      ''');
    }
    if (oldVersion < 112) {
      // Ensure all tables have created_at (some were missed in previous migrations)
      final tablesToAddCreatedAt = [
        'contracting_projects', 'project_invoices', 'subcontractors',
        'hotel_rooms', 'hotel_bookings', 'hotel_housekeeping',
        'medical_patients', 'medical_appointments', 'medical_invoices', 'medical_medicines',
        'ecommerce_orders', 'ecommerce_order_items', 'branches',
        'manufacturing_boms', 'manufacturing_bom_lines', 'manufacturing_orders',
        'manufacturing_cut_list', 'manufacturing_specifications'
      ];
      
      for (var table in tablesToAddCreatedAt) {
        try {
          await db.execute("ALTER TABLE $table ADD COLUMN created_at TEXT");
        } catch (_) {
          // Column might already exist
        }
      }
      
      // Fix fleet_vehicles missing 'name' column which is queried in DbSpecializedMixin
      try {
        await db.execute("ALTER TABLE fleet_vehicles ADD COLUMN name TEXT");
        await db.execute("UPDATE fleet_vehicles SET name = model || ' ' || plate_number WHERE name IS NULL");
      } catch (_) {}
    }

    if (oldVersion < 113) {
      // --- Audit Alerts ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_alerts (
          id TEXT PRIMARY KEY,
          type TEXT,
          description TEXT,
          severity TEXT,
          status TEXT DEFAULT 'open',
          $metadata
        )
      ''');

      // --- Real Estate Fixes ---
      try { await db.execute("ALTER TABLE real_estate_units ADD COLUMN unit_no TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE real_estate_units ADD COLUMN property_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE real_estate_units ADD COLUMN rent_amount REAL"); } catch (_) {}
      
      try { await db.execute("ALTER TABLE real_estate_contracts ADD COLUMN rent_amount REAL"); } catch (_) {}
      try { await db.execute("ALTER TABLE real_estate_contracts ADD COLUMN last_payment_date TEXT"); } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS real_estate_payments (
          id TEXT PRIMARY KEY,
          contract_id TEXT,
          amount REAL,
          payment_date TEXT,
          notes TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 114) {
      // --- Security Audit & Audit Trail ---
      await db.execute('''
        CREATE TABLE IF NOT EXISTS security_audit (
          id TEXT PRIMARY KEY,
          action_type TEXT,
          description TEXT,
          is_critical INTEGER DEFAULT 0,
          $metadata
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_trail (
          id TEXT PRIMARY KEY,
          module TEXT,
          action TEXT,
          reference_id TEXT,
          user_id TEXT,
          details TEXT,
          timestamp TEXT,
          device_id TEXT,
          $metadata
        )
      ''');

      // --- Fleet Extensions ---
      try { await db.execute("ALTER TABLE fleet_vehicles ADD COLUMN driver_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE fleet_vehicles ADD COLUMN fuel_card TEXT"); } catch (_) {}
      
      // --- Support Extensions ---
      try { await db.execute("ALTER TABLE support_tickets ADD COLUMN customer_feedback TEXT"); } catch (_) {}
    }

    if (oldVersion < 115) {
      // --- Logistics Extensions ---
      try { await db.execute("ALTER TABLE shipments ADD COLUMN shipping_cost REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE shipments ADD COLUMN tracking_url TEXT"); } catch (_) {}
      
      // Ensure metadata column exists in newer tables
      final newerTables = ['security_audit', 'audit_trail', 'audit_alerts'];
      for (var table in newerTables) {
        try { await db.execute("ALTER TABLE $table ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN updated_at TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN device_id TEXT"); } catch (_) {}
      }
    }

    if (oldVersion < 116) {
      // --- Missing Tables Referenced by moduleTableMap (Plan 4) ---
      
      // 1. governance_records (used by compliance_governance module)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS governance_records (
          id TEXT PRIMARY KEY,
          module_id TEXT,
          title TEXT,
          type TEXT,
          description TEXT,
          status TEXT DEFAULT 'active',
          responsible TEXT,
          review_date TEXT,
          notes TEXT,
          $metadata
        )
      ''');

      // 2. industrial_jobs (used by ai_robot_industries module)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS industrial_jobs (
          id TEXT PRIMARY KEY,
          module_id TEXT,
          name TEXT,
          job_type TEXT,
          machine_id TEXT,
          status TEXT DEFAULT 'pending',
          priority TEXT DEFAULT 'medium',
          start_date TEXT,
          end_date TEXT,
          output_qty REAL DEFAULT 0,
          notes TEXT,
          $metadata
        )
      ''');

      // 3. meeting_records (used by meeting_mgmt module)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meeting_records (
          id TEXT PRIMARY KEY,
          module_id TEXT,
          title TEXT,
          date TEXT,
          time TEXT,
          location TEXT,
          attendees TEXT,
          minutes TEXT,
          status TEXT DEFAULT 'Scheduled',
          notes TEXT,
          $metadata
        )
      ''');

      // 4. feasibility_studies (used by feasibility module)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS feasibility_studies (
          id TEXT PRIMARY KEY,
          module_id TEXT,
          name TEXT,
          project_type TEXT,
          initial_investment REAL DEFAULT 0,
          expected_revenue REAL DEFAULT 0,
          expected_costs REAL DEFAULT 0,
          roi_percentage REAL DEFAULT 0,
          payback_months INTEGER DEFAULT 0,
          npv REAL DEFAULT 0,
          risk_level TEXT DEFAULT 'medium',
          status TEXT DEFAULT 'draft',
          notes TEXT,
          $metadata
        )
      ''');

      // 5. tax_filings (used by taxes & taxes_global modules)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tax_filings (
          id TEXT PRIMARY KEY,
          module_id TEXT,
          period_label TEXT,
          start_date TEXT,
          end_date TEXT,
          country TEXT,
          tax_rate REAL,
          total_sales_tax REAL DEFAULT 0,
          total_purchase_tax REAL DEFAULT 0,
          net_tax_due REAL DEFAULT 0,
          status TEXT DEFAULT 'draft',
          filed_date TEXT,
          filed_at TEXT,
          notes TEXT,
          $metadata
        )
      ''');

      // --- Support & Logistics Tables (Plan 5) ---
      
      // 1. approval_requests (ApprovalSystemScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS approval_requests (
          id TEXT PRIMARY KEY,
          module TEXT,
          reference_id TEXT,
          requested_by TEXT,
          approver_id TEXT,
          status TEXT DEFAULT 'Pending',
          notes TEXT,
          $metadata
        )
      ''');

      // 2. workflows (WorkflowMgmtScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workflows (
          id TEXT PRIMARY KEY,
          name TEXT,
          trigger_type TEXT,
          action_type TEXT,
          condition_json TEXT,
          is_active INTEGER DEFAULT 1,
          $metadata
        )
      ''');

      // 3. kpi_definitions (KPIManagementScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS kpi_definitions (
          id TEXT PRIMARY KEY,
          title TEXT,
          target REAL DEFAULT 0,
          actual REAL DEFAULT 0,
          unit TEXT,
          period TEXT DEFAULT 'Monthly',
          department TEXT,
          responsible_id TEXT,
          $metadata
        )
      ''');

      // 4. meetings (MeetingMgmtScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meetings (
          id TEXT PRIMARY KEY,
          title TEXT,
          date TEXT,
          time TEXT,
          location TEXT,
          organizer_id TEXT,
          attendees_json TEXT,
          minutes TEXT,
          status TEXT DEFAULT 'Scheduled',
          $metadata
        )
      ''');

      // 5. support_tickets (SupportTicketsScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS support_tickets (
          id TEXT PRIMARY KEY,
          subject TEXT,
          description TEXT,
          priority TEXT DEFAULT 'Medium',
          status TEXT DEFAULT 'Open',
          assigned_to TEXT,
          reported_by TEXT,
          resolution TEXT,
          $metadata
        )
      ''');

      // 6. shipments (ShippingLogisticsScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shipments (
          id TEXT PRIMARY KEY,
          tracking_number TEXT,
          origin TEXT,
          destination TEXT,
          sender TEXT,
          receiver TEXT,
          status TEXT DEFAULT 'Processing',
          estimated_delivery TEXT,
          actual_delivery TEXT,
          shipping_cost REAL DEFAULT 0,
          notes TEXT,
          $metadata
        )
      ''');

      // 7. fleet_vehicles (FleetProfessionalScreen)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fleet_vehicles (
          id TEXT PRIMARY KEY,
          plate_number TEXT,
          model TEXT,
          year TEXT,
          type TEXT,
          driver_id TEXT,
          status TEXT DEFAULT 'active',
          last_mileage REAL DEFAULT 0,
          insurance_expiry TEXT,
          license_expiry TEXT,
          notes TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 117) {
      // --- Phase 7: Specialized Industries ---
      
      // 1. Pharmacies & Medicine
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pharmacy_drugs (
          id TEXT PRIMARY KEY,
          scientific_name TEXT,
          barcode TEXT,
          category TEXT,
          requires_prescription INTEGER DEFAULT 0,
          shelf_location TEXT,
          notes TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS drug_batches (
          id TEXT PRIMARY KEY,
          drug_id TEXT,
          lot_number TEXT,
          production_date TEXT,
          expiry_date TEXT,
          quantity REAL DEFAULT 0,
          $metadata
        )
      ''');

      // 2. Car Trading & Dealerships
      await db.execute('''
        CREATE TABLE IF NOT EXISTS car_inventory (
          id TEXT PRIMARY KEY,
          vin TEXT,
          make TEXT,
          model TEXT,
          year INTEGER,
          color TEXT,
          mileage REAL DEFAULT 0,
          status TEXT DEFAULT 'Available',
          import_type TEXT,
          notes TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicle_inspections (
          id TEXT PRIMARY KEY,
          car_id TEXT,
          inspection_date TEXT,
          inspector_name TEXT,
          damages_json TEXT,
          passed INTEGER DEFAULT 1,
          $metadata
        )
      ''');

      // 3. Gas Stations
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fuel_tanks (
          id TEXT PRIMARY KEY,
          tank_number TEXT,
          capacity REAL DEFAULT 0,
          fuel_type TEXT,
          current_level REAL DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pump_readings (
          id TEXT PRIMARY KEY,
          tank_id TEXT,
          pump_number TEXT,
          shift_id TEXT,
          previous_reading REAL DEFAULT 0,
          current_reading REAL DEFAULT 0,
          liters_sold REAL DEFAULT 0,
          revenue_collected REAL DEFAULT 0,
          $metadata
        )
      ''');

      // 4. Livestock & Agriculture
      await db.execute('''
        CREATE TABLE IF NOT EXISTS crop_cycles (
          id TEXT PRIMARY KEY,
          crop_type TEXT,
          planting_date TEXT,
          expected_harvest_date TEXT,
          area_size REAL DEFAULT 0,
          status TEXT DEFAULT 'Growing',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS livestock_batches (
          id TEXT PRIMARY KEY,
          animal_type TEXT,
          head_count INTEGER DEFAULT 0,
          health_status TEXT DEFAULT 'Healthy',
          next_vaccination TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 118) {
      // --- Phase 8: Light Industries & Services ---
      
      // 1. Furniture & Wood
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wood_inventory (
          id TEXT PRIMARY KEY,
          wood_type TEXT,
          thickness REAL,
          dimensions TEXT,
          quantity_m3 REAL DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS furniture_assemblies (
          id TEXT PRIMARY KEY,
          assembly_name TEXT,
          components_json TEXT,
          status TEXT DEFAULT 'Pending',
          estimated_cost REAL DEFAULT 0,
          $metadata
        )
      ''');

      // 2. Electronics & Appliances
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appliance_inventory (
          id TEXT PRIMARY KEY,
          name TEXT,
          barcode TEXT,
          serial_number TEXT,
          brand TEXT,
          warranty_period_months INTEGER,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS warranty_claims (
          id TEXT PRIMARY KEY,
          claim_number TEXT,
          customer_id TEXT,
          appliance_id TEXT,
          fault_description TEXT,
          repair_status TEXT DEFAULT 'Open',
          $metadata
        )
      ''');

      // 3. Cleaning Materials & Chemicals
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chemical_inventory (
          id TEXT PRIMARY KEY,
          chemical_name TEXT,
          concentration TEXT,
          volume REAL DEFAULT 0,
          hazard_level TEXT,
          expiry_date TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS mixing_batches (
          id TEXT PRIMARY KEY,
          batch_number TEXT,
          ingredients_json TEXT,
          produced_quantity REAL DEFAULT 0,
          $metadata
        )
      ''');

      // 4. Sanitary Ware
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sanitary_inventory (
          id TEXT PRIMARY KEY,
          item_name TEXT,
          model TEXT,
          color TEXT,
          is_set INTEGER DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sanitary_sets (
          id TEXT PRIMARY KEY,
          set_name TEXT,
          component_ids_json TEXT,
          $metadata
        )
      ''');

      // 5. Office Services & Bookings
      await db.execute('''
        CREATE TABLE IF NOT EXISTS office_service_catalog (
          id TEXT PRIMARY KEY,
          service_name TEXT,
          pricing_type TEXT,
          unit_price REAL DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS service_bookings (
          id TEXT PRIMARY KEY,
          customer_name TEXT,
          service_id TEXT,
          start_time TEXT,
          end_time TEXT,
          total_cost REAL DEFAULT 0,
          $metadata
        )
      ''');
    }

    if (oldVersion < 119) {
      // --- Phase 9: Entities (Full CRUD) ---
      
      // 1. Branch Chains
      await db.execute('''
        CREATE TABLE IF NOT EXISTS branch_locations (
          id TEXT PRIMARY KEY,
          branch_name TEXT,
          branch_code TEXT,
          city TEXT,
          manager_name TEXT,
          operating_status TEXT DEFAULT 'Active',
          target_revenue REAL DEFAULT 0,
          $metadata
        )
      ''');

      // 2. Subsidiary Companies
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subsidiary_companies (
          id TEXT PRIMARY KEY,
          company_name TEXT,
          sector TEXT,
          ownership_percentage REAL DEFAULT 100,
          capital REAL DEFAULT 0,
          ceo_name TEXT,
          $metadata
        )
      ''');
    }

    if (oldVersion < 120) {
      // --- Phase 10: E-Commerce & Supply Chain (Full CRUD) ---
      
      // 1. E-Commerce Platforms
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ecommerce_platforms (
          id TEXT PRIMARY KEY,
          platform_name TEXT,
          store_url TEXT,
          api_key TEXT,
          last_sync TEXT,
          total_orders INTEGER DEFAULT 0,
          $metadata
        )
      ''');

      // 2. Shipping Shipments (Supply Chain)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shipping_shipments (
          id TEXT PRIMARY KEY,
          tracking_number TEXT,
          carrier TEXT,
          origin TEXT,
          destination TEXT,
          expected_arrival TEXT,
          status TEXT DEFAULT 'In Transit',
          $metadata
        )
      ''');
    }

    if (oldVersion < 121) {
      // --- Phase 11: Operations (Trade Contracts, Stock Waste, Barcode Mgmt) ---

      // 1. Trade Contracts
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trade_contracts_records (
          id TEXT PRIMARY KEY,
          contract_title TEXT,
          second_party TEXT,
          start_date TEXT,
          end_date TEXT,
          contract_value REAL DEFAULT 0,
          status TEXT DEFAULT 'Active',
          $metadata
        )
      ''');

      // 2. Stock Waste
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_waste_records (
          id TEXT PRIMARY KEY,
          item_name TEXT,
          reason TEXT,
          quantity REAL DEFAULT 0,
          financial_loss REAL DEFAULT 0,
          date_reported TEXT,
          $metadata
        )
      ''');

      // 3. Barcode Management
      await db.execute('''
        CREATE TABLE IF NOT EXISTS barcode_mgmt_records (
          id TEXT PRIMARY KEY,
          product_name TEXT,
          barcode_format TEXT,
          barcode_value TEXT,
          is_printed INTEGER DEFAULT 0,
          $metadata
        )
      ''');
    }

    if (oldVersion < 122) {
      // --- Phase 12: Enterprise (Recruitment, Performance, CRM, Legal) ---

      // 1. HR Recruitment
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_recruitment_records (
          id TEXT PRIMARY KEY,
          candidate_name TEXT,
          job_position TEXT,
          stage TEXT DEFAULT 'Applied',
          rating REAL DEFAULT 0,
          interview_date TEXT,
          $metadata
        )
      ''');

      // 2. HR Performance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_performance_records (
          id TEXT PRIMARY KEY,
          employee_name TEXT,
          review_period TEXT,
          score REAL DEFAULT 0,
          manager_feedback TEXT,
          status TEXT DEFAULT 'Draft',
          $metadata
        )
      ''');

      // 3. CRM Leads
      await db.execute('''
        CREATE TABLE IF NOT EXISTS crm_leads_records (
          id TEXT PRIMARY KEY,
          lead_name TEXT,
          opportunity_value REAL DEFAULT 0,
          stage TEXT DEFAULT 'New',
          source TEXT,
          contact_info TEXT,
          $metadata
        )
      ''');

      // 4. Legal Cases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS legal_cases_records (
          id TEXT PRIMARY KEY,
          case_number TEXT,
          court_name TEXT,
          case_type TEXT,
          next_session TEXT,
          legal_status TEXT DEFAULT 'Open',
          $metadata
        )
      ''');
    }

    if (oldVersion < 123) {
      // --- Phase 13: Industrial Excellence (Quality, Maintenance) ---

      // 1. Quality Management
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quality_mgmt_records (
          id TEXT PRIMARY KEY,
          item_name TEXT,
          batch_number TEXT,
          test_type TEXT,
          result TEXT DEFAULT 'Pending',
          inspector_name TEXT,
          inspection_date TEXT,
          $metadata
        )
      ''');

      // 2. Periodic Maintenance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS periodic_maintenance_records (
          id TEXT PRIMARY KEY,
          machine_name TEXT,
          maintenance_type TEXT,
          frequency TEXT,
          last_service TEXT,
          next_service TEXT,
          status TEXT DEFAULT 'Scheduled',
          $metadata
        )
      ''');
    }

    if (oldVersion < 124) {
      // --- Phase 14: Specialized Sectors (Medical, Hotel, Labs) ---

      // 1. Medical
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_patients_records (
          id TEXT PRIMARY KEY,
          name TEXT,
          phone TEXT,
          medical_history TEXT,
          $metadata
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medical_appointments_records (
          id TEXT PRIMARY KEY,
          patient_id TEXT,
          patient_name TEXT,
          date TEXT,
          time TEXT,
          status TEXT DEFAULT 'scheduled',
          $metadata
        )
      ''');

      // 2. Hotels
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hotel_rooms_records (
          id TEXT PRIMARY KEY,
          room_number TEXT,
          type TEXT,
          price_per_night REAL DEFAULT 0,
          status TEXT DEFAULT 'available',
          $metadata
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hotel_bookings_records (
          id TEXT PRIMARY KEY,
          room_id TEXT,
          room_number TEXT,
          guest_name TEXT,
          check_in TEXT,
          check_out TEXT,
          total_price REAL DEFAULT 0,
          status TEXT DEFAULT 'confirmed',
          $metadata
        )
      ''');

      // 3. Labs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lab_tests_records (
          id TEXT PRIMARY KEY,
          patient_name TEXT,
          test_name TEXT,
          sample_id TEXT,
          result_value TEXT,
          status TEXT DEFAULT 'Pending',
          $metadata
        )
      ''');
    }

    if (oldVersion < 44) {
      // Fix tables that were created in v43 without the is_deleted column
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
        await db.execute("ALTER TABLE items ADD COLUMN expiry_date TEXT");
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
        'asset_custody_logs', 'asset_custody_log', 'channels', 'messages', 'shifts', 'hr_shifts', 'tasks',
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

      // 5. Compliance & Governance
      await db.execute('''
        CREATE TABLE IF NOT EXISTS governance_records (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          status TEXT DEFAULT 'Active',
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
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
    }

    if (oldVersion < 100) {
      // v100: Critical Finance & CRM Infrastructure
      
      // 1. General Contracts Table (Index 56)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contracts (
          id TEXT PRIMARY KEY,
          title TEXT,
          partner_id TEXT,
          partner_name TEXT,
          partner_type TEXT, -- 'client', 'supplier', 'employee', 'other'
          start_date TEXT,
          end_date TEXT,
          amount REAL DEFAULT 0,
          currency TEXT DEFAULT 'SAR',
          status TEXT DEFAULT 'active', -- 'active', 'expired', 'terminated', 'draft'
          attachment_path TEXT,
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 2. Asset Transfers Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS asset_transfers (
          id TEXT PRIMARY KEY,
          asset_id TEXT,
          from_location TEXT,
          to_location TEXT,
          from_cost_center_id TEXT,
          to_cost_center_id TEXT,
          transfer_date TEXT,
          approved_by TEXT,
          notes TEXT,
          sync_status INTEGER DEFAULT 0, 
          updated_at TEXT, 
          device_id TEXT, 
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 3. Commission Rules Table (Automated calculations)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commission_rules (
          id TEXT PRIMARY KEY,
          name TEXT,
          rule_type TEXT, -- 'flat', 'percentage', 'tiered'
          value REAL,
          target_amount REAL DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          sync_status INTEGER DEFAULT 0, 
          updated_at TEXT, 
          device_id TEXT, 
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // 4. Enhance Clients & Suppliers
      try { await db.execute("ALTER TABLE clients ADD COLUMN credit_limit REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE clients ADD COLUMN classification TEXT DEFAULT 'normal'"); } catch (_) {}
      try { await db.execute("ALTER TABLE suppliers ADD COLUMN rating INTEGER DEFAULT 5"); } catch (_) {}
      
      // 5. Enhance Employee Loans (Detailed installments tracking)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS loan_installments (
          id TEXT PRIMARY KEY,
          loan_id TEXT,
          due_date TEXT,
          amount REAL,
          paid_amount REAL DEFAULT 0,
          status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'late'
          payment_date TEXT,
          sync_status INTEGER DEFAULT 0, 
          updated_at TEXT, 
          device_id TEXT, 
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    
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

    if (oldVersion < 60) {
      // ══════════════════════════════════════════════════════════════════
      // v60: Production Audit Fixes
      // 1. Fix attendance_logs column mismatch (code uses check_in_time/check_out_time)
      // 2. Create employee_contracts table
      // ══════════════════════════════════════════════════════════════════

      // Fix attendance_logs: add check_in_time/check_out_time columns
      try { await db.execute('ALTER TABLE attendance_logs ADD COLUMN check_in_time TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE attendance_logs ADD COLUMN check_out_time TEXT'); } catch (_) {}

      // Copy existing data from check_in → check_in_time (for existing users)
      try { await db.execute("UPDATE attendance_logs SET check_in_time = check_in WHERE check_in_time IS NULL AND check_in IS NOT NULL"); } catch (_) {}
      try { await db.execute("UPDATE attendance_logs SET check_out_time = check_out WHERE check_out_time IS NULL AND check_out IS NOT NULL"); } catch (_) {}

      // Employee contracts table (required by contracts_tab.dart)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employee_contracts (
          id TEXT PRIMARY KEY,
          employee_id TEXT,
          contract_type TEXT,
          start_date TEXT,
          end_date TEXT,
          basic_salary REAL,
          status TEXT DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      debugPrint("✅ Database Migrated to v60: Attendance columns + employee_contracts fixed.");
    }

    if (oldVersion < 61) {
      // v61: System Users Schema Integrity
      // Fixes: "table system_users has no column named name"
      try {
        await db.execute('ALTER TABLE system_users ADD COLUMN name TEXT');
        debugPrint("✅ Added 'name' column to system_users");
      } catch (e) {
        // Column might already exist if table was created in v48/v60 directly
        debugPrint("ℹ️ system_users.name already exists or table doesn't exist yet.");
      }
      
      debugPrint("✅ Database Migrated to v61: Local schema repairs completed.");
    }

    if (oldVersion < 69) {
      // v69: Fix budgets table schema (budget_amount)
      try {
        await db.execute("ALTER TABLE budgets ADD COLUMN budget_amount REAL DEFAULT 0");
        debugPrint("✅ Added 'budget_amount' column to budgets");
      } catch (_) {}
      
      // Sync Engine catch-all for budgets
      try { await db.execute('ALTER TABLE budgets ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE budgets ADD COLUMN device_id TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE budgets ADD COLUMN updated_at TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE budgets ADD COLUMN is_deleted INTEGER DEFAULT 0'); } catch (_) {}
      
      debugPrint("✅ Database Migrated to v69: Budgets schema repaired.");
    }

    if (oldVersion < 70) {
      // v70: Feasibility Studies Schema Update
      final columns = [
        'project_name TEXT', 'sector TEXT', 'country TEXT', 
        'capital REAL DEFAULT 0', 'monthly_costs REAL DEFAULT 0', 
        'monthly_revenue REAL DEFAULT 0', 'study_years INTEGER DEFAULT 5', 
        'discount_rate REAL DEFAULT 0.10', 'npv REAL', 'irr REAL', 
        'payback_months INTEGER', 'success_rate REAL', 'scenario TEXT', 'notes TEXT'
      ];
      for (var col in columns) {
        try {
          await db.execute('ALTER TABLE feasibility_studies ADD COLUMN $col');
        } catch (_) {}
      }
      debugPrint("✅ Database Migrated to v70: Feasibility Studies schema synchronized.");
    }


    if (oldVersion < 71) {
      // v71: Fix journal_entry_lines missing account_name and add created_at to many tables
      try { await db.execute('ALTER TABLE journal_entry_lines ADD COLUMN account_name TEXT'); } catch (_) {}
      
      final tablesToAddCreatedAt = [
        'invoices', 'invoice_lines', 'purchase_invoices', 'purchase_invoice_lines',
        'journal_entries', 'journal_entry_lines', 'accounts', 'cost_centers',
        'projects', 'bom_lines', 'asset_custody_logs', 'sales_targets',
        'employees', 'suppliers', 'clients', 'items', 'budgets', 'assets', 'cheques'
      ];
      for (var table in tablesToAddCreatedAt) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN created_at TEXT');
        } catch (_) {}
      }
      debugPrint("✅ Database Migrated to v71: Global created_at columns and account_name added.");
    }

    if (oldVersion < 72) {
      // v72: Add temporal bounds to budgets for overrun detection
      try { await db.execute('ALTER TABLE budgets ADD COLUMN start_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE budgets ADD COLUMN end_date TEXT'); } catch (_) {}
      debugPrint("✅ Database Migrated to v72: Budget date bounds added.");
    }

    if (oldVersion < 73) {
      // v73: Fix security_audit schema drift
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN action TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN user_id TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN details TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN ip_address TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE security_audit ADD COLUMN created_at TEXT'); } catch (_) {}
      debugPrint("✅ Database Migrated to v73: security_audit schema unified.");
    }

    if (oldVersion < 62) {
      // v62: Comprehensive User Schema Repair
      // Ensures ALL columns for users exist to prevent "no column named X" crashes
      final userColumns = {
        'name': 'TEXT',
        'email': 'TEXT',
        'password_hash': 'TEXT',
        'role': "TEXT DEFAULT 'employee'",
        'is_active': 'INTEGER DEFAULT 1',
        'sync_status': 'INTEGER DEFAULT 0',
        'device_id': 'TEXT',
        'updated_at': 'TEXT',
        'is_deleted': 'INTEGER DEFAULT 0',
      };

      for (var entry in userColumns.entries) {
        try {
          await db.execute('ALTER TABLE system_users ADD COLUMN ${entry.key} ${entry.value}');
          debugPrint("✅ Added '${entry.key}' column to system_users");
        } catch (_) {
          // Skip if exists
        }
      }
      
      debugPrint("✅ Database Migrated to v62: Comprehensive user schema repair completed.");
    }

    if (oldVersion < 63) {
      // v63: Global Metadata Schema Sweeper (Phase 2)
      // Fixes: "table cost_centers has no column named created_at"
      // This ensures ALL sync tables have 'created_at' which was missed in v59 sweep
      
      const List<String> allTables = [
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
        'performance_reviews', 'employee_contracts', 'draft_invoices',
      ];

      for (final table in allTables) {
        try { await db.execute('ALTER TABLE $table ADD COLUMN created_at TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN device_id TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN is_deleted INTEGER DEFAULT 0'); } catch (_) {}
      }

      debugPrint("✅ Database Migrated to v63: Global 'created_at' schema repair completed.");
    }

    if (oldVersion < 64) {
      // v64: Ensure 'clients' table exists (Crucial FIX for Vouchers)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients (
          id TEXT PRIMARY KEY,
          name TEXT,
          phone TEXT,
          email TEXT,
          tax_id TEXT,
          address TEXT,
          balance REAL DEFAULT 0,
          $metadata
        )
      ''');
      
      // Fix existing table: add missing columns
      try { await db.execute('ALTER TABLE clients ADD COLUMN phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN email TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN contact_info TEXT'); } catch (_) {}
      
      // Seed a default client if empty
      final res = await db.query('clients', limit: 1);
      if (res.isEmpty) {
        await db.insert('clients', {
          'id': 'CL_DEFAULT',
          'name': 'عميل عام / مشتري نقدي',
          'sync_status': 0,
          'is_deleted': 0
        });
      }

      // Seed a default supplier if empty
      final resSup = await db.query('suppliers', limit: 1);
      if (resSup.isEmpty) {
        await db.insert('suppliers', {
          'id': 'SUP_DEFAULT',
          'name': 'مورد عام / مشتريات نقدية',
          'sync_status': 0,
          'is_deleted': 0
        });
      }
      // Ensure ALL missing tables exist
      final missingTables = {
        'financial_custodies': '''
          CREATE TABLE IF NOT EXISTS financial_custodies (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            amount REAL,
            issue_date TEXT,
            reason TEXT,
            status TEXT DEFAULT 'pending',
            cleared_amount REAL DEFAULT 0,
            clearance_date TEXT,
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'asset_depreciation_logs': '''
          CREATE TABLE IF NOT EXISTS asset_depreciation_logs (
            id TEXT PRIMARY KEY,
            asset_id TEXT,
            date TEXT,
            amount REAL,
            method TEXT DEFAULT 'straight_line',
            created_at TEXT,
            $metadata
          )
        ''',
        'purchase_orders': '''
          CREATE TABLE IF NOT EXISTS purchase_orders (
            id TEXT PRIMARY KEY,
            supplier_id TEXT,
            supplier_name TEXT,
            issue_date TEXT,
            expected_date TEXT,
            subtotal REAL DEFAULT 0,
            tax_amount REAL DEFAULT 0,
            total REAL DEFAULT 0,
            status TEXT DEFAULT 'draft',
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'purchase_order_lines': '''
          CREATE TABLE IF NOT EXISTS purchase_order_lines (
            id TEXT PRIMARY KEY,
            order_id TEXT,
            item_id TEXT,
            name TEXT,
            quantity REAL,
            price REAL,
            total REAL DEFAULT 0,
            $metadata
          )
        ''',
        'debit_notes': '''
          CREATE TABLE IF NOT EXISTS debit_notes (
            id TEXT PRIMARY KEY,
            supplier_id TEXT,
            original_invoice_id TEXT,
            amount REAL,
            reason TEXT,
            date TEXT,
            journal_entry_id TEXT,
            status TEXT DEFAULT 'draft',
            created_at TEXT,
            $metadata
          )
        ''',
        'manufacturing_orders': '''
          CREATE TABLE IF NOT EXISTS manufacturing_orders (
            id TEXT PRIMARY KEY,
            bom_id TEXT,
            product_id TEXT,
            quantity REAL,
            status TEXT DEFAULT 'planned',
            start_date TEXT,
            end_date TEXT,
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'bom': '''
          CREATE TABLE IF NOT EXISTS bom (
            id TEXT PRIMARY KEY,
            product_id TEXT,
            product_name TEXT,
            total_cost REAL DEFAULT 0,
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'bom_lines': '''
          CREATE TABLE IF NOT EXISTS bom_lines (
            id TEXT PRIMARY KEY,
            bom_id TEXT,
            item_id TEXT,
            item_name TEXT,
            quantity REAL,
            unit_cost REAL,
            $metadata
          )
        ''',
        'sales_agents': '''
          CREATE TABLE IF NOT EXISTS sales_agents (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            name TEXT,
            commission_rate REAL DEFAULT 0,
            target_amount REAL DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TEXT,
            $metadata
          )
        ''',
        'sales_targets': '''
          CREATE TABLE IF NOT EXISTS sales_targets (
            id TEXT PRIMARY KEY,
            agent_id TEXT,
            month TEXT,
            target_amount REAL DEFAULT 0,
            achieved_amount REAL DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TEXT,
            $metadata
          )
        ''',
        'investments': '''
          CREATE TABLE IF NOT EXISTS investments (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            initial_amount REAL,
            current_value REAL,
            return_rate REAL DEFAULT 0,
            start_date TEXT,
            maturity_date TEXT,
            status TEXT DEFAULT 'active',
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'investment_transactions': '''
          CREATE TABLE IF NOT EXISTS investment_transactions (
            id TEXT PRIMARY KEY,
            investment_id TEXT,
            type TEXT,
            amount REAL,
            date TEXT,
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'real_estate_units': '''
          CREATE TABLE IF NOT EXISTS real_estate_units (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            area REAL,
            location TEXT,
            status TEXT DEFAULT 'available',
            monthly_rent REAL DEFAULT 0,
            created_at TEXT,
            $metadata
          )
        ''',
        'real_estate_contracts': '''
          CREATE TABLE IF NOT EXISTS real_estate_contracts (
            id TEXT PRIMARY KEY,
            unit_id TEXT,
            tenant_name TEXT,
            start_date TEXT,
            end_date TEXT,
            monthly_rent REAL,
            status TEXT DEFAULT 'active',
            created_at TEXT,
            $metadata
          )
        ''',
        'leave_requests': '''
          CREATE TABLE IF NOT EXISTS leave_requests (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            type TEXT,
            start_date TEXT,
            end_date TEXT,
            days INTEGER,
            status TEXT DEFAULT 'pending',
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'employee_loans': '''
          CREATE TABLE IF NOT EXISTS employee_loans (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            amount REAL,
            monthly_deduction REAL,
            remaining REAL,
            start_date TEXT,
            status TEXT DEFAULT 'active',
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'performance_reviews': '''
          CREATE TABLE IF NOT EXISTS performance_reviews (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            reviewer_id TEXT,
            review_date TEXT,
            rating REAL,
            comments TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'employee_contracts': '''
          CREATE TABLE IF NOT EXISTS employee_contracts (
            id TEXT PRIMARY KEY,
            employee_id TEXT,
            contract_type TEXT,
            start_date TEXT,
            end_date TEXT,
            basic_salary REAL,
            status TEXT DEFAULT 'active',
            created_at TEXT,
            $metadata
          )
        ''',
        'liquidation_requests': '''
          CREATE TABLE IF NOT EXISTS liquidation_requests (
            id TEXT PRIMARY KEY,
            custody_id TEXT,
            employee_id TEXT,
            amount REAL,
            date TEXT,
            status TEXT DEFAULT 'pending',
            notes TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'tax_filings': '''
          CREATE TABLE IF NOT EXISTS tax_filings (
            id TEXT PRIMARY KEY,
            period TEXT,
            type TEXT,
            total_tax REAL,
            status TEXT DEFAULT 'draft',
            filed_date TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'feasibility_studies': '''
          CREATE TABLE IF NOT EXISTS feasibility_studies (
            id TEXT PRIMARY KEY,
            title TEXT,
            data TEXT,
            result TEXT,
            created_at TEXT,
            $metadata
          )
        ''',
        'promotional_campaigns': '''
          CREATE TABLE IF NOT EXISTS promotional_campaigns (
            id TEXT PRIMARY KEY,
            name TEXT,
            item_id TEXT,
            discount_rate REAL,
            start_date TEXT,
            end_date TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            $metadata
          )
        ''',
      };

      for (final entry in missingTables.entries) {
        try {
          await db.execute(entry.value);
        } catch (e) {
          debugPrint('⚠️ Table ${entry.key} creation skipped: $e');
        }
      }

      // Add missing columns to clients table
      try { await db.execute('ALTER TABLE clients ADD COLUMN phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN email TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}

      debugPrint("✅ Database Migrated to v64: ALL missing tables created and data seeded.");
    }

    if (oldVersion < 65) {
      // v65: Safety net — re-run column and seeding fixes if v64 failed
      try { await db.execute('ALTER TABLE clients ADD COLUMN phone TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN email TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE clients ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN balance REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN contact_info TEXT'); } catch (_) {}

      // Ensure default data
      final cl = await db.query('clients', limit: 1);
      if (cl.isEmpty) {
        await db.insert('clients', {'id': 'CL_DEFAULT', 'name': 'عميل عام / مشتري نقدي', 'sync_status': 0, 'is_deleted': 0});
      }
      final sp = await db.query('suppliers', limit: 1);
      if (sp.isEmpty) {
        await db.insert('suppliers', {'id': 'SUP_DEFAULT', 'name': 'مورد عام / مشتريات نقدية', 'sync_status': 0, 'is_deleted': 0});
      }

      // Ensure all critical tables exist
      final criticalTables = [
        "CREATE TABLE IF NOT EXISTS financial_custodies (id TEXT PRIMARY KEY, employee_id TEXT, amount REAL, issue_date TEXT, reason TEXT, status TEXT DEFAULT 'pending', cleared_amount REAL DEFAULT 0, notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS asset_depreciation_logs (id TEXT PRIMARY KEY, asset_id TEXT, date TEXT, amount REAL, method TEXT DEFAULT 'straight_line', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS purchase_orders (id TEXT PRIMARY KEY, supplier_id TEXT, supplier_name TEXT, issue_date TEXT, expected_date TEXT, subtotal REAL DEFAULT 0, tax_amount REAL DEFAULT 0, total REAL DEFAULT 0, status TEXT DEFAULT 'draft', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS purchase_order_lines (id TEXT PRIMARY KEY, order_id TEXT, item_id TEXT, name TEXT, quantity REAL, price REAL, total REAL DEFAULT 0, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS debit_notes (id TEXT PRIMARY KEY, supplier_id TEXT, amount REAL, reason TEXT, date TEXT, status TEXT DEFAULT 'draft', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS manufacturing_orders (id TEXT PRIMARY KEY, bom_id TEXT, product_id TEXT, quantity REAL, status TEXT DEFAULT 'planned', start_date TEXT, end_date TEXT, notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS bom (id TEXT PRIMARY KEY, product_id TEXT, product_name TEXT, total_cost REAL DEFAULT 0, notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS bom_lines (id TEXT PRIMARY KEY, bom_id TEXT, item_id TEXT, item_name TEXT, quantity REAL, unit_cost REAL, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS sales_agents (id TEXT PRIMARY KEY, employee_id TEXT, name TEXT, commission_rate REAL DEFAULT 0, status TEXT DEFAULT 'active', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS investments (id TEXT PRIMARY KEY, name TEXT, type TEXT, initial_amount REAL, current_value REAL, return_rate REAL DEFAULT 0, start_date TEXT, status TEXT DEFAULT 'active', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS real_estate_units (id TEXT PRIMARY KEY, name TEXT, type TEXT, area REAL, location TEXT, status TEXT DEFAULT 'available', monthly_rent REAL DEFAULT 0, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS real_estate_contracts (id TEXT PRIMARY KEY, unit_id TEXT, tenant_name TEXT, start_date TEXT, end_date TEXT, monthly_rent REAL, status TEXT DEFAULT 'active', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS leave_requests (id TEXT PRIMARY KEY, employee_id TEXT, type TEXT, start_date TEXT, end_date TEXT, days INTEGER, status TEXT DEFAULT 'pending', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS employee_loans (id TEXT PRIMARY KEY, employee_id TEXT, amount REAL, monthly_deduction REAL, remaining REAL, start_date TEXT, status TEXT DEFAULT 'active', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS performance_reviews (id TEXT PRIMARY KEY, employee_id TEXT, reviewer_id TEXT, review_date TEXT, rating REAL, comments TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS employee_contracts (id TEXT PRIMARY KEY, employee_id TEXT, contract_type TEXT, start_date TEXT, end_date TEXT, basic_salary REAL, status TEXT DEFAULT 'active', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS tax_filings (id TEXT PRIMARY KEY, period TEXT, type TEXT, total_tax REAL, status TEXT DEFAULT 'draft', filed_date TEXT, filed_at TEXT, period_label TEXT, start_date TEXT, end_date TEXT, country TEXT, tax_rate REAL, total_sales_tax REAL, total_purchase_tax REAL, net_tax_due REAL, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS feasibility_studies (id TEXT PRIMARY KEY, title TEXT, data TEXT, result TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS asset_custody_logs (id TEXT PRIMARY KEY, asset_id TEXT, employee_id TEXT, issued_date TEXT, returned_date TEXT, status TEXT, notes TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS receipt_vouchers (id TEXT PRIMARY KEY, client_id TEXT, amount REAL, payment_method TEXT, bank_id TEXT, description TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS payment_vouchers (id TEXT PRIMARY KEY, supplier_id TEXT, amount REAL, payment_method TEXT, bank_id TEXT, description TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS cheques (id TEXT PRIMARY KEY, cheque_number TEXT, bank_name TEXT, amount REAL, issue_date TEXT, due_date TEXT, type TEXT, partner_id TEXT, partner_name TEXT, partner_type TEXT, status TEXT DEFAULT 'pending', journal_entry_id TEXT, notes TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS money_transfers (id TEXT PRIMARY KEY, from_account_id TEXT, to_account_id TEXT, amount REAL, fee REAL DEFAULT 0, date TEXT, notes TEXT, attachment_path TEXT, reconciled INTEGER DEFAULT 0, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS commissions (id TEXT PRIMARY KEY, employee_id TEXT, invoice_id TEXT, amount REAL, rate REAL, date TEXT, status TEXT DEFAULT 'pending', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS security_audit (id TEXT PRIMARY KEY, user_id TEXT, action TEXT, details TEXT, ip_address TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS documents (id TEXT PRIMARY KEY, owner_id TEXT, owner_type TEXT, name TEXT, type TEXT, file_path TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS quotations (id TEXT PRIMARY KEY, client_id TEXT, client_name TEXT, issue_date TEXT, valid_until TEXT, subtotal REAL DEFAULT 0, tax_amount REAL DEFAULT 0, total REAL DEFAULT 0, status TEXT DEFAULT 'draft', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS quotation_lines (id TEXT PRIMARY KEY, quotation_id TEXT, item_id TEXT, name TEXT, quantity REAL, price REAL, total REAL DEFAULT 0, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS credit_notes (id TEXT PRIMARY KEY, client_id TEXT, invoice_id TEXT, amount REAL, reason TEXT, date TEXT, status TEXT DEFAULT 'draft', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS fiscal_years (id TEXT PRIMARY KEY, name TEXT, start_date TEXT, end_date TEXT, status TEXT DEFAULT 'active', closing_entry_id TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS currency_rates (id TEXT PRIMARY KEY, from_currency TEXT, to_currency TEXT, rate REAL, date TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS budgets (id TEXT PRIMARY KEY, account_id TEXT, period TEXT, budget_amount REAL DEFAULT 0, spent REAL DEFAULT 0, status TEXT DEFAULT 'active', created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS maintenance_schedules (id TEXT PRIMARY KEY, asset_id TEXT, type TEXT, scheduled_date TEXT, completed_date TEXT, status TEXT DEFAULT 'scheduled', notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS recurring_transactions (id TEXT PRIMARY KEY, description TEXT, amount REAL, account_id TEXT, frequency TEXT, next_run_date TEXT, is_active INTEGER DEFAULT 1, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
        "CREATE TABLE IF NOT EXISTS payments (id TEXT PRIMARY KEY, partner_id TEXT, partner_type TEXT, amount REAL, type TEXT, date TEXT, notes TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)",
      ];

      for (final sql in criticalTables) {
        try { await db.execute(sql); } catch (e) { debugPrint('⚠️ $e'); }
      }

      debugPrint("✅ Database Migrated to v65: Safety net — all fixes applied.");
    }

    if (oldVersion < 66) {
      try {
        await db.execute("ALTER TABLE items ADD COLUMN expiry_date TEXT");
        debugPrint("✅ Database Migrated to v66: Added expiry_date to items.");
      } catch (e) {
        debugPrint("⚠️ v66 Migration Warning: expiry_date column might already exist.");
      }
    }

    if (oldVersion < 67) {
      // v67: Fix recurring_transactions table schema
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN description TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN amount REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN sync_status INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN updated_at TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE recurring_transactions ADD COLUMN device_id TEXT"); } catch (_) {}
      debugPrint("✅ Database Migrated to v67: Fixed recurring_transactions schema.");
    }

    if (oldVersion < 68) {
      // v68: Fleet & Equipment Maintenance Enhancement
      try { await db.execute("ALTER TABLE assets ADD COLUMN plate_number TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE assets ADD COLUMN model TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE assets ADD COLUMN year TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE assets ADD COLUMN last_mileage REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE maintenance_schedules ADD COLUMN odometer_reading REAL"); } catch (_) {}
      try { await db.execute("ALTER TABLE maintenance_schedules ADD COLUMN payment_account_id TEXT"); } catch (_) {}
      debugPrint("✅ Database Migrated to v68: Added Fleet Management & Maintenance tracking columns.");
    }

    if (oldVersion < 74) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          parent_id TEXT,
          created_at TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
      try {
        await db.execute("ALTER TABLE documents ADD COLUMN folder_id TEXT");
      } catch (_) {}
      debugPrint("✅ Database Migrated to v74: Added folders support for professional file management.");
    }

    if (oldVersion < 76) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS roles (
          id TEXT PRIMARY KEY,
          company_id TEXT,
          name TEXT,
          user_count INTEGER DEFAULT 0,
          is_preset INTEGER DEFAULT 0,
          permissions TEXT,
          created_at TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
      debugPrint("✅ Database Migrated to v76: Added roles table for Offline Advanced Permissions.");
    }

    if (oldVersion < 77) {
      try {
        await db.execute("ALTER TABLE roles ADD COLUMN created_at TEXT");
      } catch (_) {}
      debugPrint("✅ Database Migrated to v77: Added missing created_at to roles table.");
    }

    if (oldVersion < 78) {
      try { await db.execute("ALTER TABLE companies ADD COLUMN slug TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN company_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN password_hash TEXT"); } catch (_) {}
      debugPrint("✅ Database Migrated to v78: Added slug and company isolation columns.");
    }

    if (oldVersion < 79) {
      try { await db.execute("ALTER TABLE system_users ADD COLUMN phone TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN job_title TEXT"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v79: Added phone and job_title to system_users.");
    }

    if (oldVersion < 81) {
      try { await db.execute("ALTER TABLE crm_leads ADD COLUMN module_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE support_tickets ADD COLUMN module_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE governance_records ADD COLUMN module_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE industrial_jobs ADD COLUMN module_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE specialized_records ADD COLUMN module_id TEXT"); } catch (_) {}
    }

    if (oldVersion < 80) {
      await db.execute('CREATE TABLE IF NOT EXISTS governance_records (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, title TEXT, description TEXT, status TEXT, priority TEXT, meta_data TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS support_tickets (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, title TEXT, priority TEXT, status TEXT, assigned_to TEXT, created_at TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS meeting_records (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, title TEXT, date TEXT, location TEXT, attendees TEXT, minutes TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS crm_leads (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, name TEXT, email TEXT, phone TEXT, source TEXT, status TEXT, value REAL, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS industrial_jobs (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, title TEXT, asset_id TEXT, status TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS specialized_records (id TEXT PRIMARY KEY, module_id TEXT, company_id TEXT, name TEXT, category TEXT, status TEXT, amount REAL, notes TEXT, sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0)');
      debugPrint("💎 Database Migrated to v80: Global Enterprise tables initialized.");
    }

    if (oldVersion < 83) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS module_settings (
          module_id TEXT,
          setting_key TEXT,
          setting_value TEXT,
          PRIMARY KEY (module_id, setting_key)
        )
      ''');
      debugPrint("🛠️ Database Migrated to v83: Added module_settings table.");
    }
    if (oldVersion < 84) {
      // Phase 1: Multi-Branch & Approval Workflows
      await db.execute('''
        CREATE TABLE IF NOT EXISTS branches (
          id TEXT PRIMARY KEY,
          company_id TEXT,
          name TEXT,
          code TEXT,
          address TEXT,
          phone TEXT,
          is_main INTEGER DEFAULT 0,
          status TEXT DEFAULT 'active',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS approval_requests (
          id TEXT PRIMARY KEY,
          entity_type TEXT, -- 'invoice', 'payment', 'journal_entry'
          entity_id TEXT,
          requester_id TEXT,
          approver_id TEXT,
          status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
          request_date TEXT,
          action_date TEXT,
          comments TEXT,
          $metadata
        )
      ''');

      // Add branch_id to core tables for multi-branch isolation
      final tablesToUpdate = [
        'invoices', 'purchase_invoices', 'journal_entries', 'journal_entry_lines',
        'items', 'employees', 'clients', 'suppliers', 'payments', 'warehouses',
        'system_users', 'pos_sessions', 'shifts', 'hr_shifts', 'expenses'
      ];

      for (var table in tablesToUpdate) {
        try {
          await db.execute("ALTER TABLE $table ADD COLUMN branch_id TEXT");
        } catch (_) {
          // Column might already exist in some edge cases
        }
      }

      try {
        await db.execute("ALTER TABLE companies ADD COLUMN is_multi_branch INTEGER DEFAULT 0");
      } catch (_) {}
      
      debugPrint("🚀 Database Migrated to v84: Multi-Branch & Approval Workflows initialized.");
    }
    if (oldVersion < 85) {
      // Phase 2: Advanced Inventory & Supply Chain
      try { await db.execute("ALTER TABLE inventory_transactions ADD COLUMN warehouse_id TEXT"); } catch (_) {}
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_serials (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          serial_number TEXT,
          status TEXT DEFAULT 'available', 
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS landed_costs (
          id TEXT PRIMARY KEY,
          purchase_invoice_id TEXT,
          journal_entry_id TEXT,
          amount REAL,
          description TEXT,
          $metadata
        )
      ''');
      
      debugPrint("🚀 Database Migrated to v85: Advanced Inventory & Supply Chain initialized.");
    }
    if (oldVersion < 86) {
      try { await db.execute("ALTER TABLE fiscal_years ADD COLUMN sync_status INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE fiscal_years ADD COLUMN updated_at TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE fiscal_years ADD COLUMN device_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE fiscal_years ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v86: Fixed fiscal_years schema.");
    }
    if (oldVersion < 87) {
      // Phase 3: Cost Centers & Financial Performance
      try { await db.execute("ALTER TABLE cost_centers ADD COLUMN parent_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE cost_centers ADD COLUMN branch_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE budgets ADD COLUMN branch_id TEXT"); } catch (_) {}
      
      // Ensure metadata columns for these tables
      for (var table in ['cost_centers', 'budgets']) {
        try { await db.execute("ALTER TABLE $table ADD COLUMN sync_status INTEGER DEFAULT 0"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN updated_at TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      }
      
      debugPrint("🚀 Database Migrated to v87: Cost Centers & Budgets enhanced.");
    }
    if (oldVersion < 88) {
      // Phase 4: Advanced HR & Payroll
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_shifts (
          id TEXT PRIMARY KEY,
          name TEXT,
          start_time TEXT,
          end_time TEXT,
          grace_period INTEGER DEFAULT 15,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS loan_installments (
          id TEXT PRIMARY KEY,
          loan_id TEXT,
          due_date TEXT,
          amount REAL,
          status TEXT DEFAULT 'pending',
          $metadata
        )
      ''');

      try { await db.execute("ALTER TABLE employees ADD COLUMN shift_id TEXT"); } catch (_) {}
      
      debugPrint("🚀 Database Migrated to v88: Advanced HR & Payroll initialized.");
    }
    if (oldVersion < 89) {
      // v89: Fix HR Shifts table creation for existing users
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_shifts (
          id TEXT PRIMARY KEY,
          name TEXT,
          start_time TEXT,
          end_time TEXT,
          grace_period INTEGER DEFAULT 15,
          $metadata
        )
      ''');
      debugPrint("🚀 Database Migrated to v89: HR Shifts table created successfully.");
    }

    if (oldVersion < 90) {
      // v90: Manufacturing Phase 2 - WIP & Schema Unification
      try { await db.execute("ALTER TABLE bom ADD COLUMN finished_good_item_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE bom ADD COLUMN estimated_overhead_cost REAL DEFAULT 0"); } catch (_) {}
      
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN actual_qty_produced REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN actual_overhead_cost REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN actual_material_cost REAL DEFAULT 0"); } catch (_) {}
      
      // Ensure WIP account exists
      final accRes = await db.query('accounts', where: 'id = ?', whereArgs: ['ACC_WIP']);
      if (accRes.isEmpty) {
        await db.insert('accounts', {
          'id': 'ACC_WIP',
          'code': '1205',
          'name': 'الإنتاج تحت التشغيل (WIP)',
          'type': 'asset',
          'balance': 0.0,
          'sync_status': 0,
          'is_deleted': 0
        });
      }
      
      debugPrint("🚀 Database Migrated to v90: Manufacturing WIP & Schema Unified.");
    }

    if (oldVersion < 91) {
      // v91: Manufacturing Phase 3 - Quality Control & Cost Centers
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN qc_status TEXT DEFAULT 'pending'"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN qc_notes TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN inspected_by TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN cost_center_id TEXT"); } catch (_) {}
      
      debugPrint("🚀 Database Migrated to v91: QC Tracking & Cost Centers added.");
    }

    if (oldVersion < 92) {
      // v92: Projects Phase 2 - Progress & Cost Tracking
      try { await db.execute("ALTER TABLE projects ADD COLUMN progress REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE projects ADD COLUMN actual_cost REAL DEFAULT 0"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v92: Projects Progress & Cost Tracking added.");
    }

    if (oldVersion < 93) {
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN filed_date TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN filed_at TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN period_label TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN start_date TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN end_date TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN country TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN tax_rate REAL"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN total_sales_tax REAL"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN total_purchase_tax REAL"); } catch (_) {}
      try { await db.execute("ALTER TABLE tax_filings ADD COLUMN net_tax_due REAL"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v93: Tax Filings professional columns added.");
    }

    if (oldVersion < 94) {
      // v94: Ensure employees table has all columns needed by both HR Screen and HR Professional Screen
      try { await db.execute("ALTER TABLE employees ADD COLUMN position TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE employees ADD COLUMN hire_date TEXT"); } catch (_) {}
      // Ensure system_users table has all needed columns (was previously queried as 'users')
      try { await db.execute("ALTER TABLE system_users ADD COLUMN company_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN password_hash TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN phone TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN job_title TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE system_users ADD COLUMN name TEXT"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v94: Unified HR & Users schema integrity fix.");
    }

    // v95 was previously applied — kept for compatibility
    if (oldVersion < 95) {
      debugPrint("🚀 Database Migrated to v95: (legacy — no-op).");
    }

    if (oldVersion < 97) {
      // v97: Stage 1 Infrastructure - Generic Module Records & Structured HR
      await db.execute('''
        CREATE TABLE IF NOT EXISTS module_records (
          id TEXT PRIMARY KEY,
          module_id TEXT NOT NULL,
          data TEXT NOT NULL, -- JSON formatted data
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_departments (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          manager_id TEXT,
          parent_id TEXT,
          created_at TEXT,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS hr_positions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          department_id TEXT,
          description TEXT,
          salary_range_min REAL,
          salary_range_max REAL,
          created_at TEXT,
          updated_at TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS contracts (
          id TEXT PRIMARY KEY,
          module_id TEXT, -- For differentiating between HR, Client, Supplier contracts
          title TEXT,
          party_id TEXT, -- ID of employee, client, or supplier
          party_type TEXT, -- 'employee', 'client', 'supplier'
          start_date TEXT,
          end_date TEXT,
          amount REAL,
          status TEXT DEFAULT 'active',
          file_path TEXT,
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      debugPrint("🚀 Database Migrated to v97: Infrastructure Stage 1 (Module Records, HR Structure, Contracts) initialized.");
    }

    if (oldVersion < 101) {
      // ══════════════════════════════════════════════════════════════════
      // v101: Final Professionalization Suite
      // ══════════════════════════════════════════════════════════════════
      
      // 1. Employee Loans: Interest & Remaining Balance Fix
      try { await db.execute('ALTER TABLE employee_loans ADD COLUMN interest_rate REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE employee_loans ADD COLUMN total_interest REAL DEFAULT 0'); } catch (_) {}
      
      // 2. Payroll Structure (JSON for allowances/deductions)
      try { await db.execute('ALTER TABLE employees ADD COLUMN allowances_json TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE employees ADD COLUMN deductions_json TEXT'); } catch (_) {}
      
      // 3. Supplier Performance
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN lead_time_rating INTEGER DEFAULT 5'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN price_rating INTEGER DEFAULT 5'); } catch (_) {}
      try { await db.execute('ALTER TABLE suppliers ADD COLUMN quality_rating INTEGER DEFAULT 5'); } catch (_) {}
      
      // 4. Financial Custody Settlements
      try { await db.execute('ALTER TABLE financial_custodies ADD COLUMN settlement_status TEXT DEFAULT "pending"'); } catch (_) {}
      try { await db.execute('ALTER TABLE financial_custodies ADD COLUMN settlement_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE financial_custodies ADD COLUMN settlement_entry_id TEXT'); } catch (_) {}

      // 5. Asset Transfers
      try { await db.execute('ALTER TABLE assets ADD COLUMN current_branch_id TEXT'); } catch (_) {}

      debugPrint("🚀 Database Migrated to v101: Final Professionalization Suite complete.");
    }

    if (oldVersion < 125) {
      // v125: Fix missing schema columns
      try { await db.execute("ALTER TABLE branches ADD COLUMN location TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE branches ADD COLUMN manager_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE performance_reviews ADD COLUMN comments TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE performance_reviews ADD COLUMN reviewer_id TEXT"); } catch (_) {}
      try { await db.execute("UPDATE performance_reviews SET comments = manager_feedback WHERE comments IS NULL AND manager_feedback IS NOT NULL"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v125: Missing schema columns added.");
    }

    if (oldVersion < 126) {
      // v126: Comprehensive Data Visibility Fix
      // 1. Missing columns in core tables
      try { await db.execute("ALTER TABLE journal_entries ADD COLUMN is_deleted INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE invoices ADD COLUMN is_return INTEGER DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE purchase_invoices ADD COLUMN is_return INTEGER DEFAULT 0"); } catch (_) {}
      
      // 2. Supplier performance ratings (if missed in earlier migrations)
      try { await db.execute("ALTER TABLE suppliers ADD COLUMN lead_time_rating INTEGER DEFAULT 5"); } catch (_) {}
      try { await db.execute("ALTER TABLE suppliers ADD COLUMN price_rating INTEGER DEFAULT 5"); } catch (_) {}
      try { await db.execute("ALTER TABLE suppliers ADD COLUMN quality_rating INTEGER DEFAULT 5"); } catch (_) {}

      // 3. New Tables for Specialized Modules
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_alerts (
          id TEXT PRIMARY KEY,
          type TEXT, -- 'risk', 'compliance', 'unusual_activity'
          severity TEXT, -- 'high', 'medium', 'low'
          message TEXT,
          date TEXT,
          is_resolved INTEGER DEFAULT 0,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_receipts (
          id TEXT PRIMARY KEY,
          total REAL DEFAULT 0,
          subtotal REAL DEFAULT 0,
          tax_amount REAL DEFAULT 0,
          discount_amount REAL DEFAULT 0,
          date TEXT,
          client_id TEXT,
          shift_id TEXT,
          payment_method TEXT DEFAULT 'cash',
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_receipt_lines (
          id TEXT PRIMARY KEY,
          receipt_id TEXT,
          item_id TEXT,
          name TEXT,
          quantity REAL,
          price REAL,
          total REAL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS promotions (
          id TEXT PRIMARY KEY,
          item_id TEXT,
          discount_percentage REAL,
          reason TEXT,
          $metadata
        )
      ''');

      // 4. Update feasibility_studies to match specialized module fields
      try { await db.execute("DROP TABLE IF EXISTS feasibility_studies"); } catch(_) {}
      await db.execute('''
        CREATE TABLE feasibility_studies (
          id TEXT PRIMARY KEY,
          project_name TEXT,
          sector TEXT,
          country TEXT,
          capital REAL,
          monthly_costs REAL,
          monthly_revenue REAL,
          study_years INTEGER,
          discount_rate REAL,
          npv REAL,
          irr REAL,
          payback_months INTEGER,
          success_rate REAL,
          scenario TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_trail (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          action TEXT,
          table_name TEXT,
          record_id TEXT,
          old_data TEXT,
          new_data TEXT,
          $metadata
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_targets (
          id TEXT PRIMARY KEY,
          agent_id TEXT,
          target_amount REAL,
          period TEXT,
          $metadata
        )
      ''');

      debugPrint("🚀 Database Migrated to v126: All missing tables and data visibility patches applied.");
    }

    if (oldVersion < 127) {
      // v127: Fix 'contracts' table column inconsistency (amount vs value)
      try { 
        await db.execute("ALTER TABLE contracts ADD COLUMN value REAL DEFAULT 0"); 
        debugPrint("✅ Added 'value' column to contracts table.");
      } catch (e) {
        debugPrint("ℹ️ contracts.value might already exist: $e");
      }
      debugPrint("🚀 Database Migrated to v127: Contracts schema repaired.");
    }

    if (oldVersion < 128) {
      // v128: Ensure all sync metadata columns exist for contracts
      final contractsColumns = {
        'device_id': 'TEXT',
        'updated_at': 'TEXT',
        'sync_status': 'INTEGER DEFAULT 0',
        'is_deleted': 'INTEGER DEFAULT 0',
        'created_at': 'TEXT',
      };
      for (var col in contractsColumns.entries) {
        try { 
          await db.execute("ALTER TABLE contracts ADD COLUMN ${col.key} ${col.value}"); 
          debugPrint("✅ Added '${col.key}' to contracts table.");
        } catch (_) {}
      }
      debugPrint("🚀 Database Migrated to v128: Contracts metadata repaired.");
    }

    if (oldVersion < 129) {
      try {
        await db.execute("ALTER TABLE payments ADD COLUMN payment_method TEXT");
        debugPrint("✅ Added 'payment_method' to payments table.");
      } catch (e) {
        debugPrint("ℹ️ payments.payment_method might already exist: $e");
      }
      debugPrint("🚀 Database Migrated to v129: Payments schema repaired.");
    }
    
    if (oldVersion < 130) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS risk_incidents (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          impact TEXT,
          status TEXT, -- 'pending', 'investigating', 'mitigated', 'resolved'
          date TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
      ''');
    }

    if (oldVersion < 131) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS governance_records (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          status TEXT DEFAULT 'Active',
          notes TEXT,
          created_at TEXT,
          updated_at TEXT,
          sync_status INTEGER DEFAULT 0,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 132) {
      // v132: Harmonize support_tickets schema (ensure 'subject' and 'description' exist)
      final supportColumns = {
        'subject': 'TEXT',
        'description': 'TEXT',
        'module_id': 'TEXT',
        'company_id': 'TEXT',
      };
      for (var col in supportColumns.entries) {
        try { 
          await db.execute("ALTER TABLE support_tickets ADD COLUMN ${col.key} ${col.value}"); 
        } catch (_) {}
      }
      debugPrint("🚀 Database Migrated to v132: Support tickets schema repaired.");
    }

    if (oldVersion < 133) {
      // v133: Harmonize meetings schema
      final meetingColumns = {
        'updated_at': 'TEXT',
        'sync_status': 'INTEGER DEFAULT 0',
        'device_id': 'TEXT',
        'created_at': 'TEXT',
      };
      for (var col in meetingColumns.entries) {
        try { 
          await db.execute("ALTER TABLE meetings ADD COLUMN ${col.key} ${col.value}"); 
        } catch (_) {}
      }
      debugPrint("🚀 Database Migrated to v133: Meetings schema repaired.");
    }

    if (oldVersion < 134) {
      // v134: Fix POS Receipts schema
      try {
        await db.execute("ALTER TABLE pos_receipts ADD COLUMN subtotal REAL DEFAULT 0");
      } catch (_) {}
      debugPrint("🚀 Database Migrated to v134: POS Receipts subtotal added.");
    }
    if (oldVersion < 135) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS risk_incidents (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          impact TEXT DEFAULT 'medium',
          status TEXT DEFAULT 'pending',
          date TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          created_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      try { await db.execute("ALTER TABLE medical_patients ADD COLUMN email TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE medical_patients ADD COLUMN dob TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE medical_patients ADD COLUMN gender TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE medical_patients ADD COLUMN blood_group TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE hotel_rooms ADD COLUMN floor TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE hotel_rooms ADD COLUMN last_cleaned TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE hotel_bookings ADD COLUMN guest_phone TEXT"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v135");
    }

    if (oldVersion < 136) {
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN order_no TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN product_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN actual_qty_produced REAL DEFAULT 0"); } catch (_) {}
      try { await db.execute("ALTER TABLE manufacturing_orders ADD COLUMN completed_at TEXT"); } catch (_) {}
      debugPrint("🚀 Database Migrated to v136: Manufacturing Orders columns added.");
    }

    if (oldVersion < 137) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS real_estate_maintenance (
          id TEXT PRIMARY KEY,
          unit_id TEXT,
          description TEXT,
          request_date TEXT,
          completion_date TEXT,
          cost REAL DEFAULT 0,
          status TEXT DEFAULT 'pending',
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
      debugPrint("🚀 Database Migrated to v137: Real Estate Maintenance table added.");
    }

    if (oldVersion < 138) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fleet_driver_assignments (
          id TEXT PRIMARY KEY,
          vehicle_id TEXT,
          employee_id TEXT,
          start_date TEXT,
          end_date TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
      debugPrint("🚀 Database Migrated to v138: Fleet Driver Assignments table added.");
    }

    if (oldVersion < 139) {
      try {
        await db.execute("ALTER TABLE medical_medicines ADD COLUMN price REAL DEFAULT 0");
        debugPrint("✅ Added 'price' column to medical_medicines table.");
      } catch (e) {
        debugPrint("ℹ️ medical_medicines.price might already exist: $e");
      }
      debugPrint("🚀 Database Migrated to v139: Medical medicines price column added.");
    }

    if (oldVersion < 140) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          parent_id TEXT,
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS documents (
          id TEXT PRIMARY KEY,
          name TEXT,
          file_path TEXT,
          file_type TEXT,
          folder_id TEXT,
          status TEXT DEFAULT 'active',
          sync_status INTEGER DEFAULT 0,
          updated_at TEXT,
          device_id TEXT,
          is_deleted INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
      debugPrint("🚀 Database Migrated to v140: File Manager tables added.");
    }

    if (oldVersion < 141) {
      // v141: Add tenant_id to real_estate_contracts for professional client linking
      try {
        await db.execute("ALTER TABLE real_estate_contracts ADD COLUMN tenant_id TEXT");
        debugPrint("✅ Added tenant_id to real_estate_contracts");
      } catch (e) {
        debugPrint("⚠️ Could not add tenant_id to real_estate_contracts: $e");
      }
    }

    if (oldVersion < 142) {
      // v142: Finalizing Industrial Schema (Mixing Batches, Sanitary Ware, Electronics)
      try { await db.execute("ALTER TABLE mixing_batches ADD COLUMN status TEXT DEFAULT 'COMPLETED'"); } catch (_) {}
      try { await db.execute("ALTER TABLE mixing_batches ADD COLUMN branch_id TEXT"); } catch (_) {}
      
      try { await db.execute("ALTER TABLE sanitary_sets ADD COLUMN description TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE sanitary_sets ADD COLUMN status TEXT DEFAULT 'ACTIVE'"); } catch (_) {}
      try { await db.execute("ALTER TABLE sanitary_sets ADD COLUMN branch_id TEXT"); } catch (_) {}
      
      try { await db.execute("ALTER TABLE warranty_claims ADD COLUMN serial_number TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE warranty_claims ADD COLUMN model TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE warranty_claims ADD COLUMN issue TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE warranty_claims ADD COLUMN branch_id TEXT"); } catch (_) {}
      
      debugPrint("🚀 Database Migrated to v142: Industrial Schema Finalized.");
    }

    if (oldVersion < 143) {
      // 1. Fix Furniture Professional
      try { await db.execute("ALTER TABLE furniture_assemblies ADD COLUMN notes TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE furniture_assemblies ADD COLUMN created_at TEXT"); } catch (_) {}
      
      // 2. Fix Fleet & Specialized missing columns
      final industryTables = [
        'fleet_vehicles', 'wood_inventory', 'appliance_inventory', 
        'warranty_claims', 'chemical_inventory', 'mixing_batches', 
        'sanitary_inventory', 'sanitary_sets', 'office_service_catalog', 
        'service_bookings', 'real_estate_units', 'real_estate_contracts'
      ];
      
      for (var table in industryTables) {
        try { await db.execute("ALTER TABLE $table ADD COLUMN created_at TEXT"); } catch (_) {}
        try { await db.execute("ALTER TABLE $table ADD COLUMN updated_at TEXT"); } catch (_) {}
      }
      
      debugPrint("🚀 Database Migrated to v143: Industrial Schema Stabilization Complete.");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Standard Metadata columns for ALL tables in v35
    const String metadata = 'sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0';

    await db.execute('''
      CREATE TABLE companies (
        id TEXT PRIMARY KEY,
        slug TEXT,
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
        closing_date TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        cr_number TEXT,
        tax_id TEXT,
        address TEXT,
        balance REAL DEFAULT 0,
        credit_limit REAL DEFAULT 0,
        category TEXT DEFAULT 'regular', -- 'vip', 'regular', 'debtor'
        user_id TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS risk_incidents (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        impact TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        date TEXT,
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
        expiry_date TEXT,
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
      CREATE TABLE user_roles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        permissions TEXT NOT NULL, -- JSON List of dot-notation perms
        is_system INTEGER DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE contracts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        contract_type TEXT, -- 'client', 'supplier', 'employee', 'legal'
        party_id TEXT, -- ID of client/supplier/employee
        start_date TEXT,
        end_date TEXT,
        amount REAL DEFAULT 0,
        value REAL DEFAULT 0,
        status TEXT DEFAULT 'active', -- 'active', 'expired', 'terminated'
        description TEXT,
        attachment_path TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        is_deleted INTEGER DEFAULT 0
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
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT,
        parent_id TEXT,
        created_at TEXT,
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
        plate_number TEXT,
        model TEXT,
        year TEXT,
        last_mileage REAL DEFAULT 0,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE fleet_fuel_logs (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        date TEXT,
        liter_count REAL,
        cost REAL,
        odometer REAL,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE fleet_maintenance_logs (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        date TEXT,
        description TEXT,
        cost REAL,
        next_maintenance_date TEXT,
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
        check_in TEXT,
        check_out TEXT,
        check_in_time TEXT,
        check_out_time TEXT,
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
        payment_method TEXT,
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
        progress REAL DEFAULT 0,
        actual_cost REAL DEFAULT 0,
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
      CREATE TABLE hr_shifts (
        id TEXT PRIMARY KEY,
        name TEXT,
        start_time TEXT,
        end_time TEXT,
        grace_period INTEGER DEFAULT 15,
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
        odometer_reading REAL,
        payment_account_id TEXT,
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
        budget_amount REAL DEFAULT 0,
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
        company_id TEXT,
        username TEXT UNIQUE,
        name TEXT,
        email TEXT,
        phone TEXT,
        job_title TEXT,
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
      CREATE TABLE roles (
        id TEXT PRIMARY KEY,
        company_id TEXT,
        name TEXT,
        user_count INTEGER DEFAULT 0,
        is_preset INTEGER DEFAULT 0,
        permissions TEXT,
        created_at TEXT,
        $metadata
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
        folder_id TEXT,
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
        description TEXT,
        amount REAL,
        account_id TEXT,
        frequency TEXT, -- 'daily', 'weekly', 'monthly', 'yearly'
        next_run_date TEXT,
        last_run_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        $metadata
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
      CREATE TABLE manufacturing_specifications (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        type TEXT, -- 'glass_type', 'thickness', 'edging', 'tempering'
        value TEXT,
        notes TEXT,
        $metadata
      )
    ''');

    await db.execute('''
      CREATE TABLE manufacturing_cut_list (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        width REAL,
        height REAL,
        quantity INTEGER,
        is_cut INTEGER DEFAULT 0,
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

    // Dedicated Expenses table (petty cash, operational costs)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        category TEXT DEFAULT 'misc',
        expense_date TEXT,
        payment_method TEXT DEFAULT 'cash',
        vendor TEXT,
        reference_no TEXT,
        notes TEXT,
        status TEXT DEFAULT 'approved',
        attachment_path TEXT,
        created_by TEXT,
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS specialized_records (
        id TEXT PRIMARY KEY,
        module_id TEXT NOT NULL,
        name TEXT,
        category TEXT,
        amount REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        device_id TEXT,
        is_deleted INTEGER DEFAULT 0
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
          'sync_status': 0,
          'updated_at': DateTime.now().toIso8601String(),
          'device_id': 'system_seed',
          'is_deleted': 0
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      // Ensure maintenance expense account exists
      await db.insert('accounts', {
        'id': 'ACC_EXPENSE_MAINTENANCE',
        'code': '5260',
        'name': 'مصروفات صيانة الأسطول والمعدات',
        'type': 'expense',
        'sync_status': 0,
        'updated_at': DateTime.now().toIso8601String(),
        'device_id': 'system_seed',
        'is_deleted': 0
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _seedDefaultCostCenters(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM cost_centers');
    if ((count.first['count'] as int) == 0) {
      await db.insert('cost_centers', {'id': 'CC_MAIN', 'name': 'المركز الرئيسي', 'code': '100'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('cost_centers', {'id': 'CC_SALES', 'name': 'قسم المبيعات', 'code': '200'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
