# المرحلة 6: دعم متعدد الدول والعملات والضرائب

## الأولوية: 🟡 متوسطة

## السياق
حالياً التطبيق يدعم 5 دول و5 عملات فقط مع نسب ضريبية محدودة.
نصوص كثيرة مكتوبة بالعربية مباشرة (hardcoded) بدلاً من نظام الترجمة.

## المهام

### 6.1 محرك الضرائب الذكي
**ملف جديد:** `lib/services/tax_engine.dart`

```dart
class TaxEngine {
  // تحديد نوع الضريبة ونسبتها حسب الدولة
  static TaxConfig getConfigForCountry(String countryCode);
  
  // حساب الضريبة على سعر
  static double calculateTax(double amount, String countryCode, {String? itemCategory});
  
  // التحقق من صحة الرقم الضريبي
  static bool validateTaxNumber(String number, String countryCode);
  
  // إنشاء فاتورة ضريبية متوافقة
  static Map<String, dynamic> generateTaxCompliantInvoice(String countryCode, Map invoice);
}

class TaxConfig {
  final String countryCode;
  final String taxName; // VAT, GST, KDV, etc
  final double standardRate;
  final List<TaxBracket>? incomeTaxBrackets; // للدول مع ضريبة دخل
  final bool hasEInvoicing; // فوترة إلكترونية
  final String? eInvoiceProvider; // ZATCA, FTA, etc
  final Map<String, double> specialRates; // zero-rated, exempt items
}
```

### 6.2 خدمة العملات
**ملف جديد:** `lib/services/currency_service.dart`

```dart
class CurrencyService {
  // أسعار الصرف الأساسية (أوفلاين)
  static const Map<String, double> baseRatesUSD = {
    'SAR': 3.75, 'AED': 3.67, 'EGP': 50.5, 'KWD': 0.31,
    'JOD': 0.71, 'BHD': 0.376, 'OMR': 0.385, 'QAR': 3.64,
    'LBP': 89500, 'IQD': 1310, 'LYD': 4.85, 'SDG': 601,
    'TND': 3.12, 'MAD': 10.05, 'DZD': 134.5, 'TRY': 36.5,
    'USD': 1.0, 'GBP': 0.79, 'EUR': 0.92, 'INR': 84.5,
  };
  
  // تحويل مبلغ
  static double convert(double amount, String from, String to);
  
  // رمز العملة
  static String getSymbol(String code);
  
  // تنسيق المبلغ حسب العملة
  static String format(double amount, String currencyCode);
  
  // تحديث الأسعار من الإنترنت (اختياري)
  Future<void> updateRatesOnline();
}
```

### 6.3 توسيع الإعدادات
**ملف:** `lib/screens/settings_screen.dart`

#### الدول (من 5 → 20+):
- [ ] إضافة كل الدول العربية + تركيا + دول رئيسية
- [ ] عند اختيار الدولة:
  - تتغير العملة الافتراضية تلقائياً
  - تتغير نسبة الضريبة الافتراضية
  - تتغير قواعد الرواتب
  - يتغير شكل الفاتورة

#### العملات (من 5 → 20+):
- [ ] إضافة كل العملات مع رموزها

#### الضرائب:
- [ ] بدلاً من dropdown ثابت، استخدام حقل رقمي مع اقتراح افتراضي حسب الدولة

### 6.4 إزالة النصوص Hardcoded
**جميع الشاشات المتأثرة:**

| الملف | النص Hardcoded | يُستبدل بـ |
|-------|----------------|------------|
| `inventory_screen.dart` | `"ر.س"` | `CurrencyService.getSymbol(settings.currency)` |
| `inventory_screen.dart` | `"إدارة المخزون"` | `tr('inventory.title')` |
| `inventory_screen.dart` | `"صنف جديد"` | `tr('inventory.new_item')` |
| `inventory_screen.dart` | `"قطعة"` | `tr('inventory.unit')` |
| `hr_screen.dart` | `"مرشح جديد"` | `tr('hr.new_candidate')` |
| `hr_screen.dart` | `"إضافة موظف جديد"` | `tr('hr.add_employee')` |
| `hr_screen.dart` | `"الجنسية"` | `tr('hr.nationality')` |
| `hr_screen.dart` | `"البيانات الشخصية"` | `tr('hr.personal_data')` |
| `hr_screen.dart` | `"الوظيفة والدوام"` | `tr('hr.job_attendance')` |
| `hr_screen.dart` | `"المالية والرواتب"` | `tr('hr.financial')` |
| `login_screen.dart` | `"أهلاً بك مجدداً"` | `tr('login.welcome_back')` |
| `login_screen.dart` | `"سجل دخولك..."` | `tr('login.subtitle')` |
| `login_screen.dart` | `"البريد الوظيفي"` | `tr('login.email')` |
| `login_screen.dart` | `"كلمة المرور"` | `tr('login.password')` |
| `login_screen.dart` | `"نسيت كلمة المرور؟"` | `tr('login.forgot_password')` |
| `login_screen.dart` | `"تسجيل الدخول"` | `tr('login.sign_in')` |
| `login_screen.dart` | `"حساب جوجل"` | `tr('login.google')` |
| وغيرها | ... | ... |

- [ ] البحث في كل ملف عن نصوص عربية بين `""` أو `''`
- [ ] إضافة المفاتيح المقابلة في `ar.json` و `en.json`
- [ ] استبدال كل نص بـ `tr('key')`

### 6.5 تحديث ملفات الترجمة
**ملف:** `assets/translations/ar.json`
**ملف:** `assets/translations/en.json`

- [ ] إضافة ~200 مفتاح ترجمة جديد
- [ ] التأكد من أن كل مفتاح موجود في كلا الملفين
- [ ] إضافة ترجمات لأسماء الدول والعملات

## معايير القبول
- [ ] تبديل الدولة → تتغير العملة والضريبة تلقائياً
- [ ] تبديل اللغة EN → كل النصوص تتحول للإنجليزية (صفر نص عربي)
- [ ] الفواتير تعرض رمز العملة الصحيح
- [ ] حساب الضريبة صحيح لكل دولة
- [ ] لا يوجد أي نص hardcoded في كل الشاشات
