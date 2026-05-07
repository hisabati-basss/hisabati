# ترتيب التنفيذ الرسمي — نظام حساباتي ERP

## آخر تحديث: 2026-04-19

## تعليمات للمنفذ (أي ذكاء اصطناعي يقرأ هذا)

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

## [أعلى أولوية] المرحلة 32: التقوية النهائية للإنتاج ← `phase-32-final-production-hardening.md`

> **هذه المرحلة نتجت عن تدقيق شامل سطر بسطر في 2026-04-19**
> يجب تنفيذها **فوراً** قبل أي شيء آخر
> مقسمة إلى 6 مهام مرقمة — نفذها **بالترتيب** (1→2→3→4→5→6)

**الهدف**: إصلاح كل المشاكل الحرجة المتبقية قبل التسليم
**الزمن المقدر**: ~4 ساعات
**يشمل**:
1. **إصلاحات أمنية حرجة** (30 دق): إزالة admin backdoor + تشفير كلمات المرور + إصلاح setCurrentCompany
2. **إزالة بيانات وهمية وأزرار فارغة** (45 دق): أرقام ضريبية ثابتة + قائمة مستخدمين ثابتة + طابع زمني وهمي + onTap فارغ
3. **توحيد Deprecated APIs** (60 دق): 44 withOpacity → withValues في accounting + RawKeyboardListener في POS
4. **ربط HR Tabs المفقودة** (30 دق): إضافة 4 tabs (contracts, documents, performance, custody) لـ hr_root_screen
5. **ترجمة نصوص ثابتة متبقية** (60 دق): 6 ملفات + تحديث ar.json و en.json
6. **تحقق نهائي** (20 دق): flutter analyze + build + اختبار يدوي

**الملفات المتأثرة** (12 ملف):
- `lib/screens/login_screen.dart` — إزالة backdoor
- `lib/screens/users_screen.dart` — تشفير كلمات المرور
- `lib/screens/settings_screen.dart` — إصلاح حفظ الشركة
- `lib/screens/pos_screen.dart` — رقم ضريبي ديناميكي + إصلاح RawKeyboardListener
- `lib/screens/invoice_entry_screen.dart` — رقم ضريبي ديناميكي + ترجمة
- `lib/screens/employee_chat_screen.dart` — مستخدمين حقيقيين + onTap + ترجمة
- `lib/widgets/ai_chat_bubble.dart` — طابع زمني حقيقي
- `lib/screens/accounting_operations_screen.dart` — 44 withOpacity
- `lib/screens/hr/hr_root_screen.dart` — ربط 4 tabs + ترجمة
- `lib/screens/hr/payroll_tab.dart` — ترجمة
- `lib/screens/receipt_voucher_screen.dart` — ترجمة
- `assets/translations/ar.json` + `en.json` — مفاتيح جديدة
- `pubspec.yaml` — إضافة crypto package

---

## المراحل السابقة المنجزة

| المرحلة | الحالة | الوصف |
|---------|--------|-------|
| 28 | ✅ تم | تدقيق الإنتاج — إصلاحات حرجة |
| 29 | ✅ تم | تدقيق الإنتاج — HR وربط التنقل |
| 30 | ✅ تم | تدقيق الإنتاج — تنظيف الكود |
| 31 | ✅ تم | اختبار شامل |
| 23 | ✅ تم | الرقابة وتدقيق الفواتير |
| 24 | ✅ تم | التدفقات النقدية والقوائم المالية |
| 25 | ✅ جزئي | إصلاح HR وإدارة المصروفات |
| 26 | ✅ تم | إصلاح شامل |
| 27 | ✅ تم | تنظيف شامل |
| 15 | ✅ تم | إصلاح الزجاج |

---

## المراحل المعلقة (تُنفذ بعد 32)

### المرحلة 11: القوالب المحاسبية حسب القطاع ← `phase-11-industry-templates.md`
**الهدف**: توسيع القطاعات من 7 إلى 27 مع شجرة حسابات مخصصة

### المرحلة 12: إكمال المحاسبة ← `phase-12-accounting-complete.md`
**الهدف**: إضافة الوظائف المحاسبية الناقصة لمستوى QuickBooks

### المرحلة 13: إكمال الموارد البشرية ← `phase-13-hr-complete.md`
**الهدف**: تفعيل التابات الفارغة + نظام رواتب حسب الدولة

### المرحلة 14: الأمان والصلاحيات ← `phase-14-security-rbac.md`
**الهدف**: RBAC + سجل تدقيق + نسخ احتياطي

### المرحلة 16: AI ذكي ← `phase-16-ai-complete.md`
**الهدف**: ربط AI ببيانات حقيقية + Function Calling كامل

### المرحلة 17: الضرائب العالمية ← `phase-17-global-tax.md`
**الهدف**: دعم 20+ دولة مع أنواع ضرائب مختلفة

### المرحلة 18: التثبيت النهائي ← `phase-18-installer-final.md`
**الهدف**: MSIX + About + Splash

### الموقع (20-22) ← `phase-20/21/22-website-*.md`
**الهدف**: ترقية الموقع لمستوى QuickBooks Global
