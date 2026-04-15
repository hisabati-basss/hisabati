# المرحلة 17: نظام الضرائب العالمي

## الأولوية: 🟡 متوسطة

## السياق
التطبيق حالياً يدعم ضريبة القيمة المضافة (VAT) بنسبة ثابتة. المطلوب نظام ضريبي عالمي يدعم عدة دول وأنواع ضرائب.

**الملفات الموجودة:**
- `lib/services/tax_engine.dart` — محرك ضرائب أساسي
- `lib/services/tax_service.dart` — خدمة الضرائب
- `lib/screens/taxes_screen.dart` — شاشة الضرائب

## المهام

### 17.1 توسيع محرك الضرائب
**ملف:** `lib/services/tax_engine.dart`

إضافة دعم لـ 20+ دولة:

```dart
static final Map<String, TaxConfig> countryTaxConfigs = {
  'SA': TaxConfig(name: 'ضريبة القيمة المضافة', rate: 15.0, code: 'VAT', hasEInvoicing: true, eInvoiceProvider: 'ZATCA'),
  'AE': TaxConfig(name: 'ضريبة القيمة المضافة', rate: 5.0, code: 'VAT', hasEInvoicing: true, eInvoiceProvider: 'FTA'),
  'EG': TaxConfig(name: 'ضريبة القيمة المضافة', rate: 14.0, code: 'VAT', hasEInvoicing: true),
  'JO': TaxConfig(name: 'ضريبة المبيعات', rate: 16.0, code: 'GST'),
  'KW': TaxConfig(name: 'لا ضريبة', rate: 0.0, code: 'NONE'),
  'BH': TaxConfig(name: 'ضريبة القيمة المضافة', rate: 10.0, code: 'VAT'),
  'OM': TaxConfig(name: 'ضريبة القيمة المضافة', rate: 5.0, code: 'VAT'),
  'QA': TaxConfig(name: 'لا ضريبة', rate: 0.0, code: 'NONE'),
  'TR': TaxConfig(name: 'KDV', rate: 20.0, code: 'KDV'),
  'US': TaxConfig(name: 'Sales Tax', rate: 0.0, code: 'SALES_TAX', isStateLevel: true),
  'GB': TaxConfig(name: 'VAT', rate: 20.0, code: 'VAT'),
  'DE': TaxConfig(name: 'MwSt', rate: 19.0, code: 'VAT'),
  'FR': TaxConfig(name: 'TVA', rate: 20.0, code: 'VAT'),
  'IN': TaxConfig(name: 'GST', rate: 18.0, code: 'GST'),
  // ... أضف باقي الدول
};
```

### 17.2 الإقرارات الضريبية
**تحسين:** `lib/screens/taxes_screen.dart`

إضافة تبويب "الإقرارات" يعرض:
1. إقرارات سابقة (من جدول `tax_filings`)
2. إنشاء إقرار جديد لفترة (ربع سنوي/شهري)
3. حساب تلقائي: VAT مجمعة - VAT مخصومة = صافي الضريبة
4. حالات: مسودة → مُرسل → مقبول

### 17.3 التنبيهات الضريبية
إضافة في `notification_service.dart`:
- تذكير قبل موعد تقديم الإقرار بـ 7 أيام
- تنبيه عند تجاوز حد التسجيل الضريبي
- تنبيه عند فواتير بدون رقم ضريبي

## معايير القبول
- [ ] اختيار دولة "السعودية" → ضريبة 15% + ZATCA QR
- [ ] اختيار "الإمارات" → ضريبة 5%
- [ ] اختيار "الكويت" → بدون ضريبة
- [ ] إقرار ضريبي → يحسب صافي VAT تلقائياً
