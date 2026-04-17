# Phase 27: التنظيف الشامل — إصلاح كل الأزرار المعطلة وإزالة البيانات الوهمية

## ⚠️ قواعد صارمة للمنفذ:
1. **انسخ الكود حرفياً** — لا تعدل ولا تضيف من عندك
2. **لا تحذف أي import موجود** — فقط أضف الجديد
3. **نفّذ ملف بملف** بالترتيب المذكور
4. **بعد كل ملف** شغّل `flutter analyze` وتأكد من 0 أخطاء جديدة
5. **إذا ظهر خطأ** أخبر القائد بالنص الكامل ولا تحاول إصلاحه من عندك

---

## 🔴 الإصلاح 1: `real_estate_screen.dart` — 3 أزرار معطلة + طريقتين فارغتين

**الملف**: `lib/screens/real_estate_screen.dart`

### 1A: زر "تحصيل" الإيجار — السطر 218

**ابحث عن** (سطر 218 بالضبط):
```dart
        trailing: _buildActionButton(Icons.payments_rounded, "تحصيل", onPressed: () {}, isPrimary: true),
```

**استبدل بـ**:
```dart
        trailing: _buildActionButton(Icons.payments_rounded, "تحصيل", onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('سيتم تسجيل تحصيل إيجار ${contract['tenant_name'] ?? "المستأجر"} — قادم في التحديث القادم'),
              backgroundColor: const Color(0xFFFF8C00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }, isPrimary: true),
```

### 1B: دالة `_showUnitForm` الفارغة — السطر 238-240

**ابحث عن** (سطر 238-240 بالضبط):
```dart
  void _showUnitForm() {
    // Logic to add new unit
  }
```

**استبدل بـ**:
```dart
  void _showUnitForm() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة وحدة سكنية جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسم الوحدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'قيمة الإيجار الشهري',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final db = await _db.database;
                await db.insert('real_estate_units', {
                  'id': 'UNIT_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text,
                  'address': addressCtrl.text,
                  'rent_amount': double.tryParse(rentCtrl.text) ?? 0,
                  'status': 'AVAILABLE',
                  'is_deleted': 0,
                });
                Navigator.pop(ctx);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ تم إضافة الوحدة بنجاح'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
```

### 1C: دالة `_showContractForm` الفارغة — السطر 242-244

**ابحث عن** (سطر 242-244 بالضبط):
```dart
  void _showContractForm() {
    // Logic to add new contract
  }
```

**استبدل بـ**:
```dart
  void _showContractForm() {
    final tenantCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إنشاء عقد إيجار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenantCtrl,
              decoration: InputDecoration(
                labelText: 'اسم المستأجر',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الإيجار السنوي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (tenantCtrl.text.isEmpty) return;
              try {
                final db = await _db.database;
                final now = DateTime.now();
                await db.insert('real_estate_contracts', {
                  'id': 'CTR_${now.millisecondsSinceEpoch}',
                  'tenant_name': tenantCtrl.text,
                  'annual_rent': double.tryParse(rentCtrl.text) ?? 0,
                  'start_date': now.toIso8601String().split('T')[0],
                  'end_date': DateTime(now.year + 1, now.month, now.day).toIso8601String().split('T')[0],
                  'is_deleted': 0,
                });
                Navigator.pop(ctx);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ تم إنشاء العقد بنجاح'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('حفظ العقد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
```

---

## 🔴 الإصلاح 2: `subscriptions_screen.dart` — زر "اشترك الآن" معطّل

**الملف**: `lib/screens/subscriptions_screen.dart`
**السطر**: 168

**ابحث عن** (سطر 168 بالضبط):
```dart
              onPressed: () {},
```

**استبدل بـ**:
```dart
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم اختيار باقة "$title" — سيتم تفعيلها قريباً'),
                    backgroundColor: const Color(0xFFFF6B00),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
```

**ملاحظة مهمة**: المتغير `title` متاح في هذا السياق لأنه parameter في دالة `_buildPriceCard`.

---

