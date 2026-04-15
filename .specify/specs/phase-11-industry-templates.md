# المرحلة 11: القوالب المحاسبية حسب القطاع (مستوى QuickBooks)

## الأولوية: 🔴 حرجة — يجب تنفيذها الآن

## السياق
التطبيق حالياً يدعم 7 قطاعات فقط في `lib/services/industry_provider.dart` (enum `IndustryType`).
المطلوب توسيعها إلى 24+ قطاع بحيث يعمل كل قطاع كـ **قالب محاسبي** (chart of accounts + شاشة خاصة اختيارية)، وليس كنظام منفصل.

**المبدأ**: مثل QuickBooks — عند اختيار المستخدم "مطاعم" أثناء onboarding، يتم تحميل شجرة حسابات مخصصة للمطاعم ويظهر له وحدات خاصة بالمطاعم.

## المهام

### 11.1 توسيع IndustryType enum
**ملف:** `lib/services/industry_provider.dart`

استبدال الـ enum الحالي:
```dart
// قبل:
enum IndustryType { general, realEstate, education, hospitality, healthcare, manufacturing, carRental }

// بعد:
enum IndustryType {
  general,           // التجارة العامة
  realEstate,        // العقارات والإيجارات
  propertyMgmt,      // إدارة الأملاك العقارية
  education,         // المدارس
  trainingCenter,    // المعاهد والمراكز التدريبية
  hospital,          // المستشفيات
  clinic,            // المراكز الصحية والعيادات
  pharmacy,          // الصيدليات والأدوية
  agriculture,       // الزراعة
  livestock,         // الثروة الحيوانية
  fruitsVegetables,  // الخضار والفواكه (أسواق جملة وتجزئة)
  farm,              // المزارع والإنتاج الزراعي
  foodTrading,       // تجارة المواد الغذائية
  wholesale,         // أسواق الجملة والتوزيع
  restaurant,        // المطاعم والمقاهي والكافيهات
  bakery,            // المخابز والحلويات
  perfume,           // صناعة وبيع العطور
  foodFactory,       // مصانع الأغذية والتصنيع الغذائي
  manufacturing,     // المصانع (عام)
  corporate,         // الشركات والمكاتب
  construction,      // المقاولات والإنشاءات
  retail,            // المحلات التجارية (جميع الأنشطة)
  ecommerce,         // التجارة الإلكترونية
  warehouse,         // المخازن والمستودعات
  logistics,         // النقل والتوصيل والشحن
  carRental,         // تأجير السيارات
  hospitality,       // الفنادق والسياحة
}
```

### 11.2 توسيع industryName getter
في نفس الملف `lib/services/industry_provider.dart`، تحديث `industryName` getter ليشمل كل القطاعات الجديدة بأسماء عربية صحيحة.

### 11.3 توسيع relevantModules
في نفس الملف، تحديث `relevantModules` ليعطي كل قطاع وحداته المناسبة.

**القاعدة**: كل القطاعات تحصل على:
- الضرائب
- المخزون (ما عدا `corporate` و `realEstate`)
- المحاسبة
- التقارير

القطاعات المتخصصة تحصل على وحدات إضافية:
| القطاع | وحدات إضافية |
|--------|-------------|
| `realEstate`, `propertyMgmt` | شاشة العقارات الموجودة (`real_estate_screen.dart`) |
| `construction` | المشاريع (`projects_screen.dart`) + الأصول + الصيانة |
| `restaurant`, `bakery`, `foodFactory` | التصنيع (`manufacturing_screen.dart`) + BOM |
| `manufacturing`, `perfume` | التصنيع + BOM + الأصول |
| `hospital`, `clinic`, `pharmacy` | المخزون (أدوية) + تواريخ الصلاحية (`expiry_dashboard_screen.dart`) |
| `agriculture`, `livestock`, `farm` | المخزون + تواريخ الصلاحية |
| `wholesale`, `foodTrading`, `fruitsVegetables` | المخزون + المستودعات (`warehouse_screen.dart`) |
| `logistics` | الأسطول (يُستخدم الأصول مؤقتاً) + المشاريع |
| `carRental` | الأسطول (الأصول) + العقود |
| `ecommerce` | التسويق (`affiliate_screen.dart`) + العمولات |
| `education`, `trainingCenter` | المشاريع (كـ "فصول/دورات") |

### 11.4 إنشاء شجرة حسابات لكل قطاع
**ملف:** `lib/core/accounting/coa_template.dart`

هذا الملف يجب أن يحتوي على دالة:
```dart
static List<Map<String, dynamic>> getTemplateAccounts(IndustryType industry)
```

