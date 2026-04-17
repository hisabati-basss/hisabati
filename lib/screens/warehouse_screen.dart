import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme_extension.dart';

class WarehouseScreen extends StatefulWidget {
  final bool isMobile;
  const WarehouseScreen({super.key, this.isMobile = false});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _items = [];
  Map<String, Map<String, dynamic>> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _dbHelper.getItems();
      
      Map<String, Map<String, dynamic>> analytics = {};
      for (var item in items) {
        final itemId = item['id']?.toString() ?? '';
        if (itemId.isNotEmpty) {
          analytics[itemId] = await _dbHelper.getItemPredictiveAnalytics(itemId);
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات المستودع: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));

    double totalValue = _items.fold(0, (sum, item) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final cost = (item['cost_price'] as num?)?.toDouble() ?? 0.0;
      return sum + (qty * cost);
    });
    int criticalCount = _analytics.values.where((a) => a['is_critical'] == true).length;

    return Padding(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('warehouse.subtitle'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
          const SizedBox(height: 2),
          Text(tr('warehouse.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
          const SizedBox(height: 12),

          // HUD Stats
          Row(
            children: [
              Expanded(child: _buildHudCard(tr('warehouse.inventory_value'), "${totalValue.toStringAsFixed(0)} ${tr('common.currency_symbol')}", Icons.inventory_2, Colors.blueAccent)),
              const SizedBox(width: 8),
              Expanded(child: _buildHudCard(tr('warehouse.critical_items'), "$criticalCount", Icons.warning_amber_rounded, Colors.redAccent)),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final String itemId = item['id']?.toString() ?? '';
                if (itemId.isEmpty) return const SizedBox.shrink();

                final analytic = _analytics[itemId] ?? {};
                final double daysRemaining = analytic['days_remaining'] ?? 0.0;
                final bool isCritical = analytic['is_critical'] ?? false;
                final String itemName = item['name']?.toString() ?? 'صنف غير معروف';
                final double itemQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    padding: EdgeInsets.all(context.cardPadding),
                    borderRadius: context.cardRadius,
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: isCritical ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.shopping_bag_outlined, color: isCritical ? Colors.redAccent : primaryOrange, size: context.iconSize),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                              Text("الكمية: $itemQty | ADS: ${(analytic['ads'] ?? 0.0).toStringAsFixed(1)}", style: TextStyle(color: Colors.white38, fontSize: context.bodySize - 1)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              daysRemaining == double.infinity ? "صفر" : "باقي ${daysRemaining.toStringAsFixed(0)}ي", // 📉 Shortened
                              style: TextStyle(color: isCritical ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: context.bodySize), // 📉 Reduced from 14
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: (daysRemaining / 30).clamp(0, 1),
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(isCritical ? Colors.redAccent : Colors.greenAccent),
                                minHeight: 3,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudCard(String title, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 20
      borderRadius: context.cardRadius, // 📉 Reduced from 24
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: context.iconSize), // 📉 Reduced from 28
          const SizedBox(height: 4), // 📉 Reduced from 8/16
          Text(title, style: TextStyle(color: Colors.white54, fontSize: context.bodySize - 2)), // 📉 Reduced from 12
          Text(value, style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 22/headerSize+2
        ],
      ),
    );
  }
}
