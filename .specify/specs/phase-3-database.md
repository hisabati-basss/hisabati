# المرحلة 3: إكمال قاعدة البيانات 100%

## الأولوية: 🟠 عالية

## السياق
قاعدة البيانات حالياً تحتوي ~35 جدول لكنها تحتاج ~15 جدول إضافي وإصلاح عدة ثغرات.

## المهام

### 3.1 إصلاح الثغرات الحالية
**ملف:** `lib/services/database_helper.dart`

#### 3.1.1 توحيد أسماء الجداول المكررة
- [ ] دمج `asset_custody_log` (v16) مع `asset_custody_logs` (v30)
- [ ] الاحتفاظ بـ `asset_custody_logs` فقط (الأحدث)
- [ ] migration لنقل البيانات من القديم للجديد

#### 3.1.2 إصلاح sync_status
- [ ] البحث عن كل مكان يستخدم `'pending'` كقيمة string
- [ ] استبدالها بـ `0` (INTEGER)
- [ ] القيم المعتمدة: 0=غير مزامن، 1=مزامن

#### 3.1.3 إضافة migration v48-v49
```dart
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
      permissions TEXT, -- JSON string of permissions
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
    CREATE TABLE IF NOT EXISTS audit_trail (
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
```

### 3.2 إضافة CRUD Methods للجداول الجديدة
- [ ] `addQuotation()`, `getQuotations()`, `convertQuotationToInvoice()`
- [ ] `addReceiptVoucher()`, `getReceiptVouchers()`
- [ ] `addPaymentVoucher()`, `getPaymentVouchers()`
- [ ] `addCreditNote()`, `getCreditNotes()`
- [ ] `addAuditTrailEntry()`, `getAuditTrail()`
- [ ] `addTask()`, `getTasks()`, `updateTaskStatus()`
- [ ] `addDocument()`, `getDocuments()`
- [ ] `addCurrencyRate()`, `convertCurrency()`
- [ ] `addFiscalYear()`, `closeFiscalYear()`

### 3.3 التأكد من _onCreate يشمل كل الجداول
- [ ] نقل كل CREATE TABLE من migrations إلى `_onCreate` أيضاً
- [ ] هذا يضمن أن التثبيت الجديد ينشئ كل شيء دفعة واحدة

## التحقق
- [ ] حذف قاعدة البيانات وإعادة تشغيل → كل الجداول تنشأ
- [ ] ترقية من نسخة قديمة → كل الجداول تضاف بأمان
- [ ] كل CRUD method يعمل بدون أخطاء
