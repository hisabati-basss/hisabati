import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/industry_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme_extension.dart';
import '../core/config/module_definitions.dart';
import 'package:easy_localization/easy_localization.dart';

class HubScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const HubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    final isDark = context.isDark;
    final perm = PermissionService();

    // Grouping logic
    Map<ModuleCategory, List<ModuleDef>> grouped = {};
    for (var mod in AppModules.allModules) {
      // Only show top-level modules (respecting showInSidebar) to avoid HR duplication
      if (mod.showInSidebar && perm.isVisible(mod.id)) {
        grouped.putIfAbsent(mod.category, () => []).add(mod);
      }
    }

    final categoryNames = {
      ModuleCategory.core: 'الأنظمة الرئيسية والأساسية',
      ModuleCategory.finance: 'المالية والمحاسبة المتقدمة',
      ModuleCategory.support: 'الدعم الفني والرقابة الإدارية',
      ModuleCategory.hr: 'الموارد البشرية وشؤون الموظفين',
      ModuleCategory.operations: 'العمليات والتجارة وسلاسل الإمداد',
      ModuleCategory.entities: 'القطاعات والكيانات التجارية',
      ModuleCategory.industries: 'القطاعات المتخصصة والخدمات',
      ModuleCategory.extensions: 'الإضافات الذكية والذكاء الاصطناعي',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: _buildHeader(context, isMobile),
            ),
          ),
          ...categoryNames.keys.map((cat) {
            final mods = grouped[cat];
            if (mods == null || mods.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryNames[cat]!,
                      style: TextStyle(
                        color: context.primaryOrange.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isMobile ? 2.2 : 2.5,
                      ),
                      itemCount: mods.length,
                      itemBuilder: (ctx, i) => _buildHubTile(context, mods[i]),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Enterprise Control Center",
            style: TextStyle(color: context.primaryOrange, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "جميع تطبيقات Hisabati ERP",
          style: TextStyle(
            color: context.textColor,
            fontSize: isMobile ? 20 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "الوصول السريع لجميع الوحدات الـ ${AppModules.allModules.length} في مكان واحد",
          style: TextStyle(color: context.mutedText, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHubTile(BuildContext context, ModuleDef module) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => onNavigate(module.index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(module.icon, color: module.color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.localizedName,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_left, size: 14, color: context.mutedText.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
