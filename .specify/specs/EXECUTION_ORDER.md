# ترتيب التنفيذ الرسمي — نظام حساباتي ERP

## آخر تحديث: 2026-04-16

## تعليمات للمنفذ (أي ذكاء اصطناعي يقرأ هذا)

### قواعد عامة يجب اتباعها دائما:
1. **اقرأ `file-map.md` أولا** لفهم هيكل المشروع والملفات الموجودة
2. **لا تنشئ ملفات مكررة** — تحقق دائما من وجود الملف قبل إنشائه
3. **استخدم نفس نمط التصميم الموجود**: Apple-style Glassmorphism مع Orange `#FF6B00` كلون أساسي
4. **كل شاشة تستخدم** `context.isDark`, `context.bgSurface`, `context.textColor` من `lib/theme/app_theme_extension.dart`
5. **كل عملية CRUD في قاعدة البيانات** يجب أن تضع:
   - `'id': Uuid().v4()` (من `package:uuid/uuid.dart`)
   - `'updated_at': DateTime.now().toIso8601String()`
   - `'sync_status': 0`
   - `'device_id': await DatabaseHelper().getDeviceFingerprint()`
6. **عند إضافة جدول جديد** في `database_helper.dart`:
   - زد `_databaseVersion` بواحد
   - أضف `CREATE TABLE IF NOT EXISTS` في `_onUpgrade`
   - أضف نفس الجدول في `supabase_schema.sql`
7. **عند إنشاء شاشة جديدة**: أضف import و navigation في `main.dart`
8. **RTL Support**: كل النصوص تدعم العربية. استخدم `tr('key')` من `easy_localization`
9. **لا تحذف imports أو كود موجود** إلا إذا طلب منك صراحة
10. **لا تغير الألوان الأساسية** (`primaryOrange`, `sunsetStart`, `sunsetEnd`, `accentGold`)

### هيكل metadata لكل جدول SQLite:
```dart
const String metadata = '''
  sync_status INTEGER DEFAULT 0,
  updated_at TEXT,
  device_id TEXT,
  is_deleted INTEGER DEFAULT 0
''';
```

---

## الترتيب الرسمي للتنفيذ

## [أعلى أولوية] المراحل 28-31: تدقيق الإنتاج الشامل

> هذه المراحل نتجت عن تدقيق شامل سطر بسطر في 2026-04-16
> يجب تنفيذها **بالترتيب** قبل أي مرحلة أخرى

---

### المرحلة 28: تدقيق الإنتاج — الإصلاحات الحرجة (أعلى أولوية) <- `phase-28-production-audit-fix.md`
**الهدف**: إصلاح 5 مشاكل حرجة تمنع التطبيق من العمل بشكل صحيح
**يجب تنفيذها قبل أي شيء آخر**
**يشمل**:
- إنشاء دالة `_onCreate` المفقودة (التطبيق لن يعمل لأي تثبيت جديد بدونها)
- إعادة تسمية `getDeviceFingerdebugPrint()` الى `getDeviceFingerprint()` (31 موقع)
- إصلاح أعمدة `check_in_time`/`check_out_time` في attendance_logs (migration v60)
- توحيد `saveSystemUser` مع الحقول الكاملة
- تنفيذ `_viewSlipDetails` الفارغة في HR
**الملفات المتأثرة**:
- `lib/services/database_helper.dart` — إضافة `_onCreate` + migration v60 + إصلاح method name
- `lib/services/sync_service.dart` — إصلاح method name
- `lib/services/custody_service.dart` — إصلاح method name
- `lib/services/cheque_service.dart` — إصلاح method name
- `lib/services/audit_service.dart` — إصلاح method name
- `lib/screens/hr/hr_root_screen.dart` — تنفيذ `_viewSlipDetails`

---

### المرحلة 29: تدقيق الإنتاج — HR وربط التنقل <- `phase-29-production-audit-hr-nav.md`
**الهدف**: ربط الوظائف المفقودة في HR وإصلاح التنقل
**يعتمد على**: المرحلة 28
**يشمل**:
- تنفيذ زر إضافة طلب إجازة مع dialog كامل
- إضافة جدول `employee_contracts` في migration v60
- التحقق من navigation indices في main.dart
- ربط عداد المستندات المنتهية الصلاحية ببيانات حقيقية
**الملفات المتأثرة**:
- `lib/screens/hr/hr_root_screen.dart` — leave dialog + expiring docs count
- `lib/services/database_helper.dart` — employee_contracts table

---

### المرحلة 30: تدقيق الإنتاج — تنظيف الكود <- `phase-30-production-audit-cleanup.md`
**الهدف**: إزالة التحذيرات وتحسين جودة الكود
**يعتمد على**: المرحلة 28, 29
**يشمل**:
- إزالة imports غير مستخدمة (4 ملفات)
- إزالة imports `dart:ui` غير ضرورية (4 ملفات)
- استبدال deprecated `background`/`onBackground` بـ `surface`/`onSurface`
- إصلاح `Table.fromTextArray` الى `TableHelper.fromTextArray`
- تحميل الفروع الحقيقية في TopBar
**الملفات المتأثرة**:
- `lib/screens/debit_note_screen.dart`
- `lib/screens/financial_reports_screen.dart`
- `lib/screens/hr/employee_form.dart`
- `lib/screens/feasibility_study_screen.dart`
- `lib/screens/fiscal_year_screen.dart`
- `lib/screens/expiry_dashboard_screen.dart`
- `lib/screens/hr/hr_root_screen.dart`
- `lib/main.dart` — TopBar branches

