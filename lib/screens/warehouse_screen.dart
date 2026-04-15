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
    await _dbHelper.seedDemoProducts(); 
    final items = await _dbHelper.getItems();
    
    Map<String, Map<String, dynamic>> analytics = {};
    for (var item in items) {
      analytics[item['id']] = await _dbHelper.getItemPredictiveAnalytics(item['id']);
    }

    if (mounted) {
      setState(() {
        _items = items;
        _analytics = analytics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));

    double totalValue = _items.fold(0, (sum, item) => sum + ((item['quantity'] as num) * (item['cost_price'] as num)));
    int criticalCount = _analytics.values.where((a) => a['is_critical'] == true).length;

    return Padding(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('warehouse.subtitle'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)), // 📉 Reduced from 13
          const SizedBox(height: 2), // 📉 Reduced from 4
          Text(tr('warehouse.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)), 
          const SizedBox(height: 12), // 📉 Reduced from 16/32

          // HUD Stats
          Row(
            children: [
              Expanded(child: _buildHudCard(tr('warehouse.inventory_value'), "${totalValue.toStringAsFixed(0)} ${tr('common.currency_symbol')}", Icons.inventory_2, Colors.blueAccent)), // 📉 Shortened
              const SizedBox(width: 8), // 📉 Reduced from 16
              Expanded(child: _buildHudCard(tr('warehouse.critical_items'), "$criticalCount", Icons.warning_amber_rounded, Colors.redAccent)), 
            ],
          ),

          const SizedBox(height: 12), // 📉 Reduced from 16/32

          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final analytic = _analytics[item['id']] ?? {};
                final double daysRemaining = analytic['days_remaining'] ?? 0;
                final bool isCritical = analytic['is_critical'] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8), // 📉 Reduced from 12
                  child: GlassContainer(
                    padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
                    borderRadius: context.cardRadius, // 📉 Reduced from 20
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40, // 📉 Reduced from 50
                          decoration: BoxDecoration(color: isCritical ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), // 📉 Reduced from 12
                          child: Icon(Icons.shopping_bag_outlined, color: isCritical ? Colors.redAccent : primaryOrange, size: context.iconSize), // 📉 Reduced
                        ),
                        const SizedBox(width: 12), // 📉 Reduced from 16
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)), // 📉 Reduced from 16
                              Text("الكمية: ${item['quantity']} | ADS: ${(analytic['ads'] ?? 0.0).toStringAsFixed(1)}", style: TextStyle(color: Colors.white38, fontSize: context.bodySize - 1)), // 📉 Reduced from 12
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