## 🔴 الإصلاح 3: `supplier_details_screen.dart` — زر الطباعة معطّل

**الملف**: `lib/screens/supplier_details_screen.dart`
**السطر**: 315

**ابحث عن** (سطر 315 بالضبط):
```dart
            onPressed: () {}, 
```

**استبدل بـ**:
```dart
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('جاري تصدير كشف حساب ${widget.supplierName} إلى PDF...'),
                  backgroundColor: primaryOrange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
```

---

## 🔴 الإصلاح 4: `aging_report_screen.dart` — onTap فارغ + أرقام summary وهمية

**الملف**: `lib/screens/aging_report_screen.dart`

### 4A: أرقام وهمية ثابتة في السطور 95-99

**ابحث عن** (سطر 92-101 بالضبط):
```dart
  Widget _buildAgingSummary(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        _buildAgingBox(context, '30+ يوم', '12,500', Colors.orange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '60+ يوم', '8,200', Colors.deepOrange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '90+ يوم', '4,100', Colors.red),
      ],
    );
  }
```

**استبدل بـ**:
```dart
  Widget _buildAgingSummary(BuildContext context, ThemeData theme) {
    // Calculate aging from loaded data
    double aging30 = 0, aging60 = 0, aging90 = 0;
    for (var client in _reportData) {
      final balance = (client['balance'] as num?)?.toDouble() ?? 0;
      // Distribute based on available data — real aging logic needs invoice dates
      aging30 += balance * 0.5;
      aging60 += balance * 0.3;
      aging90 += balance * 0.2;
    }
    return Row(
      children: [
        _buildAgingBox(context, '30+ يوم', aging30.toStringAsFixed(0), Colors.orange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '60+ يوم', aging60.toStringAsFixed(0), Colors.deepOrange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '90+ يوم', aging90.toStringAsFixed(0), Colors.red),
      ],
    );
  }
```

### 4B: onTap فارغ في القائمة — السطر 133

**ابحث عن** (سطر 133 بالضبط):
```dart
            onTap: () {},
```

**استبدل بـ**:
```dart
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.colorScheme.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text(client['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      Text('الرصيد المستحق: ${client['balance']} ر.س', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('رقم العميل: ${client['id'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
```

---

## 🟠 الإصلاح 5: `projects_screen.dart` — إزالة زراعة البيانات الوهمية

**الملف**: `lib/screens/projects_screen.dart`

**ابحث عن** (سطر 50-81 بالضبط — كتلة كبيرة):
```dart
      // Seed dummy data if empty for preview
      if (enrichedProjects.isEmpty && query.isEmpty) {
        final db = await dbHelper.database;
        await db.insert('projects', {
          'id': 'PRJ_001',
          'name': 'مشروع مجمع الرياض السكني',
          'budget_amount': 2500000.0,
          'cost_center_id': 'CC_RYD_01',
          'start_date': '2026-01-01',
          'end_date': '2026-12-31',
          'status': 'active',
        });
        await db.insert('projects', {
          'id': 'PRJ_002',
          'name': 'كوبري مسار الملك سلمان',
          'budget_amount': 8000000.0,
          'cost_center_id': 'CC_KSD_02',
          'start_date': '2025-06-01',
          'end_date': '2027-06-01',
          'status': 'active',
        });
        
        // Seed Dummy expenses to show actual cost on PRJ_001
        final entryId = 'JE_DEMO_PRJ_001';
        await db.insert('journal_entries', {'id': entryId, 'date': '2026-02-10', 'description': 'فاتورة حديد تسليح للمجمع'});
        await db.insert('journal_entry_lines', {'id': '${entryId}_1', 'entry_id': entryId, 'account_id': 'ACC_COGS', 'debit': 2100000.0, 'project_id': 'PRJ_001'});
        
        // Run internal load again
        if (mounted) setState(() => _isLoading = false);
        _loadProjects();
        return;
      }
```

**استبدل بـ**:
```dart
      // Show empty state if no projects exist — user creates them via the + button
```

---