---

### المرحلة 31: اختبار شامل <- `phase-31-comprehensive-test.md`
**الهدف**: إنشاء ملف اختبار يتحقق من كل الإصلاحات (16 اختبار)
**يعتمد على**: المرحلة 28, 29, 30
**الملفات الجديدة**:
- `test/comprehensive_audit_test.dart` — 16 اختبار في 5 مجموعات
**التشغيل**: `flutter test test/comprehensive_audit_test.dart`

---

## المراحل المعلقة (تُنفذ بعد 28-31)

### المرحلة 20: تحديث الموقع الكامل <- `phase-20-website-overhaul.md`
**الهدف**: ترقية الموقع (Next.js) لمستوى QuickBooks Global
**يشمل**: توسيع الترجمات + إضافة قائمة موبايل + تحديث ترتيب الأقسام
**الملفات المتأثرة**:
- `website/src/context/LanguageContext.tsx`
- `website/src/components/Navbar.tsx`
- `website/src/app/page.tsx`

---

### المرحلة 21: مكونات الموقع الجزء 1 <- `phase-21-website-components.md`
**الهدف**: تحديث Hero + HowItWorks + Features (28 ميزة) + IndustrySolutions (جديد)
**الملفات**:
- `website/src/components/Hero.tsx`
- `website/src/components/HowItWorks.tsx`
- `website/src/components/Features.tsx`
- `website/src/components/IndustrySolutions.tsx` — ملف جديد

---

### المرحلة 22: مكونات الموقع الجزء 2 <- `phase-22-website-components-2.md`
**الهدف**: Pricing + Comparison + FAQ + Testimonials + DemoVideo + Contact + Footer

---

### المرحلة 23: تطبيق Flutter — الرقابة وتدقيق الفواتير <- `phase-23-flutter-monitoring-audit.md`
**الحالة**: تم تنفيذها
**الملفات الجديدة**:
- `lib/screens/monitoring_control_screen.dart`
- `lib/screens/invoice_audit_screen.dart`

---

### المرحلة 24: تطبيق Flutter — التدفقات النقدية والقوائم المالية <- `phase-24-flutter-cashflow-statements-jv.md`
**الحالة**: تم تنفيذها
**الملفات الجديدة**:
- `lib/screens/cash_flow_statement_screen.dart`
- `lib/screens/quick_statements_screen.dart`
- `lib/screens/joint_ventures_screen.dart`

---

### المرحلة 25: تطبيق Flutter — إصلاح HR وإدارة المصروفات <- `phase-25-flutter-hr-fix-expenses.md`
**الحالة**: تم تنفيذها جزئيا
**الملفات الجديدة**:
- `lib/screens/expense_management_screen.dart`
- `lib/screens/cost_accounting_screen.dart`

---

### المرحلة 26: إصلاح شامل <- `phase-26-comprehensive-fix.md`
**الحالة**: تم تنفيذها

---

### المرحلة 27: تنظيف شامل <- `phase-27-comprehensive-cleanup.md`
**الحالة**: تم تنفيذها

---

### المرحلة 11: القوالب المحاسبية حسب القطاع <- `phase-11-industry-templates.md`
**الهدف**: توسيع القطاعات من 7 إلى 27 مع شجرة حسابات مخصصة لكل قطاع

---

### المرحلة 12: إكمال المحاسبة <- `phase-12-accounting-complete.md`
**الهدف**: إضافة الوظائف المحاسبية الناقصة لمستوى QuickBooks

---

### المرحلة 13: إكمال الموارد البشرية <- `phase-13-hr-complete.md`
**الهدف**: تفعيل التابات الفارغة وإضافة نظام رواتب حسب الدولة

---

### المرحلة 14: الأمان والصلاحيات <- `phase-14-security-rbac.md`
**الهدف**: RBAC + سجل تدقيق + نسخ احتياطي

---

### المرحلة 15: إصلاح الزجاج <- `phase-15-glass-blur-fix.md`
**الحالة**: تم تنفيذها

---

### المرحلة 16: AI ذكي <- `phase-16-ai-complete.md`
**الهدف**: ربط AI ببيانات حقيقية + Function Calling كامل

---

### المرحلة 17: الضرائب العالمية <- `phase-17-global-tax.md`
**الهدف**: دعم 20+ دولة مع أنواع ضرائب مختلفة

---

### المرحلة 18: التثبيت النهائي <- `phase-18-installer-final.md`
**الهدف**: MSIX + About + Splash

---

## المراحل القديمة (1-10) — مرجع فقط

| المرحلة القديمة | الحالة | ما نقل |
|----------------|--------|--------|
| Phase 1: Critical Fixes | 90% تم | مولد كلمة المرور Phase 14 |
| Phase 2: Desktop | تم | |
| Phase 3: Database | تم | |
| Phase 4: Accounting | 60% تم | Credit/Debit Notes + PO + Recurring + Aging + FY Close Phase 12 |
| Phase 5: HR | 60% تم | Documents Tab + Custody Tab + Contracts + Country Payroll Phase 13 |
| Phase 6: Multi-Country | 40% تم | Hardcoded texts + Translations يراجع لاحقا |
| Phase 7: Integration | 20% تم | POS Inventory + Invoices COGS Phase 12 |
| Phase 8: AI | 40% تم | Function Calling + Dynamic Prompt Phase 16 |
| Phase 9: Reports | 70% تم | Aging PDF + Statement PDF Phase 12 |
| Phase 10: Security | 10% تم | RBAC + Audit + Backup Phase 14 |
