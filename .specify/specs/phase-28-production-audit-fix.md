# Phase 28: إصلاح تدقيق الإنتاج — المرحلة 1 (حرجة)

## ⚠️ قواعد صارمة للمنفذ:
1. **نفّذ الملفات بالترتيب المحدد بالضبط** — لا تقفز
2. **انسخ الكود حرفياً** — لا تعدل ولا تضيف من عندك
3. **لا تحذف أي import موجود** — فقط أضف الجديد
4. **بعد كل ملف** شغّل `flutter analyze` وتأكد من 0 أخطاء
5. **إذا ظهر خطأ** أخبر القائد بالنص الكامل ولا تحاول إصلاحه
6. **هذه المرحلة تعالج 5 مشاكل حرجة فقط** — كل المشاكل الأخرى في مراحل لاحقة

---

## 🔴 الإصلاح 1: إنشاء دالة `_onCreate` المفقودة (الأخطر)

**الملف**: `lib/services/database_helper.dart`
**السبب**: الدالة `_onCreate` مُستدعاة في سطر 45 و 67 (`onCreate: _onCreate`) لكنها **غير موجودة** في الملف. هذا يعني أن أي تثبيت جديد (fresh install) **لن يُنشئ أي جدول**.
**التأثير**: كارثي — التطبيق لن يعمل لأي مستخدم جديد.

### التنفيذ:

**ابحث عن** (سطر 95-96):
```dart
  /// Returns a combined string of (Device Name - Serial Number) for v34 Sync Engine
  Future<String> getDeviceFingerdebugPrint() async {
```

**أضف قبلها مباشرة** (بعد إغلاق `}` الخاصة بـ `_initDatabase` في سطر 70):
```dart

  /// Fresh install: create all tables by running all migrations from scratch
  Future<void> _onCreate(Database db, int version) async {
    await _onUpgrade(db, 0, version);
  }

```

**التحقق**: ابحث عن `onCreate: _onCreate` — يجب أن يظهر في سطرين (45 و 67). الدالة الجديدة ستجعلهما يعملان.

---

## 🔴 الإصلاح 2: إعادة تسمية `getDeviceFingerdebugPrint` → `getDeviceFingerprint`

**السبب**: عملية بحث واستبدال سابقة حوّلت كلمة `print` إلى `debugPrint` داخل اسم الدالة بالخطأ. الاسم الأصلي المطلوب هو `getDeviceFingerprint`.
**التأثير**: الدالة تعمل حالياً لأن كل المواقع تستخدم نفس الاسم المشوّه، لكن أي كود جديد يتبع `EXECUTION_ORDER.md` سيستدعي `getDeviceFingerprint()` وسيفشل.

### التنفيذ:

استخدم **Find and Replace All** في المشروع كامل:

**ابحث عن**:
```
getDeviceFingerdebugPrint
```

**استبدل بـ**:
```
getDeviceFingerprint
```

**الملفات المتأثرة** (31 موقع):
| الملف | عدد المواقع |
|-------|------------|
| `lib/services/database_helper.dart` | 25 |
| `lib/services/sync_service.dart` | 1 |
| `lib/services/custody_service.dart` | 1 |
| `lib/services/cheque_service.dart` | 3 |
| `lib/services/audit_service.dart` | 1 |

**التحقق**: بعد الاستبدال، ابحث عن `getDeviceFingerdebugPrint` — يجب أن يكون **0 نتائج**.

---

## 🔴 الإصلاح 3: إصلاح أعمدة الحضور (attendance_logs)

**السبب**: كود HR يكتب ويقرأ أعمدة `check_in_time` و `check_out_time`، لكن جدول `attendance_logs` في قاعدة البيانات يحتوي فقط على `check_in` و `check_out`. البيانات تُكتب في أعمدة غير موجودة فتُتجاهل صامتةً.
**التأثير**: كل عمليات تسجيل الحضور تفشل — لا حضور ولا انصراف يُحفظ.

### التنفيذ (خطوة أ — إضافة migration v60):

**الملف**: `lib/services/database_helper.dart`

**ابحث عن** رقم الإصدار (سطر 14 تقريباً):
```dart
  static const int _databaseVersion = 59;
```

**استبدل بـ**:
```dart
  static const int _databaseVersion = 60;
```

**ثم ابحث عن** آخر migration block (حوالي سطر 1800-1850 — ابحث عن `if (oldVersion < 59)`). بعد إغلاقه `}` أضف:

