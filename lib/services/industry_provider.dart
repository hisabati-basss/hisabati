import 'package:flutter/material.dart';

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

class IndustryModule {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int screenIndex;

  IndustryModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.screenIndex,
  });
}

class IndustryProvider extends ChangeNotifier {
  IndustryType _currentIndustry = IndustryType.general;
  IndustryType get currentIndustry => _currentIndustry;

  void setIndustry(IndustryType type) {
    _currentIndustry = type;
    notifyListeners();
  }

  String get industryName {
    switch (_currentIndustry) {
      case IndustryType.general: return 'تجارة عامة';
      case IndustryType.realEstate: return 'العقارات والإيجارات';
      case IndustryType.propertyMgmt: return 'إدارة الأملاك العقارية';
      case IndustryType.education: return 'المجال التعليمي (مدارس)';
      case IndustryType.trainingCenter: return 'المعاهد والمراكز التدريبية';
      case IndustryType.hospital: return 'المستشفيات';
      case IndustryType.clinic: return 'المراكز الصحية والعيادات';
      case IndustryType.pharmacy: return 'الصيدليات والأدوية';
      case IndustryType.agriculture: return 'الزراعة';
      case IndustryType.livestock: return 'الثروة الحيوانية';
      case IndustryType.fruitsVegetables: return 'الخضار والفواكه';
      case IndustryType.farm: return 'المزارع والإنتاج الزراعي';
      case IndustryType.foodTrading: return 'تجارة المواد الغذائية';
      case IndustryType.wholesale: return 'أسواق الجملة والتوزيع';
      case IndustryType.restaurant: return 'المطاعم والمقاهي';
      case IndustryType.bakery: return 'المخابز والحلويات';
      case IndustryType.perfume: return 'صناعة وبيع العطور';
      case IndustryType.foodFactory: return 'مصانع الأغذية';
      case IndustryType.manufacturing: return 'المصانع والإنتاج';
      case IndustryType.corporate: return 'الشركات والمكاتب';
      case IndustryType.construction: return 'المقاولات والإنشاءات';
      case IndustryType.retail: return 'المحلات التجارية (تجزئة)';
      case IndustryType.ecommerce: return 'التجارة الإلكترونية';
      case IndustryType.warehouse: return 'المخازن والمستودعات';
      case IndustryType.logistics: return 'النقل والخدمات اللوجستية';
      case IndustryType.carRental: return 'تأجير السيارات';
      case IndustryType.hospitality: return 'الفنادق والسياحة';
    }
  }

  List<IndustryModule> get relevantModules {
    List<IndustryModule> modules = [];
    
    // Core modules always present
    modules.add(IndustryModule(id: 'taxes', label: 'الضرائب', icon: Icons.receipt_long, color: Colors.orange, screenIndex: 3));
    modules.add(IndustryModule(id: 'inventory', label: 'المخزون', icon: Icons.inventory, color: Colors.green, screenIndex: 10));
    
    // Industry-specific modules
    switch (_currentIndustry) {
      case IndustryType.realEstate:
        modules.add(IndustryModule(id: 'rentals', label: 'الإيجارات', icon: Icons.home_work, color: Colors.blueAccent, screenIndex: 100));
        modules.add(IndustryModule(id: 'maintenance', label: 'الصيانة', icon: Icons.build, color: Colors.redAccent, screenIndex: 100));
        modules.add(IndustryModule(id: 'checks', label: 'الشيكات', icon: Icons.account_balance_wallet, color: Colors.indigo, screenIndex: 100));
        break;
      case IndustryType.carRental:
        modules.add(IndustryModule(id: 'fleet', label: 'الأسطول', icon: Icons.directions_car, color: Colors.blue, screenIndex: 100));
        modules.add(IndustryModule(id: 'contracts', label: 'العقود', icon: Icons.description, color: Colors.teal, screenIndex: 100));
        modules.add(IndustryModule(id: 'fuel', label: 'الوقود', icon: Icons.local_gas_station, color: Colors.orangeAccent, screenIndex: 100));
        break;
      case IndustryType.education:
        modules.add(IndustryModule(id: 'students', label: 'الطلاب', icon: Icons.school, color: Colors.purple, screenIndex: 100));
        modules.add(IndustryModule(id: 'fees', label: 'الرسوم', icon: Icons.payments, color: Colors.greenAccent, screenIndex: 100));
        break;
      default:
        modules.add(IndustryModule(id: 'auditing', label: 'التدقيق', icon: Icons.security, color: Colors.redAccent, screenIndex: 5));
        modules.add(IndustryModule(id: 'hr', label: 'الموارد البشرية', icon: Icons.people, color: Colors.blue, screenIndex: 4));
        break;
    }
    
    return modules;
  }

}
