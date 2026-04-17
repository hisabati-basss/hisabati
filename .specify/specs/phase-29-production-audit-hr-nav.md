# Phase 29: إصلاح تدقيق الإنتاج — المرحلة 2 (HR وربط التنقل)

## ⚠️ قواعد صارمة للمنفذ:
1. **نفّذ Phase 28 أولاً** — هذه المرحلة تعتمد عليها
2. **انسخ الكود حرفياً** — لا تعدل ولا تضيف من عندك
3. **لا تحذف أي import موجود**
4. **بعد كل إصلاح** شغّل `flutter analyze` وتأكد من 0 أخطاء
5. **إذا ظهر خطأ** أخبر القائد بالنص الكامل ولا تحاول إصلاحه

---

## 🟠 الإصلاح 1: تنفيذ زر إضافة طلب إجازة (Leaves Tab)

**الملف**: `lib/screens/hr/hr_root_screen.dart`
**السبب**: زر "إضافة طلب إجازة" لا يفعل شيئاً (`onAddRequest: () {}`)

**ابحث عن** (سطر 331-334):
```dart
                        LeavesTab(
                          leaveRequests: _leaveRequests,
                          onAddRequest: () {}, // To be implemented
                          onUpdateStatus: (id, status) async {
```

**استبدل بـ**:
```dart
                        LeavesTab(
                          leaveRequests: _leaveRequests,
                          onAddRequest: () => _showAddLeaveDialog(),
                          onUpdateStatus: (id, status) async {
```

**ثم أضف هذه الدالة** قبل دالة `_viewSlipDetails` (قبل سطرها):

```dart
  void _showAddLeaveDialog() {
    String? selectedEmpId;
    String leaveType = 'ANNUAL';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('طلب إجازة جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'الموظف'),
                  items: _employees.map((e) => DropdownMenuItem(
                    value: e['id']?.toString(),
                    child: Text(e['name']?.toString() ?? ''),
                  )).toList(),
                  onChanged: (v) => selectedEmpId = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: leaveType,
                  decoration: const InputDecoration(labelText: 'نوع الإجازة'),
                  items: const [
                    DropdownMenuItem(value: 'ANNUAL', child: Text('سنوية')),
                    DropdownMenuItem(value: 'SICK', child: Text('مرضية')),
                    DropdownMenuItem(value: 'EMERGENCY', child: Text('طارئة')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('بدون راتب')),
                  ],
                  onChanged: (v) => leaveType = v ?? 'ANNUAL',
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('من'),
                  subtitle: Text(startDate.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  title: const Text('إلى'),
                  subtitle: Text(endDate.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'السبب'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى اختيار الموظف'), backgroundColor: Colors.red),
                  );
                  return;
                }
                await _payrollService.submitLeaveRequest({
                  'employee_id': selectedEmpId,
                  'type': leaveType,
                  'start_date': startDate.toIso8601String(),
                  'end_date': endDate.toIso8601String(),
                  'reason': reasonCtrl.text,
                });
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم تقديم طلب الإجازة'), backgroundColor: Colors.green),
                );
              },
              child: const Text('تقديم الطلب'),
            ),
          ],
        ),
      ),
    );
  }
```

**التحقق**: `flutter analyze` — 0 أخطاء.

---

## 🟠 الإصلاح 2: إضافة جدول `employee_contracts` في migration v60

**السبب**: ملف `contracts_tab.dart` يقرأ من جدول `employee_contracts` الذي **غير موجود** في أي migration. أي محاولة لفتح هذا التاب ستفشل.

**الملف**: `lib/services/database_helper.dart`

**ابحث عن** migration v60 التي أضفتها في Phase 28:
```dart
    if (oldVersion < 60) {
```

**أضف داخلها** (قبل `}` الإغلاق):
```dart

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
```

---

## 🟠 الإصلاح 3: إصلاح `_buildCurrentScreen` — إضافة الشاشات المفقودة

**السبب**: بعض الـ navigation indices تذهب لشاشات خاطئة أو غير موجودة.

**الملف**: `lib/main.dart`

### 3A: التحقق من Navigation Indices

افتح الملف `lib/main.dart` وابحث عن دالة `_buildCurrentScreen`. تحقق من أن هذه الـ cases موجودة وصحيحة:

| Index | الشاشة المفترضة | تحقق أنها موجودة |
|-------|-----------------|-------------------|
| 0 | AI Chat Screen | ✅ |
| 1 | CEO Dashboard | ✅ |
| 2 | Accounting/Taxes | ✅ |
| 3 | Inventory | ✅ |
| 4 | HR Screen | ✅ |
| 5 | Dashboard | ✅ |
| 6 | FeasibilityStudy | ✅ |
| 7 | Users Screen | ✅ |
| 8 | Affiliate Screen | ✅ verify |
| 12 | Settings Screen | ✅ |
| 13 | CreditStatement | ⚠️ hub says "subscriptions" |
| 47 | MonitoringControl | ✅ |
| 48 | InvoiceAudit | ✅ |
| 49 | CashFlowStatement | ✅ |
| 50 | QuickStatements | ✅ |
| 51 | JointVentures | ✅ |
| 52 | ExpenseManagement | ✅ |
| 53 | CostAccounting | ✅ |

**لا تغيّر أي case** — فقط تحقق وأبلغ القائد إذا وجدت اختلافاً عن الجدول أعلاه.

---

## 🟠 الإصلاح 4: إصلاح `_loadData` في HR لتحميل إضافي

**السبب**: دالة `_loadData()` في `hr_root_screen.dart` لا تحمّل بيانات العقود والمستندات — وهذا مطلوب لعدادات لوحة التحكم.

**الملف**: `lib/screens/hr/hr_root_screen.dart`

**ابحث عن** (داخل `_loadData()` — الجزء الذي يحسب `_expiringDocsCount`):
```dart
      _expiringDocsCount = 0;
```

**إذا كانت القيمة ثابتة على 0**، استبدلها بـ:
```dart
      // Count expiring documents (within 30 days)
      try {
        final docsDb = await _db.database;
        final threshold = DateTime.now().add(const Duration(days: 30)).toIso8601String();
        final expiringDocs = await docsDb.rawQuery(
          "SELECT COUNT(*) as cnt FROM documents WHERE expiry_date IS NOT NULL AND expiry_date <= ? AND is_deleted = 0",
          [threshold],
        );
        _expiringDocsCount = (expiringDocs.first['cnt'] as int?) ?? 0;
      } catch (_) {
        _expiringDocsCount = 0;
      }
```

**التحقق**: `flutter analyze` — 0 أخطاء. التطبيق سيعرض الآن عدد المستندات المنتهية الصلاحية الحقيقي.

---

## ✅ التحقق النهائي

```powershell
flutter analyze
```

**النتيجة المتوقعة**: 0 أخطاء.
