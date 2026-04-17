// lib/core/accounting/coa_template.dart
import '../../services/industry_provider.dart';

class COATemplate {
  /// Returns initial Chart of Accounts as SQLite-ready maps based on the selected industry.
  static List<Map<String, dynamic>> getTemplateAccounts(IndustryType industry) {
    List<Map<String, dynamic>> accounts = _getBaseAccounts();

    // Ensure that core engine IDs are present in EVERY industry
    // The engine relies on ACC_INVENTORY, ACC_SALES, ACC_COGS.
    accounts.addAll([
      {'id': 'ACC_INVENTORY', 'code': '1140', 'name': 'المخزون السلعي العام', 'type': 'asset'},
      {'id': 'ACC_SALES', 'code': '4100', 'name': 'إيرادات المبيعات العامة', 'type': 'revenue'},
      {'id': 'ACC_COGS', 'code': '5100', 'name': 'تكلفة المبيعات العامة', 'type': 'expense'},
    ]);

    switch (industry) {
      case IndustryType.realEstate:
      case IndustryType.propertyMgmt:
        accounts.addAll([
          {'code': '1131', 'name': 'ذمم المستأجرين', 'type': 'asset'},
          {'code': '1240', 'name': 'المباني والعقارات الاستثمارية', 'type': 'asset'},
          {'code': '2150', 'name': 'تأمينات مستأجرين مستردة', 'type': 'liability'},
          {'code': '4110', 'name': 'إيرادات إيجارات عقارية', 'type': 'revenue'},
          {'code': '4120', 'name': 'إيرادات رسوم إدارة أملاك', 'type': 'revenue'},
          {'code': '5250', 'name': 'مصروفات صيانة وترميم', 'type': 'expense'},
          {'code': '5260', 'name': 'مصروفات رسوم وساطة عقارية', 'type': 'expense'},
        ]);
        break;

      case IndustryType.restaurant:
      case IndustryType.bakery:
      case IndustryType.foodFactory:
        accounts.addAll([
          {'code': '1141', 'name': 'مخزن مواد غذائية خام', 'type': 'asset'},
          {'code': '1142', 'name': 'مخزن مواد تغليف وتعليب', 'type': 'asset'},
          {'code': '4101', 'name': 'مبيعات - داخل الصالة', 'type': 'revenue'},
          {'code': '4102', 'name': 'مبيعات - سفري / توصيل', 'type': 'revenue'},
          {'code': '5110', 'name': 'تكلفة المواد الأولية (COGS)', 'type': 'expense'},
          {'code': '5255', 'name': 'مصروفات الغاز والوقود (مطبخ)', 'type': 'expense'},
          {'code': '5265', 'name': 'مصروفات أدوات مائدة واستهلاكيات', 'type': 'expense'},
        ]);
        break;

      case IndustryType.construction:
        accounts.addAll([
          {'code': '1145', 'name': 'مخزن مواد بنااء (حديد/أسمنت)', 'type': 'asset'},
          {'code': '1146', 'name': 'مشاريع تحت التنفيذ (WIP)', 'type': 'asset'},
          {'code': '2160', 'name': 'ذمم مقاولي الباطن', 'type': 'liability'},
          {'code': '2170', 'name': 'تأمينات محتجزة للغير', 'type': 'liability'},
          {'code': '4210', 'name': 'إيرادات مستخلصات مشاريع', 'type': 'revenue'},
          {'code': '5310', 'name': 'تكلفة مواد بناء مستخدمة', 'type': 'expense'},
          {'code': '5320', 'name': 'أجور عمالة مهنية ومقاولين', 'type': 'expense'},
        ]);
        break;

      case IndustryType.hospital:
      case IndustryType.clinic:
      case IndustryType.pharmacy:
        accounts.addAll([
          {'code': '1144', 'name': 'مخزن أدوية ومستلزمات طبية', 'type': 'asset'},
          {'code': '4310', 'name': 'إيرادات كشوفات طبية', 'type': 'revenue'},
          {'code': '4320', 'name': 'إيرادات خدمات مختبر وأشعة', 'type': 'revenue'},
          {'code': '4330', 'name': 'مبيعات صيدلية', 'type': 'revenue'},
          {'code': '5410', 'name': 'تكلفة أدوية ومستهلكات طبية', 'type': 'expense'},
          {'code': '5420', 'name': 'رواتب أطباء وفنيين', 'type': 'expense'},
        ]);
        break;

      case IndustryType.education:
      case IndustryType.trainingCenter:
        accounts.addAll([
          {'code': '1132', 'name': 'ذمم أولياء أمور / طلاب', 'type': 'asset'},
          {'code': '2180', 'name': 'رسوم دراسية محصلة مقدماً', 'type': 'liability'},
          {'code': '4410', 'name': 'إيرادات رسوم دراسية', 'type': 'revenue'},
          {'code': '4420', 'name': 'إيرادات كتب وزي مدرسي', 'type': 'revenue'},
          {'code': '4430', 'name': 'إيرادات حافلات ونقل', 'type': 'revenue'},
          {'code': '5510', 'name': 'رواتب هيئة تدريس', 'type': 'expense'},
          {'code': '5520', 'name': 'مصروفات أنشطة ووسائل تعليمية', 'type': 'expense'},
        ]);
        break;

      case IndustryType.agriculture:
      case IndustryType.livestock:
      case IndustryType.farm:
        accounts.addAll([
          {'code': '1250', 'name': 'أصول حيوية (مواشي/أشجار)', 'type': 'asset'},
          {'code': '1147', 'name': 'مخزن أسمدة ومبيدات', 'type': 'asset'},
          {'code': '1148', 'name': 'مخزن أعلاف وبذور', 'type': 'asset'},
          {'code': '4510', 'name': 'إيرادات محاصيل زراعية', 'type': 'revenue'},
          {'code': '4520', 'name': 'إيرادات منتجات حيوانية', 'type': 'revenue'},
          {'code': '5610', 'name': 'تكلفة بذور وأسمدة', 'type': 'expense'},
          {'code': '5620', 'name': 'مصروفات ري وطاقة زراعية', 'type': 'expense'},
        ]);
        break;

      case IndustryType.manufacturing:
      case IndustryType.perfume:
        accounts.addAll([
          {'code': '1141', 'name': 'مخزن مواد خام', 'type': 'asset'},
          {'code': '1142', 'name': 'مخزن تحت التصنيع (WIP)', 'type': 'asset'},
          {'code': '1143', 'name': 'مخزن إنتاج تام', 'type': 'asset'},
          {'code': '4610', 'name': 'مبيعات منتجات مصنعة', 'type': 'revenue'},
          {'code': '5710', 'name': 'تكلفة مواد خام مستخدمة', 'type': 'expense'},
          {'code': '5720', 'name': 'أجور عمال إنتاج مباشرة', 'type': 'expense'},
          {'code': '5730', 'name': 'إهلاك ماكينات ومعدات', 'type': 'expense'},
        ]);
        break;

      case IndustryType.retail:
      case IndustryType.wholesale:
      case IndustryType.foodTrading:
      case IndustryType.fruitsVegetables:
      case IndustryType.ecommerce:
        accounts.addAll([
          {'code': '5820', 'name': 'مصروفات نقل وشحن مشتريات', 'type': 'expense'},
          {'code': '5830', 'name': 'مصروفات تغليف وتعبئة', 'type': 'expense'},
        ]);
        break;

      case IndustryType.logistics:
        accounts.addAll([
          {'code': '1235', 'name': 'شاحنات ووسائل نقل ثقيل', 'type': 'asset'},
          {'code': '4810', 'name': 'إيرادات خدمات نقل وشحن', 'type': 'revenue'},
          {'code': '4820', 'name': 'إيرادات خدمات تخزين للغير', 'type': 'revenue'},
          {'code': '5910', 'name': 'مصروفات وقود وزيوت أسطول', 'type': 'expense'},
          {'code': '5920', 'name': 'مصروفات صيانة وقطع غيار أسطول', 'type': 'expense'},
          {'code': '5930', 'name': 'مخالفات ورسوم طريق', 'type': 'expense'},
        ]);
        break;

      case IndustryType.carRental:
        accounts.addAll([
          {'code': '1236', 'name': 'سيارات مخصصة للإيجار', 'type': 'asset'},
          {'code': '2190', 'name': 'تأمينات مستأجري سيارات', 'type': 'liability'},
          {'code': '4910', 'name': 'إيرادات تأجير سيارات', 'type': 'revenue'},
          {'code': '5940', 'name': 'مصروفات تأمين سيارات', 'type': 'expense'},
          {'code': '5950', 'name': 'مصروفات ترخيص وتجديد', 'type': 'expense'},
        ]);
        break;

      default:
        break;
    }

    return accounts;
  }