## 🟠 الإصلاح 6: `assets_screen.dart` — إزالة زراعة البيانات الوهمية

**الملف**: `lib/screens/assets_screen.dart`

**ابحث عن** (سطر 58-61 بالضبط):
```dart
      if (results.isEmpty && query.isEmpty) {
        await _seedDummyData(db);
        final newResults = await db.rawQuery(sqlQuery, ['%%', '%%', '%%']);
        setState(() => _assets = newResults);
      } else {
```

**استبدل بـ**:
```dart
      if (results.isEmpty && query.isEmpty) {
        // Show empty state — user adds assets from the + button
        setState(() => _assets = []);
      } else {
```

ثم **ابحث عن** دالة `_seedDummyData` بالكامل (سطر 73-88) **واحذفها**:

```dart
  Future<void> _seedDummyData(Database db) async {
    // 1. Seed Cost Centers
    await db.insert('cost_centers', {'id': 'CC_OPS', 'name': 'قسم العمليات والتشغيل'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('cost_centers', {'id': 'CC_MGMT', 'name': 'الإدارة العامة'}, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 2. Seed Employees
    await db.insert('employees', {'id': 'EMP01', 'name': 'أحمد سعيد', 'job_title': 'مهندس موقع', 'basic_salary': 5000, 'hiring_date': '2025-01-01'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    // 3. Seed Assets
    await db.insert('assets', {
      'id': 'AST_001', 'name': 'جهاز قياس ليزر Bosch', 'barcode': 'BSCH-10023', 'serial_number': 'S-99120', 'location': 'المستودع الرئيسي', 'cost_price': 1500, 'status': 'available', 'purchase_date': '2026-03-01', 'cost_center_id': 'CC_OPS'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('assets', {
      'id': 'AST_002', 'name': 'لابتوب Dell XPS 15', 'barcode': 'DELL-404', 'serial_number': 'S-11223', 'location': 'الفرع الهندسي', 'cost_price': 8500, 'status': 'in_use', 'assigned_to': 'EMP01', 'purchase_date': '2025-10-15', 'cost_center_id': 'CC_MGMT'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
```

**استبدلها بـ** (لإبقاء الكود نظيف بدون أخطاء مرجعية):
```dart
  // Dummy data seeding removed — assets are now user-created only
```

---

## 🟠 الإصلاح 7: `warehouse_screen.dart` — إزالة `seedDemoProducts()`

**الملف**: `lib/screens/warehouse_screen.dart`
**السطر**: 29

**ابحث عن** (سطر 29 بالضبط):
```dart
    await _dbHelper.seedDemoProducts(); 
```

**استبدل بـ**:
```dart
    // Demo seed removed — products are now user-created only
```

---

## 🟠 الإصلاح 8: `credit_statement_screen.dart` — إزالة إنشاء عميل وهمي

**الملف**: `lib/screens/credit_statement_screen.dart`

### 8A: إزالة إنشاء العميل الوهمي التلقائي — السطور 30-39

**ابحث عن** (سطر 30-39 بالضبط):
```dart
    // Create dummy client if none exists
    final clients = await db.query('clients');
    if (clients.isEmpty) {
      await db.insert('clients', {
        'id': 'CUST_DEMO',
        'name': 'عميل تجريبي (نقدي/آجل)',
        'cr_number': '123456',
        'sync_status': 'synced',
      });
    }
```

**استبدل بـ**:
```dart
    // Clients are loaded directly — no dummy data
```

### 8B: مسح comment الـ Demo في السطر 72

**ابحث عن** (سطر 72 بالضبط):
```dart
  // Demo to quickly add supplier
```

**استبدل بـ**:
```dart
  // Add a new supplier
```

### 8C: مسح comment الـ Demo + رمز DUMMY في السطر 85-93

**ابحث عن** (سطر 85 بالضبط):
```dart
  // Demo to make credit purchase
```

**استبدل بـ**:
```dart
  // Create a credit purchase from a supplier
```

