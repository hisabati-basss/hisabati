# المرحلة 12: إكمال المحاسبة الاحترافية (QuickBooks Level)

## الأولوية: 🔴 حرجة

## السياق
المحاسبة هي قلب النظام. الوظائف التالية **موجودة في قاعدة البيانات (جداول مهيأة)** لكن **لا شاشات ولا خدمات تستخدمها**.

## التقنيات المستخدمة
- **DB**: SQLite via `database_helper.dart` — كل جدول يستخدم metadata: `sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0`
- **Theme**: استخدم `context.isDark`, `context.bgSurface`, `context.cardSurface`, `context.textColor`, `context.mutedText`, `context.obsidianGlass`, `context.sheetGlass`, `context.glassBorder`, `context.primaryGradient` من `lib/theme/app_theme_extension.dart`
- **الألوان**: `primaryOrange = Color(0xFFFF6B00)`, `sunsetStart`, `sunsetEnd`, `accentGold`
- **أحجام الخطوط**: `context.headerSize` (18), `context.subHeaderSize` (14), `context.bodySize` (11)
- **Glassmorphism**: استخدم `GlassContainer` من `lib/widgets/glass_container.dart` أو `ClipRRect` + `BackdropFilter`
- **التصميم**: Apple-inspired — rounded corners, soft shadows, gradients

## المهام

### 12.1 إشعار دائن (Credit Note / مرتجع مبيعات)
**ملف جديد:** `lib/screens/credit_note_screen.dart`

**الجدول في DB (موجود):** `credit_notes` (أُنشئ في v49 من `database_helper.dart` سطر 287-301)
```sql
CREATE TABLE credit_notes (
  id TEXT PRIMARY KEY,
  original_invoice_id TEXT,
  client_id TEXT,
  amount REAL,
  reason TEXT,
  date TEXT,
  journal_entry_id TEXT,
  status TEXT DEFAULT 'draft',
  created_at TEXT, updated_at TEXT,
  sync_status INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0
)
```

**الوظائف المطلوبة:**
1. قائمة جميع الإشعارات الدائنة مع فلترة (مسودة، معتمد)
2. إنشاء إشعار دائن جديد → ربط بفاتورة أصلية → إدخال المبلغ والسبب
3. عند الاعتماد → إنشاء قيد عكسي تلقائي:
   - مدين: المبيعات ← دائن: المدينين (بقيمة الإشعار)
4. تحديث رصيد العميل
5. طباعة PDF

**تحديث `accounting_engine.dart`:**
```dart
Future<void> processCreditNote({required String invoiceId, required double amount, required String reason}) async {
  // 1. إنشاء سجل في credit_notes
  // 2. إنشاء قيد يومية عكسي
  // 3. تحديث رصيد العميل في clients
}
```

### 12.2 إشعار مدين (Debit Note / مرتجع مشتريات)
**ملف جديد:** `lib/screens/debit_note_screen.dart`

**الجدول في DB (موجود):** `debit_notes` (أُنشئ في v49)

**نفس منطق الإشعار الدائن** لكن عكسي:
- مدين: الدائنين ← دائن: المشتريات (بقيمة الإشعار)
- تحديث رصيد المورد في `suppliers`

### 12.3 أوامر الشراء (Purchase Orders)
**ملف جديد:** `lib/screens/purchase_order_screen.dart`

**الجدول في DB (غير موجود — يحتاج إنشاء):**
```sql
-- يُضاف في _onUpgrade عند v55
CREATE TABLE IF NOT EXISTS purchase_orders (
  id TEXT PRIMARY KEY,
  supplier_id TEXT,
  issue_date TEXT,
  expected_delivery TEXT,
  subtotal REAL,
  tax_amount REAL,
  total REAL,
  status TEXT DEFAULT 'draft', -- draft, sent, received, cancelled
  notes TEXT,
  converted_invoice_id TEXT,
  created_at TEXT, updated_at TEXT,
  sync_status INTEGER DEFAULT 0, device_id TEXT, is_deleted INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id TEXT PRIMARY KEY,
  order_id TEXT,
  item_id TEXT,
  name TEXT,
  quantity REAL,
  price REAL,
  total REAL,
  sync_status INTEGER DEFAULT 0, device_id TEXT, updated_at TEXT, is_deleted INTEGER DEFAULT 0
);
```

**الوظائف المطلوبة:**
1. قائمة أوامر الشراء مع فلترة حسب الحالة
2. إنشاء أمر شراء جديد (نفس تصميم فاتورة المشتريات)
3. زر "تحويل إلى فاتورة مشتريات" بضغطة واحدة
4. إرسال أمر الشراء بالبريد كـ PDF
5. طباعة PDF

### 12.4 الفواتير المتكررة (Recurring Invoices)
**ملف جديد:** `lib/screens/recurring_invoices_screen.dart`