  static List<Map<String, dynamic>> _getBaseAccounts() {
    return [
      // 1. Assets
      {'id': 'ACC_CASH', 'code': '1110', 'name': 'الصندوق (الخزينة العامة)', 'type': 'asset'},
      {'id': 'ACC_BANK', 'code': '1120', 'name': 'البنك (حساب جاري)', 'type': 'asset'},
      {'id': 'ACC_RECEIVABLE', 'code': '1130', 'name': 'ذمم العملاء (مدينون)', 'type': 'asset'},
      {'code': '1150', 'name': 'سلف وعهد موظفين', 'type': 'asset'},
      {'code': '1210', 'name': 'الأراضي', 'type': 'asset'},
      {'code': '1220', 'name': 'المباني والمنشآت', 'type': 'asset'},
      {'code': '1230', 'name': 'الآلات والمعدات', 'type': 'asset'},
      {'code': '1250', 'name': 'الأثاث والمعدات المكتبية', 'type': 'asset'},
      {'code': '1260', 'name': 'أجهزة الحاسب والبرمجيات', 'type': 'asset'},
      {'code': '1299', 'name': 'مجمع إهلاك الأصول الثابتة', 'type': 'asset'}, // Contra-asset

      // 2. Liabilities
      {'id': 'ACC_PAYABLE', 'code': '2110', 'name': 'ذمم الموردين (دائنون)', 'type': 'liability'},
      {'id': 'ACC_VAT', 'code': '2131', 'name': 'ضريبة القيمة المضافة المحصلة', 'type': 'liability'},
      {'id': 'ACC_VAT_RECEIVABLE', 'code': '2132', 'name': 'ضريبة القيمة المضافة المدفوعة', 'type': 'liability'},
      {'code': '2140', 'name': 'رواتب وأجور مستحقة', 'type': 'liability'},

      // 3. Equity
      {'code': '3100', 'name': 'رأس المال المسموح به', 'type': 'equity'},
      {'id': 'ACC_RETAINED_EARNINGS', 'code': '3200', 'name': 'الأرباح والخسائر المدورة', 'type': 'equity'},
      {'code': '3300', 'name': 'رصيد افتتاح المدة (Opening Balance)', 'type': 'equity'},

      // 4. Revenue
      {'code': '4200', 'name': 'إيرادات أخرى', 'type': 'revenue'},
      {'code': '4300', 'name': 'أرباح فروق تحويل العملات', 'type': 'revenue'},
      {'code': '4400', 'name': 'خصومات مكتسبة من المشتريات', 'type': 'revenue'},

      // 5. Common Expenses
      {'code': '5210', 'name': 'مصروفات الرواتب والأجور', 'type': 'expense'},
      {'code': '5220', 'name': 'مصروف الإيجار', 'type': 'expense'},
      {'code': '5230', 'name': 'كهرباء ومياه وانترنت', 'type': 'expense'},
      {'code': '5240', 'name': 'مصاريف تسويق وإعلانات', 'type': 'expense'},
      {'code': '5250', 'name': 'مصاريف قرطاسية ومكتبية', 'type': 'expense'},
      {'code': '5260', 'name': 'خسائر فروق تحويل العملات', 'type': 'expense'},
      {'code': '5270', 'name': 'خصومات مسموح بها للمبيعات', 'type': 'expense'},
      {'code': '5280', 'name': 'مصروف الإهلاك الدوري', 'type': 'expense'},
    ];
  }
}
