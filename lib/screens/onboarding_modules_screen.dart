import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/module_config_service.dart';
import '../theme/app_theme_extension.dart';
import '../core/config/module_definitions.dart';

class OnboardingModulesScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingModulesScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingModulesScreen> createState() => _OnboardingModulesScreenState();
}

class _OnboardingModulesScreenState extends State<OnboardingModulesScreen> {
  List<String> _selectedModules = ['accounting']; // Default to accounting

  late final List<Map<String, dynamic>> _modules;

  @override
  void initState() {
    super.initState();
    // Load currently active modules so if opened from Settings, it shows correct state
    final active = ModuleConfigService().activeModules;
    if (active.isNotEmpty) {
      _selectedModules = List.from(active);
    }
    _modules = AppModules.allModules
        .where((def) => def.showInSidebar)
        .map((def) => {
      "id": def.id,
      "name": def.localizedName,
      "icon": def.icon,
      "color": def.color,
      "desc": def.localizedDescription,
      "isNew": def.isNew,
    }).toList();
  }

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
               decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [primaryOrange.withValues(alpha: 0.2), Colors.transparent]))
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
