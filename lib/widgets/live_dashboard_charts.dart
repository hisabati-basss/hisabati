import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class MinimalistDashboardWidget extends StatefulWidget {
  final bool isMobile;
  const MinimalistDashboardWidget({super.key, this.isMobile = false});

  @override
  State<MinimalistDashboardWidget> createState() => _MinimalistDashboardWidgetState();
}

class _MinimalistDashboardWidgetState extends State<MinimalistDashboardWidget> {
  Map<String, double> _stats = {'sales': 0, 'cash': 0, 'expenses': 0, 'net_profit': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    final stats = await db.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryOrange));
    }

    // Grid config
    int crossAxisCount = widget.isMobile ? 1 : 2;
    double childAspectRatio = widget.isMobile ? 2.5 : 2.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "الملخص المالي",
            style: TextStyle(
              color: context.textColor,
              fontSize: context.headerSize, // 📉 Reduced from 28
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "مؤشرات الأداء الرئيسية (KPIs)",
            style: TextStyle(
              color: context.mutedText,
              fontSize: context.bodySize, // 📉 Reduced from 14
            ),
          ),
          const SizedBox(height: 16), // 📉 Reduced from 32
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              children: [
                _buildKpiCard(
                  title: "صندوق النقدية",
                  value: _stats['cash'] ?? 0,
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.greenAccent.shade400,
                  context: context,
                ),
                _buildKpiCard(
                  title: "إجمالي المبيعات",
                  value: _stats['sales'] ?? 0,
                  icon: Icons.trending_up_rounded,
                  color: primaryOrange,
                  context: context,
                ),
                _buildKpiCard(
                  title: "المصروفات التشغيلية",
                  value: _stats['expenses'] ?? 0,
                  icon: Icons.money_off_rounded,
                  color: Colors.redAccent.shade400,
                  context: context,
                ),
                _buildKpiCard(
                  title: "صافي الربح",
                  value: _stats['net_profit'] ?? 0,
                  icon: Icons.auto_graph_rounded,
                  color: Colors.blueAccent.shade400,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, _) {
       return ValueListenableBuilder<bool>(
         valueListenable: perfShowShadows,
         builder: (context, showShadows, _) {
           final double blur = showBlur ? 10 : 0;
           return Container(
             decoration: BoxDecoration(
               color: context.cardSurface,
               borderRadius: BorderRadius.circular(context.cardRadius),
               border: Border.all(color: context.cardBorder, width: 1),
               boxShadow: !showShadows ? [] : [
                 BoxShadow(
                   color: color.withValues(alpha: 0.1),
                   blurRadius: 20,
                   offset: const Offset(0, 6),
                 ),
               ],
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(context.cardRadius),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                 child: Padding(
                   padding: EdgeInsets.all(context.cardPadding),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: color.withValues(alpha: 0.15),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(icon, color: color, size: 28),
                       ),
                       const SizedBox(width: 14),
                       Expanded(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               title,
                               style: TextStyle(
                                 color: context.mutedText,
                                 fontSize: 16,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                             const SizedBox(height: 8),
                             ValueListenableBuilder<bool>(
                               valueListenable: perfShowAnimations,
                               builder: (context, showAnim, child) {
                                  if (!showAnim) {
                                    return Text(
                                      "${value.toStringAsFixed(2)} ر.س",
                                      style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold), // 📉 Reduced from 32
                                    );
                                  }
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: value),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeOutExpo,
                                    builder: (context, currentValue, child) {
                                      return Text(
                                        "${currentValue.toStringAsFixed(2)} ر.س",
                                        style: TextStyle(
                                          color: context.textColor,
                                          fontSize: 18, // 📉 Reduced from 32
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      );
                                    },
                                  );
                               }
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           );
         }
       );
      }
    );
  }
}