**الجدول في DB (موجود):** `recurring_transactions` (أُنشئ في v49)
```sql
CREATE TABLE recurring_transactions (
  id TEXT PRIMARY KEY,
  type TEXT, -- 'invoice', 'expense', 'journal'
  template_data TEXT, -- JSON string للبيانات
  frequency TEXT, -- 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  next_run_date TEXT,
  last_run_date TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT
)
```

**الوظائف المطلوبة:**
1. قائمة الفواتير المتكررة (نشطة / متوقفة)
2. إنشاء قالب فاتورة متكررة (نفس حقول الفاتورة العادية + التكرار)
3. عند حلول الموعد → إنشاء الفاتورة تلقائياً (في `_loadInitialData` أو timer)
4. إيقاف/تشغيل التكرار

### 12.5 أعمار الديون (Aging Report)
**ملف جديد:** `lib/screens/aging_report_screen.dart`

**لا يحتاج جدول جديد** — يستخدم بيانات `invoices` و `purchase_invoices` الحالية.

**الوظائف المطلوبة:**
1. تبويب: مدينون (عملاء) | دائنون (موردين)
2. لكل عميل/مورد → عرض المبالغ المعلقة مقسمة:
   - 0-30 يوم (أخضر)
   - 31-60 يوم (أصفر)
   - 61-90 يوم (برتقالي)
   - 90+ يوم (أحمر)
3. إجمالي لكل فئة عمرية
4. زر تصدير CSV
5. زر تصدير PDF

**حساب العمر:**
```dart
final daysSinceInvoice = DateTime.now().difference(DateTime.parse(invoice['due_date'] ?? invoice['issue_date'])).inDays;
```

### 12.6 إقفال السنة المالية (Fiscal Year Close)
**ملف جديد:** `lib/screens/fiscal_year_screen.dart`

**الجدول في DB (موجود):** `fiscal_years` (أُنشئ في v49)

**تحديث `accounting_engine.dart`:**
```dart
Future<void> closeFiscalYear(String yearId) async {
  // 1. حساب إجمالي الإيرادات وإجمالي المصروفات
  // 2. حساب صافي الربح/الخسارة
  // 3. إنشاء قيد إقفال:
  //    - مدين: كل حسابات الإيرادات (إلى صفر)
  //    - دائن: كل حسابات المصروفات (إلى صفر)
  //    - الفرق → أرباح محتجزة
  // 4. تعيين is_closed = 1
  // 5. منع التعديل على قيود قبل تاريخ الإقفال
}
```

### 12.7 ربط POS بالمخزون
**ملف:** `lib/screens/pos_screen.dart`

حالياً POS ينشئ فاتورة لكن **لا يخصم من المخزون**. يجب:
1. عند إتمام البيع → `UPDATE items SET quantity = quantity - ? WHERE id = ?`
2. إنشاء سجل في `inventory_transactions` (type: 'sale')
3. إذا الكمية < `min_stock_level` → إظهار تنبيه
4. إذا الكمية = 0 → منع البيع مع خيار override

### 12.8 ربط الفواتير بالمخزون
**ملف:** `lib/screens/invoice_entry_screen.dart` + `lib/core/accounting/accounting_engine.dart`

عند إنشاء فاتورة مبيعات:
1. خصم الأصناف من `items.quantity`
2. إنشاء سجل في `inventory_transactions`
3. حساب COGS وإنشاء القيد المحاسبي

عند إنشاء فاتورة مشتريات:
1. إضافة الأصناف إلى `items.quantity`
2. تحديث `items.cost_price` (متوسط مرجح)
3. إنشاء سجل في `inventory_transactions`

## تنبيهات للمنفذ
> ⚠️ كل شاشة جديدة يجب أن تستخدم نفس تصميم الشاشات الموجودة (glassmorphism + Apple-style)
> ⚠️ كل شاشة يجب أن تدعم RTL (العربية) و LTR (الإنجليزية) باستخدام `easy_localization`
> ⚠️ كل شاشة يجب أن تُضاف في `main.dart` ضمن قائمة الـ screens و الـ Navigation
> ⚠️ لا تنسى تحديث `_databaseVersion` في `database_helper.dart` عند إضافة جداول جديدة
> ⚠️ كل عملية CRUD يجب أن تضع `updated_at: DateTime.now().toIso8601String()` و `sync_status: 0`

## معايير القبول
- [ ] إشعار دائن → ينشئ قيد عكسي + يحدث رصيد العميل
- [ ] أمر شراء → يتحول لفاتورة مشتريات بضغطة
- [ ] فاتورة متكررة → تنشأ تلقائياً في موعدها
- [ ] أعمار الديون → تعرض الفئات الأربع بألوان صحيحة
- [ ] إقفال سنة مالية → يرحل الأرصدة ويمنع التعديل
- [ ] بيع في POS → كمية المخزون تنقص فوراً
- [ ] فاتورة مبيعات → COGS يُحسب + مخزون ينقص
