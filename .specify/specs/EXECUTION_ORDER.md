# 🗺️ ترتيب التنفيذ الرسمي — نظام حساباتي ERP

## آخر تحديث: 2026-04-12

## ⚠️ تعليمات للمنفذ (أي ذكاء اصطناعي يقرأ هذا)

### قواعد عامة يجب اتباعها دائماً:
1. **اقرأ `file-map.md` أولاً** لفهم هيكل المشروع والملفات الموجودة
2. **لا تنشئ ملفات مكررة** — تحقق دائماً من وجود الملف قبل إنشائه
3. **استخدم نفس نمط التصميم الموجود**: Apple-style Glassmorphism مع Orange `#FF6B00` كلون أساسي
4. **كل شاشة تستخدم** `context.isDark`, `context.bgSurface`, `context.textColor` من `lib/theme/app_theme_extension.dart`
5. **كل عملية CRUD في قاعدة البيانات** يجب أن تضع:
   - `'id': Uuid().v4()` (من `package:uuid/uuid.dart`)
   - `'updated_at': DateTime.now().toIso8601String()`
   - `'sync_status': 0`
   - `'device_id': await DatabaseHelper().getDeviceFingerprint()`
6. **عند إضافة جدول جديد** في `database_helper.dart`:
   - زِد `_databaseVersion` بواحد
   - أضف `CREATE TABLE IF NOT EXISTS` في `_onUpgrade`
   - أضف نفس الجدول في `supabase_schema.sql`
7. **عند إنشاء شاشة جديدة**: أضف import و navigation في `main.dart`
8. **RTL Support**: كل النصوص تدعم العربية. استخدم `tr('key')` من `easy_localization`
9. **لا تحذف imports أو كود موجود** إلا إذا طُلب منك صراحة
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

### المرحلة 11: القوالب المحاسبية حسب القطاع ← `phase-11-industry-templates.md`
**الهدف**: توسيع القطاعات من 7 إلى 27 مع شجرة حسابات مخصصة لكل قطاع
**الملفات المتأثرة**:
- `lib/services/industry_provider.dart` — توسيع enum + modules
- `lib/core/accounting/coa_template.dart` — إنشاء 27 شجرة حسابات
- `lib/screens/onboarding_screen.dart` — عرض 27 قطاع
- `assets/translations/ar.json` + `en.json` — أسماء القطاعات

---

### المرحلة 12: إكمال المحاسبة ← `phase-12-accounting-complete.md`
**الهدف**: إضافة الوظائف المحاسبية الناقصة لمستوى QuickBooks
**الملفات الجديدة**:
- `lib/screens/credit_note_screen.dart`
- `lib/screens/debit_note_screen.dart`
- `lib/screens/purchase_order_screen.dart`
- `lib/screens/recurring_invoices_screen.dart`
- `lib/screens/aging_report_screen.dart`
- `lib/screens/fiscal_year_screen.dart`
**الملفات المعدَّلة**:
- `lib/core/accounting/accounting_engine.dart` — إضافة دوال جديدة
- `lib/services/database_helper.dart` — v55 (جدول purchase_orders)
- `lib/screens/pos_screen.dart` — ربط بالمخزون
- `lib/screens/invoice_entry_screen.dart` — ربط بالمخزون
- `main.dart` — إضافة الشاشات الجديدة

---

### المرحلة 13: إكمال الموارد البشرية ← `phase-13-hr-complete.md`
**الهدف**: تفعيل التابات الفارغة وإضافة نظام رواتب حسب الدولة
**الملفات المعدَّلة**:
- ملفات في `lib/screens/hr/` — تابات المستندات والعهد
- `lib/services/payroll_service.dart` — قواعد الدول

---

### المرحلة 14: الأمان والصلاحيات ← `phase-14-security-rbac.md`
**الهدف**: RBAC + سجل تدقيق + نسخ احتياطي
**الملفات الجديدة**:
- `lib/services/permission_service.dart`
- `lib/services/audit_service.dart`
- `lib/services/backup_service.dart`
- `.env.example`
**الملفات المعدَّلة**:
- `.gitignore` — إضافة `.env`
- `lib/services/supabase_admin_service.dart` — إصلاح مولد كلمة المرور
- `lib/services/database_helper.dart` — v55+ (indexes)
- `main.dart` — إخفاء وحدات حسب الصلاحيات

---

### المرحلة 15: إصلاح الزجاج ← `phase-15-glass-blur-fix.md`
**الهدف**: بلور غامق في الليلي وفاتح في الساطع
**الملفات المعدَّلة**:
- `lib/widgets/glass_container.dart` — تحديث الألوان
- أي شاشة تستخدم `BackdropFilter` يدوياً

---

### المرحلة 16: AI ذكي ← `phase-16-ai-complete.md`
**الهدف**: ربط AI ببيانات حقيقية + Function Calling كامل
**الملفات المعدَّلة**:
- `lib/services/ai_service.dart`
- `lib/services/ai_chat_controller.dart`

---

### المرحلة 17: الضرائب العالمية ← `phase-17-global-tax.md`
**الهدف**: دعم 20+ دولة مع أنواع ضرائب مختلفة
**الملفات المعدَّلة**:
- `lib/services/tax_engine.dart`
- `lib/screens/taxes_screen.dart`

---

### المرحلة 18: التثبيت النهائي ← `phase-18-installer-final.md`
**الهدف**: MSIX + About + Splash
**الملفات المعدَّلة**:
- `pubspec.yaml` — إضافة msix
- `lib/screens/settings_screen.dart` — شاشة "حول"

---

## المراحل القديمة (1-10) — مرجع فقط
الملفات `phase-1` إلى `phase-10` هي مراحل **سابقة** تم تنفيذ معظمها. بعض البنود لم تُنفذ وتم نقلها إلى المراحل الجديدة (11-18).

| المرحلة القديمة | الحالة | ما نُقل |
|----------------|--------|---------|
| Phase 1: Critical Fixes | 90% تم | مولد كلمة المرور → Phase 14 |
| Phase 2: Desktop | ✅ تم | |
| Phase 3: Database | ✅ تم | |
| Phase 4: Accounting | 60% تم | Credit/Debit Notes + PO + Recurring + Aging + FY Close → Phase 12 |
| Phase 5: HR | 60% تم | Documents Tab + Custody Tab + Contracts + Country Payroll → Phase 13 |
| Phase 6: Multi-Country | 40% تم | Hardcoded texts + Translations → يُراجع لاحقاً |
| Phase 7: Integration | 20% تم | POS→Inventory + Invoices→COGS → Phase 12 |
| Phase 8: AI | 40% تم | Function Calling + Dynamic Prompt → Phase 16 |
| Phase 9: Reports | 70% تم | Aging PDF + Statement PDF → Phase 12 |
| Phase 10: Security | 10% تم | RBAC + Audit + Backup → Phase 14 |
