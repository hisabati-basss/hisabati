import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import '../widgets/glass_container.dart';
import 'inter_warehouse_transfer_screen.dart';
import 'warehouse_management_screen.dart';

class WarehouseScreen extends StatefulWidget {
  final bool isMobile;
  const WarehouseScreen({super.key, this.isMobile = false});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;
  List<Map<String, dynamic>> _items = [];
  Map<String, Map<String, dynamic>> _analytics = {};
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final items = await _dbHelper.getProducts();
      final warehouses = await _dbHelper.getWarehouses();
      Map<String, Map<String, dynamic>> analytics = {};
      for (var item in items.take(15)) {
        final itemId = item['id']?.toString() ?? '';
        if (itemId.isNotEmpty) {
          analytics[itemId] = await _dbHelper.getItemPredictiveAnalytics(itemId);
        }
      }
      if (mounted) {
        setState(() {
          _items = items;
          _analytics = analytics;
          _warehouses = warehouses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorder),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnalysisTab(),
                      _buildWarehousesTab(),
                      _buildTransfersTab(),
                    ],
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    if (_tabController.index == 0) return null;
    
    String label = "inventory_module.new_warehouse".tr();
    IconData icon = Icons.add_business_outlined;
    VoidCallback onPressed = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseManagementScreen())).then((_) => _loadData());

    if (_tabController.index == 2) {
      label = "تحويل جديد";
      icon = Icons.swap_horiz_rounded;
      onPressed = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterWarehouseTransferScreen())).then((_) => _loadData());
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: primaryOrange,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.textColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('sidebar.warehouses'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('إدارة ذكية لمواقع التخزين', style: TextStyle(color: context.mutedText, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh, color: primaryOrange)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    double totalValue = _items.fold<double>(0.0, (sum, item) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final cost = (item['cost_price'] as num?)?.toDouble() ?? 0.0;
      return sum + (qty * cost);
    });
    int criticalCount = _analytics.values.where((a) => a['is_critical'] == true).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildKPI('قيمة المخزون', "${totalValue.toStringAsFixed(0)}", Colors.blue),
          const SizedBox(width: 12),
          _buildKPI('أصناف حرجة', "$criticalCount", Colors.red),
          const SizedBox(width: 12),
          _buildKPI("المستودعات", "${_warehouses.length}", Colors.green),
        ],
      ),
    );
  }

  Widget _buildKPI(String label, String value, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label, style: TextStyle(color: context.mutedText, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: context.mutedText,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: "warehouse.analysis".tr()),
          Tab(text: "warehouse.management".tr()),
          Tab(text: "warehouse.transfers".tr()),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_items.isEmpty) return _emptyState("لا توجد أصناف مسجلة حالياً");
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _items.length,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 30,
            child: FadeInAnimation(child: _buildAnalysisCard(_items[index])),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> item) {
    final String itemId = item['id']?.toString() ?? '';
    final analytic = _analytics[itemId] ?? {};
    final double daysRemaining = analytic['days_remaining'] ?? 0.0;
    final bool isCritical = analytic['is_critical'] ?? false;
    final String itemName = item['name']?.toString() ?? 'صنف غير معروف';
    final double itemQty = (item['quantity'] as num?)?.toDouble() ?? 0.0;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isCritical ? Colors.red : Colors.green).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical ? Icons.priority_high_rounded : Icons.check_circle_outline_rounded, 
              color: isCritical ? Colors.red : Colors.green, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("المخزون: $itemQty", style: TextStyle(color: context.mutedText, fontSize: 10)),
                    const SizedBox(width: 12),
                    Text("معدل البيع: ${(analytic['ads'] ?? 0.0).toStringAsFixed(1)}/يوم", style: TextStyle(color: context.mutedText, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysRemaining == double.infinity ? "كافي" : "باقي ${daysRemaining.toStringAsFixed(0)} يوم",
                style: TextStyle(color: isCritical ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (daysRemaining / 30).clamp(0, 1),
                    backgroundColor: context.bgSurface.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(isCritical ? Colors.red : Colors.green),
                    minHeight: 4,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehousesTab() {
    if (_warehouses.isEmpty) return _emptyState("لا توجد مستودعات مسجلة");
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _warehouses.length,
      itemBuilder: (context, index) {
        final w = _warehouses[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.warehouse_outlined, color: Colors.blue),
            title: Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(w['location'] ?? 'موقع غير محدد', style: TextStyle(fontSize: 12, color: context.mutedText)),
            trailing: const Icon(Icons.chevron_left, color: primaryOrange),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseManagementScreen())).then((_) => _loadData()),
          ),
        );
      },
    );
  }

  Widget _buildTransfersTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text("warehouse.transfers".tr(), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text("يمكنك إدارة تحويل البضائع بين المستودعات هنا", style: TextStyle(color: context.mutedText, fontSize: 12)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterWarehouseTransferScreen())).then((_) => _loadData()),
          icon: const Icon(Icons.add, size: 18),
          label: Text("warehouse.new_transfer".tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: context.mutedText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