```dart

    if (oldVersion < 60) {
      // Fix attendance_logs column mismatch: code uses check_in_time/check_out_time
      // but the table only has check_in/check_out. Add the missing columns.
      try { await db.execute('ALTER TABLE attendance_logs ADD COLUMN check_in_time TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE attendance_logs ADD COLUMN check_out_time TEXT'); } catch (_) {}
      
      // Copy existing data from check_in → check_in_time (for existing users)
      try { await db.execute("UPDATE attendance_logs SET check_in_time = check_in WHERE check_in_time IS NULL AND check_in IS NOT NULL"); } catch (_) {}
      try { await db.execute("UPDATE attendance_logs SET check_out_time = check_out WHERE check_out_time IS NULL AND check_out IS NOT NULL"); } catch (_) {}
    }
```

**التحقق**: شغّل `flutter analyze` — يجب 0 أخطاء. ثم ابحث عن `check_in_time` في `hr_root_screen.dart` و `attendance_tab.dart` — يجب أن يتطابق الآن مع الأعمدة الجديدة.

---

## 🔴 الإصلاح 4: توحيد دوال System Users (إزالة التكرار)

**السبب**: يوجد دالتان مختلفتان لنفس الغرض:
- `addSystemUser()` في سطر 4981 — تضيف `id`, `created_at`, `is_active`
- `saveSystemUser()` في سطر 6240 — تضيف `updated_at` فقط

الشاشة `users_screen.dart` تستدعي `saveSystemUser()` بينما الأماكن الأخرى تستدعي `addSystemUser()`.

### التنفيذ:

**الملف**: `lib/services/database_helper.dart`

**ابحث عن** (سطر 6240):
```dart
  Future<void> saveSystemUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('system_users', {
      ...user,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
```

**استبدل بـ**:
```dart
  Future<void> saveSystemUser(Map<String, dynamic> user) async {
    final db = await database;
    user['id'] ??= 'USR_${DateTime.now().millisecondsSinceEpoch}';
    user['created_at'] ??= DateTime.now().toIso8601String();
    user['updated_at'] = DateTime.now().toIso8601String();
    user['is_active'] ??= 1;
    user['is_deleted'] ??= 0;
    user['sync_status'] ??= 0;
    await db.insert('system_users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }
```

**التحقق**: `flutter analyze` — يجب 0 أخطاء.

---

## 🔴 الإصلاح 5: تنفيذ `_viewSlipDetails` الفارغة

**السبب**: النقر على قسيمة راتب في تاب الرواتب لا يفعل شيئاً.
**الملف**: `lib/screens/hr/hr_root_screen.dart`

**ابحث عن** (سطر 282-284):
```dart
  void _viewSlipDetails(Map<String, dynamic> slip) {
    // Show summary or dialog (Reuse helper from hr_screen or moved)
  }
```

**استبدل بـ**:
```dart
  void _viewSlipDetails(Map<String, dynamic> slip) {
    final empName = _employees.firstWhere(
      (e) => e['id'] == slip['employee_id'],
      orElse: () => {'name': 'موظف'},
    )['name'] ?? 'موظف';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('قسيمة راتب - $empName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _slipRow('الشهر', slip['month']?.toString() ?? '---'),
              _slipRow('الراتب الأساسي', '${(slip['basic_salary'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow('بدل السكن', '${(slip['housing_allowance'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow('بدل النقل', '${(slip['transport_allowance'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              const Divider(),
              _slipRow('خصم التأمينات', '${(slip['insurance_deduction'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow('خصم الغياب', '${(slip['absence_deduction'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              const Divider(),
              _slipRow('صافي الراتب', '${(slip['net_salary'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency', isBold: true),
              _slipRow('الحالة', slip['payment_status']?.toString() ?? 'draft'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _slipRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 13,
            color: isBold ? primaryOrange : null,
          )),
        ],
      ),
    );
  }
```

---

## ✅ التحقق النهائي بعد تنفيذ كل الإصلاحات

شغّل هذه الأوامر بالترتيب:

```powershell
flutter analyze
```

**النتيجة المتوقعة**: 0 أخطاء (errors). التحذيرات (warnings/info) مقبولة وستُعالج في المرحلة التالية.

```powershell
flutter build windows
```

**النتيجة المتوقعة**: بناء ناجح بدون أخطاء.