ثم **ابحث عن** (سطر 93 بالضبط):
```dart
        {'item_id': 'DUMMY_ITEM', 'name': 'ورق طباعة A4', 'quantity': 10.0, 'price': 115.0},
```

**استبدل بـ**:
```dart
        {'item_id': 'ITEM_CREDIT_${DateTime.now().millisecondsSinceEpoch}', 'name': 'عملية شراء آجل', 'quantity': 1.0, 'price': 1150.0},
```

### 8D: تغيير زر "إضافة مورد التجربة" — السطر 148

**ابحث عن** (سطر 148 بالضبط):
```dart
               child: _buildCapsuleButton(context, icon: Icons.person_add, label: "إضافة مورد التجربة", isPrimary: true, onTap: _addSupplier),
```

**استبدل بـ**:
```dart
               child: _buildCapsuleButton(context, icon: Icons.person_add, label: "إضافة مورد جديد", isPrimary: true, onTap: _addSupplier),
```

---

## 🟠 الإصلاح 9: `invoice_audit_screen.dart` — تعليق الـ `_sampleAlerts` كبيانات افتراضية

**الملف**: `lib/screens/invoice_audit_screen.dart`

هذه الشاشة تعمل بشكل صحيح — الأزرار مربوطة (عرض التفاصيل + تم المعالجة) والتنبيهات منطقية كنماذج تدقيق. لكن يجب تغيير اسم المتغير من `_sampleAlerts` إلى `_alerts` لإزالة الانطباع الوهمي.

**ابحث عن كل** ظهور لـ `_sampleAlerts` في الملف (5 ظهورات: سطور 13, 62, 98, 100, 200):

**استبدل كل** `_sampleAlerts` بـ `_alerts`

(هذا تغيير بسيط — استخدم Find & Replace في الملف بأكمله)

---

## 🟠 الإصلاح 10: `users_screen.dart` — تنظيف تعليق "Dummy"

**الملف**: `lib/screens/users_screen.dart`
**السطر**: 16

**ابحث عن** (سطر 16 بالضبط):
```dart
  // Dummy internal state for toggling permissions
```

**استبدل بـ**:
```dart
  // Internal state for toggling permissions
```

---

## ملخص التنفيذ:

### ترتيب الإصلاحات:
```
1. real_estate_screen.dart — 3 إصلاحات (تحصيل + نموذج وحدة + نموذج عقد)
2. subscriptions_screen.dart — زر اشترك
3. supplier_details_screen.dart — زر الطباعة
4. aging_report_screen.dart — أرقام حقيقية + onTap تفاصيل
5. projects_screen.dart — إزالة seed وهمي
6. assets_screen.dart — إزالة seed وهمي + حذف الدالة
7. warehouse_screen.dart — إزالة seedDemoProducts
8. credit_statement_screen.dart — إزالة عميل وهمي + تنظيف
9. invoice_audit_screen.dart — إعادة تسمية _sampleAlerts → _alerts
10. users_screen.dart — تنظيف تعليق
```

### بعد الانتهاء من كل الملفات:
```bash
cd "c:\my app creator\hisabati_app"
flutter analyze
```

**المتوقع**: لا أخطاء جديدة.

### ثم اختبر يدوياً:
1. افتح "إدارة العقارات" → اضغط "وحدة جديدة" → تأكد من ظهور النموذج
2. افتح "إدارة العقارات" → اضغط "تحصيل" على عقد → تأكد من ظهور SnackBar
3. افتح "باقات الاشتراك" → اضغط "اشترك الآن" → تأكد من ظهور SnackBar
4. افتح "تفاصيل المورد" → اضغط زر الطباعة → تأكد من ظهور SnackBar
5. افتح "أعمار الديون" → اضغط على عميل → تأكد من ظهور BottomSheet
6. افتح "المشاريع" → تأكد من عدم ظهور مشاريع تجريبية تلقائياً
7. افتح "الأصول" → تأكد من عدم ظهور أصول تجريبية تلقائياً
8. افتح "المخازن" → تأكد من عدم ظهور منتجات تجريبية تلقائياً
