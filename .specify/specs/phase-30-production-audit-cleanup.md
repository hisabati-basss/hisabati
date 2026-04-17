# Phase 30: إصلاح تدقيق الإنتاج — المرحلة 3 (تنظيف الكود)

## ⚠️ قواعد صارمة للمنفذ:
1. **نفّذ Phase 28 و 29 أولاً** — هذه المرحلة تعتمد عليهما
2. **هذه المرحلة تنظيفية** — لا تضيف وظائف جديدة
3. **لا تحذف أي import مستخدم** — فقط احذف الـ unused imports المذكورة بالضبط
4. **بعد كل ملف** شغّل `flutter analyze`

---

## 🟡 الإصلاح 1: إزالة imports غير مستخدمة

### 1A: `lib/screens/debit_note_screen.dart`
**ابحث عن** (سطر 5):
```dart
import '../core/accounting/accounting_engine.dart';
```
**احذف هذا السطر بالكامل.**

### 1B: `lib/screens/financial_reports_screen.dart`
**ابحث عن** (سطر 10-11):
```dart
import '../services/pdf_service.dart';
import '../utils/tafqeet.dart';
```
**احذف هذين السطرين بالكامل.**

### 1C: `lib/screens/hr/employee_form.dart`
**ابحث عن** (سطر 9):
```dart
import '../../services/notification_service.dart';
```
**احذف هذا السطر بالكامل.**

### 1D: إزالة imports `dart:ui` غير الضرورية
في كل ملف من الملفات التالية، **ابحث عن** وأزل هذا السطر:
```dart
import 'dart:ui';
```

الملفات:
- `lib/screens/employee_chat_screen.dart` (سطر 1)
- `lib/screens/feasibility_study_screen.dart` (سطر 1)
- `lib/screens/financial_reports_screen.dart` (سطر 3)
- `lib/screens/fiscal_year_screen.dart` (سطر 3)

**ملاحظة مهمة**: لا تحذف `import 'dart:ui'` من أي ملف **غير** مذكور في القائمة أعلاه. بعض الملفات تحتاجه.

---

## 🟡 الإصلاح 2: استبدال deprecated `background`/`onBackground` ColorScheme

### 2A: `lib/screens/debit_note_screen.dart`

**ابحث عن كل** (Find All في الملف):
```dart
Theme.of(context).colorScheme.background
```
**استبدل بـ**:
```dart
Theme.of(context).colorScheme.surface
```

**ابحث عن كل**:
```dart
Theme.of(context).colorScheme.onBackground
```
**استبدل بـ**:
```dart
Theme.of(context).colorScheme.onSurface
```

### 2B: `lib/screens/fiscal_year_screen.dart`
نفس الاستبدال:
- `colorScheme.background` → `colorScheme.surface`

---

## 🟡 الإصلاح 3: إصلاح `Table.fromTextArray` deprecated

**الملف**: `lib/screens/feasibility_study_screen.dart`
**السطر**: 529

**ابحث عن**:
```dart
Table.fromTextArray(
```

**استبدل بـ**:
```dart
TableHelper.fromTextArray(
```

---

## 🟡 الإصلاح 4: إصلاح `curly_braces_in_flow_control_structures`

**الملف**: `lib/screens/expiry_dashboard_screen.dart`
**السطر**: 54

**ابحث عن** نمط مثل:
```dart
if (condition)
  singleStatement;
```

**استبدل بـ**:
```dart
if (condition) {
  singleStatement;
}
```

**ملاحظة**: هذا في سطر 54 تحديداً — ابحث عن `if` بدون `{`.

---

## 🟡 الإصلاح 5: إزالة unnecessary `intl` imports

### 5A: `lib/screens/hr/employee_form.dart`
**ابحث عن** (سطر 4):
```dart
import 'package:intl/intl.dart';
```
**احذف هذا السطر** — الموجود `easy_localization` يوفر نفس الوظائف.

### 5B: `lib/screens/hr/hr_root_screen.dart`
**ابحث عن** (سطر 3):
```dart
import 'package:intl/intl.dart';
```
**احذف هذا السطر.**

---

## 🟡 الإصلاح 6: إصلاح TopBar لتحميل الفروع الحقيقية

**الملف**: `lib/main.dart`

**ابحث عن** دالة `_loadBranches()` (سطر ~1783):
```dart
  Future<void> _loadBranches() async {
    try {
      final contextData = await DatabaseHelper().getCurrentCompanyContext();
      final companyName = contextData['company_name'] ?? tr('branches.main');
      if (mounted) {
        setState(() {
          selectedBranch = companyName.toString();
          branches = [companyName.toString()];
        });
      }
    } catch (_) {}
  }
```

**استبدل بـ**:
```dart
  Future<void> _loadBranches() async {
    try {
      final contextData = await DatabaseHelper().getCurrentCompanyContext();
      final companyName = contextData['company_name'] ?? tr('branches.main');
      
      // Load actual branches (cost_centers) from DB
      final costCenters = await DatabaseHelper().getCostCenters();
      final branchNames = costCenters.map((cc) => cc['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
      
      if (mounted) {
        setState(() {
          selectedBranch = companyName.toString();
          branches = [companyName.toString(), ...branchNames];
        });
      }
    } catch (_) {}
  }
```

---

## ✅ التحقق النهائي

```powershell
flutter analyze
```

**النتيجة المتوقعة**: عدد التحذيرات يقل بشكل ملحوظ. 0 أخطاء.

**ملاحظة**: بعض تحذيرات `withOpacity` deprecated ستبقى — هذه **كثيرة جداً** (50+) وسنعالجها في مرحلة منفصلة لأنها لا تؤثر على الوظائف.
