# المرحلة 13: إكمال الموارد البشرية + HR Pro

## الأولوية: 🟠 عالية

## السياق
شاشة HR تم تقسيمها في مجلد `lib/screens/hr/`. لكن هناك تابات فارغة (المستندات والعهد) ووظائف ناقصة (WPS، تأمينات حسب الدولة، عقود).

## المهام

### 13.1 تفعيل تاب المستندات
**ملف:** ضمن مجلد `lib/screens/hr/` — أيًا كان الملف الذي يحتوي على تابات التفاصيل

**الجدول في DB (موجود):** `documents` (أُنشئ في v48 من `database_helper.dart`)
```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  owner_type TEXT,    -- 'employee', 'supplier', 'client'
  owner_id TEXT,      -- ID الموظف/المورد
  name TEXT,          -- اسم المستند
  file_path TEXT,     -- مسار الملف المحلي
  file_type TEXT,     -- 'id_card', 'passport', 'iqama', 'contract', 'certificate', 'license'
  expiry_date TEXT,   -- تاريخ انتهاء الصلاحية
  status TEXT DEFAULT 'active',
  created_at TEXT, updated_at TEXT,
  sync_status INTEGER DEFAULT 0, is_deleted INTEGER DEFAULT 0
)
```

**الوظائف:**
1. عرض قائمة مستندات الموظف
2. رفع مستند من الجهاز (صورة/PDF) باستخدام `file_picker`
3. أنواع المستندات: هوية، جواز، إقامة، رخصة قيادة، شهادة، عقد عمل
4. عرض تاريخ الانتهاء بلون:
   - أخضر: > 90 يوم
   - برتقالي: 30-90 يوم
   - أحمر: < 30 يوم أو منتهي
5. تنبيه قبل الانتهاء بـ 30 يوم (عبر `notification_service.dart`)
6. عرض المستند بالضغط عليه

### 13.2 تفعيل تاب العهد
**نفس الملف**

**الجداول:** `financial_custodies` + `asset_custody_log` (أو `asset_custody_logs`)

**الوظائف:**
1. عرض العهد المالية من `financial_custodies` WHERE `employee_id = ?`
2. عرض عهد الأصول من `asset_custody_log` WHERE `employee_id = ?` + JOIN `assets`
3. إضافة عهدة جديدة (مالية أو أصل)
4. تصفية عهدة (إرجاع مع ملاحظات + تاريخ)
5. ربط بقيود اليومية تلقائياً عبر `accounting_engine.dart`

### 13.3 تقييم الأداء
**الجدول في DB (موجود):** `performance_reviews` (أُنشئ في v52)

**الوظائف:**
1. إنشاء تقييم لموظف (rating 1-5، ملاحظات المدير)
2. عرض سجل التقييمات السابقة
3. رسم بياني لتطور الأداء عبر الزمن

### 13.4 عقود العمل
**الجدول في DB (موجود):** `employee_contracts` (أُنشئ في v52)

**الوظائف:**
1. إنشاء عقد مربوط بالموظف (دائم/مؤقت/تدريب)
2. تاريخ بداية ونهاية
3. تنبيه قبل انتهاء العقد بـ 30 يوم
4. طباعة عقد PDF عبر `pdf_service.dart`

### 13.5 نظام رواتب حسب الدولة
**ملف:** `lib/services/payroll_service.dart`

يجب إنشاء `Map` أو `class` لقواعد كل دولة:

```dart
class CountryPayrollConfig {
  final String countryCode;
  final double employerSocialInsurance; // نسبة التأمينات من الشركة
  final double employeeSocialInsurance; // نسبة التأمينات من الموظف
  final List<TaxBracket>? incomeTaxBrackets; // شرائح ضريبة الدخل
  final double endOfServicePerYear; // أيام مكافأة نهاية الخدمة لكل سنة
}

static final Map<String, CountryPayrollConfig> configs = {
  'SA': CountryPayrollConfig(
    countryCode: 'SA',
    employerSocialInsurance: 0.0975, // 9.75%
    employeeSocialInsurance: 0.0975, // 9.75% (سعوديين فقط)
    incomeTaxBrackets: null, // لا ضريبة دخل
    endOfServicePerYear: 30, // شهر لكل سنة
  ),
  'EG': CountryPayrollConfig(
    countryCode: 'EG',
    employerSocialInsurance: 0.11,
    employeeSocialInsurance: 0.11,
    incomeTaxBrackets: [
      TaxBracket(from: 0, to: 15000, rate: 0),
      TaxBracket(from: 15001, to: 30000, rate: 0.025),
      TaxBracket(from: 30001, to: 45000, rate: 0.10),
      TaxBracket(from: 45001, to: 60000, rate: 0.15),
      TaxBracket(from: 60001, to: 200000, rate: 0.20),
      TaxBracket(from: 200001, to: 400000, rate: 0.225),
      TaxBracket(from: 400001, to: double.infinity, rate: 0.25),
    ],
    endOfServicePerYear: 30,
  ),
  'AE': CountryPayrollConfig(
    countryCode: 'AE',
    employerSocialInsurance: 0.125, // إماراتيين فقط
    employeeSocialInsurance: 0.05,
    incomeTaxBrackets: null,
    endOfServicePerYear: 21, // أول 5 سنوات، ثم 30
  ),
  'JO': CountryPayrollConfig(
    countryCode: 'JO',
    employerSocialInsurance: 0.11,
    employeeSocialInsurance: 0.065,
    incomeTaxBrackets: [...],
    endOfServicePerYear: 30,
  ),
};
```

## معايير القبول
- [ ] تاب المستندات → رفع ملف + عرضه + تاريخ صلاحية ملون
- [ ] تاب العهد → عرض العهد المالية والأصول + تصفية
- [ ] تقييم أداء → حفظ + عرض سجل
- [ ] عقد عمل → إنشاء + طباعة PDF
- [ ] رواتب سعودية → خصم GOSI 9.75%
- [ ] رواتب مصرية → حساب ضريبة دخل تصاعدية
