import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/module_config_service.dart';
import '../theme/app_theme_extension.dart';

class OnboardingModulesScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingModulesScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingModulesScreen> createState() => _OnboardingModulesScreenState();
}

class _OnboardingModulesScreenState extends State<OnboardingModulesScreen> {
  List<String> _selectedModules = ['accounting']; // Default to accounting

  @override
  void initState() {
    super.initState();
    // Load currently active modules so if opened from Settings, it shows correct state
    final active = ModuleConfigService().activeModules;
    if (active.isNotEmpty) {
      _selectedModules = List.from(active);
    }
  }

  final List<Map<String, dynamic>> _modules = [
    {"id": "accounting", "name": "برنامج الحسابات الشامل", "icon": Icons.account_balance_wallet, "color": Colors.blue, "desc": "المركز المالي، القيود، والأستاذ العام"},
    {"id": "invoices", "name": "المبيعات والفواتير", "icon": Icons.receipt_long, "color": Colors.green, "desc": "إصدار الفواتير وعروض الأسعار"},
    {"id": "hr", "name": "شؤون الموظفين (HR)", "icon": Icons.people, "color": Colors.teal, "desc": "الرواتب، الإجازات، والعهد"},
    {"id": "inventory", "name": "إدارة المخازن", "icon": Icons.inventory_2, "color": Colors.brown, "desc": "الفروع، الجرد، والأصناف"},
    {"id": "taxes", "name": "برنامج الضريبة", "icon": Icons.percent, "color": Colors.orange, "desc": "الإقرارات لجميع الدول"},
    {"id": "auditing", "name": "تدقيق الحسابات", "icon": Icons.fact_check, "color": Colors.cyan, "desc": "مراجعة واعتماد القيود"},
    {"id": "feasibility", "name": "دراسات الجدوى", "icon": Icons.trending_up, "color": Colors.purple, "desc": "تخطيط المشاريع الجديدة"},
    {"id": "assets", "name": "إدارة العدد والأدوات", "icon": Icons.handyman, "color": Colors.blueGrey, "desc": "الأصول، التالف، والباركود", "isNew": true},
    {"id": "purchases", "name": "إدارة المشتريات", "icon": Icons.shopping_cart, "color": Colors.pink, "desc": "الموردين وأوامر الشراء", "isNew": true},
    {"id": "maintenance", "name": "الصيانة الشاملة", "icon": Icons.build_circle, "color": Colors.red, "desc": "معدات، سيارات، وشاحنات", "isNew": true},
    {"id": "sales_commissions", "name": "المناديب والعمولات", "icon": Icons.assignment_ind, "color": Colors.blue, "desc": "تتبع المبيعات والتاجت", "isNew": true},
    {"id": "expiry", "name": "رقابة الصلاحية", "icon": Icons.history_toggle_off, "color": Colors.orange, "desc": "مراقبة تواريخ انتهاء البضائع", "isNew": true},
    {"id": "trial_balance", "name": "ميزان المراجعة", "icon": Icons.analytics, "color": Colors.indigo, "desc": "كشف الأرصدة والمجاميع", "isNew": true},
    {"id": "financial_reports", "name": "التقارير المالية الختامية", "icon": Icons.bar_chart, "color": Colors.deepOrange, "desc": "الأرباح والخسائر والمركز المالي"},
    {"id": "real_estate", "name": "إدارة العقارات", "icon": Icons.apartment, "color": Colors.amber, "desc": "الوحدات، وعقود الإيجار", "isNew": true},
    {"id": "chat", "name": "التواصل الداخلي والمهام", "icon": Icons.forum, "color": Colors.deepPurpleAccent, "desc": "شات، قنوات، وتحويل لمهمة", "isNew": true},
    {"id": "hub_commercial", "name": "المحور التجاري", "icon": Icons.storefront, "color": Colors.teal, "desc": "العروض الترويجية ونقاط البيع", "isNew": true},
    {"id": "cloud_inbox", "name": "الوارد السحابي", "icon": Icons.cloud_queue, "color": Colors.lightBlue, "desc": "استلام الفواتير تلقائياً", "isNew": true},
    {"id": "budgeting", "name": "إعداد الميزانية", "icon": Icons.pie_chart, "color": Colors.indigo, "desc": "رصد وتخطيط الموازنات"},
  ];

  void _toggleModule(String id) {
    setState(() {
      if (_selectedModules.contains(id)) {
        if (id != 'accounting') { // Prevent removing core
          _selectedModules.remove(id);
        }
      } else {
        _selectedModules.add(id);
      }
    });
  }

  void _completeSetup() async {
    await ModuleConfigService().saveModules(_selectedModules);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSurface,
      body: Stack(
        children: [
          // Background graphic
          Positioned(
             top: -100, right: -100,
             child: Container(
               width: 400, height: 400, 
               decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [primaryOrange.withOpacity(0.2), Colors.transparent]))
             ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 32
                  child: Column(
                    children: [
                      Icon(Icons.apps, size: context.iconSize + 12, color: primaryOrange), // 📉 Reduced from 48
                      const SizedBox(height: 12), // 📉 Reduced from 16
                      Text("تخصيص مساحة العمل", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 28
                      const SizedBox(height: 4), // 📉 Reduced from 8
                      Text(
                        "اختر البرامج والوحدات التي تحتاجها منشأتك", // 📉 Shortened
                        style: TextStyle(fontSize: context.bodySize, color: context.mutedText), // 📉 Reduced from 14
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 4), // 📉 Reduced from 24/8
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300, // 📉 Reduced from 350
                      childAspectRatio: 2.8, // 📉 Slimmer from 2.2
                      crossAxisSpacing: 12, // 📉 Reduced from 16
                      mainAxisSpacing: 12, // 📉 Reduced from 16
                    ),
                    itemCount: _modules.length,
                    itemBuilder: (context, index) {
                      final module = _modules[index];
                      final isSelected = _selectedModules.contains(module['id']);
                      final isNew = module['isNew'] == true;
                      
                      return GestureDetector(
                        onTap: () => _toggleModule(module['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? module['color'].withValues(alpha: 0.15) 
                                : context.cardSurface,
                            borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 20
                            border: Border.all(
                              color: isSelected 
                                  ? module['color'] 
                                  : context.cardBorder.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8), // 📉 Reduced from 12
                                decoration: BoxDecoration(
                                  color: isSelected ? module['color'] : Colors.black12,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  module['icon'], 
                                  color: isSelected ? Colors.white : context.mutedText,
                                  size: context.iconSize, // 📉 Added size
                                ),
                              ),
                              const SizedBox(width: 12), // 📉 Reduced from 16
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            module['name'], 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              color: isSelected ? context.textColor : context.mutedText,
                                              fontSize: context.bodySize, // 📉 Reduced from 14
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isNew) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(100)),
                                            child: const Text("جديد", style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                                          )
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 2), // 📉 Reduced from 4
                                    Text(
                                      module['desc'], 
                                      style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), // 📉 Reduced from 11
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: module['color'], size: context.iconSize), // 📉 Added size
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12), // 📉 Reduced from 24
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    border: Border(top: BorderSide(color: context.cardBorder.withValues(alpha: 0.5))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "الأنظمة: ${_selectedModules.length}", // 📉 Shortened
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize), // 📉 Reduced from 16
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 📉 Reduced from 32/18
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 16
                          elevation: 0,
                        ),
                        child: Text("اعتماد وبدء العمل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)), // 📉 Reduced from 16
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