لكل قطاع، يُرجع شجرة حسابات مناسبة. **مثال للمطاعم:**
```dart
case IndustryType.restaurant:
  return [
    // أصول
    {'id': 'ACC_CASH', 'code': '101', 'name': 'الخزينة/الصندوق', 'type': 'asset'},
    {'id': 'ACC_BANK', 'code': '102', 'name': 'البنك', 'type': 'asset'},
    {'id': 'ACC_RECEIVABLE', 'code': '103', 'name': 'مدينون', 'type': 'asset'},
    {'id': 'ACC_INVENTORY_RAW', 'code': '104', 'name': 'مخزون مواد خام', 'type': 'asset'},
    {'id': 'ACC_INVENTORY_PACKAGING', 'code': '105', 'name': 'مخزون تغليف', 'type': 'asset'},
    // خصوم
    {'id': 'ACC_PAYABLE', 'code': '201', 'name': 'دائنون (موردين)', 'type': 'liability'},
    {'id': 'ACC_VAT_PAYABLE', 'code': '202', 'name': 'ضريبة القيمة المضافة', 'type': 'liability'},
    {'id': 'ACC_SALARIES_PAYABLE', 'code': '203', 'name': 'رواتب مستحقة', 'type': 'liability'},
    // إيرادات
    {'id': 'ACC_SALES_DINE_IN', 'code': '401', 'name': 'إيرادات - داخل المطعم', 'type': 'revenue'},
    {'id': 'ACC_SALES_DELIVERY', 'code': '402', 'name': 'إيرادات - توصيل', 'type': 'revenue'},
    {'id': 'ACC_SALES_CATERING', 'code': '403', 'name': 'إيرادات - تموين حفلات', 'type': 'revenue'},
    // مصروفات
    {'id': 'ACC_COGS', 'code': '501', 'name': 'تكلفة المواد الغذائية', 'type': 'expense'},
    {'id': 'ACC_SALARY_EXP', 'code': '502', 'name': 'مصروفات الرواتب', 'type': 'expense'},
    {'id': 'ACC_RENT_EXP', 'code': '503', 'name': 'إيجار الموقع', 'type': 'expense'},
    {'id': 'ACC_UTILITIES_EXP', 'code': '504', 'name': 'كهرباء وماء وغاز', 'type': 'expense'},
    {'id': 'ACC_MARKETING_EXP', 'code': '505', 'name': 'مصروفات تسويق', 'type': 'expense'},
    {'id': 'ACC_MAINTENANCE_EXP', 'code': '506', 'name': 'صيانة معدات المطبخ', 'type': 'expense'},
    {'id': 'ACC_DELIVERY_EXP', 'code': '507', 'name': 'مصروفات التوصيل', 'type': 'expense'},
    {'id': 'ACC_DEPRECIATION', 'code': '508', 'name': 'مصروف إهلاك', 'type': 'expense'},
    // حقوق ملكية
    {'id': 'ACC_CAPITAL', 'code': '301', 'name': 'رأس المال', 'type': 'equity'},
    {'id': 'ACC_RETAINED', 'code': '302', 'name': 'أرباح محتجزة', 'type': 'equity'},
  ];
```

**يجب إنشاء قوالب لكل قطاع من الـ 27 قطاع**. كل قالب يجب أن يحتوي على حسابات ذات أسماء مناسبة للقطاع.

### 11.5 تحديث شاشة الـ Onboarding
**ملف:** `lib/screens/onboarding_screen.dart`

- حالياً الشاشة تعرض 7 قطاعات فقط.
- يجب تحديثها لعرض جميع الـ 27 قطاع.
- **التصميم**: شبكة (Grid) بأيقونات وألوان جميلة لكل قطاع.
- عند اختيار قطاع → تُحمّل شجرة الحسابات المناسبة من `coa_template.dart`.
- عند اختيار قطاع → تُحدّث `IndustryProvider` ليُظهر الوحدات المخصصة.

### 11.6 تحديث ملفات الترجمة
**ملفات:** `assets/translations/ar.json` و `assets/translations/en.json`

إضافة أسماء كل قطاع بالعربية والإنجليزية:
```json
{
  "industries": {
    "general": "التجارة العامة",
    "realEstate": "العقارات والإيجارات",
    "propertyMgmt": "إدارة الأملاك العقارية",
    "restaurant": "المطاعم والمقاهي", 
    "construction": "المقاولات والإنشاءات",
    ...
  }
}
```

## معايير القبول
- [ ] `flutter analyze` بدون أخطاء
- [ ] عند اختيار "مطاعم" → شجرة الحسابات تحتوي حسابات التكلفة الغذائية وإيرادات التوصيل
- [ ] عند اختيار "عقارات" → تظهر وحدة العقارات في القائمة الجانبية
- [ ] عند اختيار "مستشفيات" → تظهر وحدة تواريخ صلاحية الأدوية
- [ ] كل الـ 27 قطاع تظهر في شاشة الـ onboarding بشكل جميل
