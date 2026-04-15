import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/commercial_service.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class CommercialHubScreen extends StatefulWidget {
  final bool isMobile;
  const CommercialHubScreen({super.key, this.isMobile = false});

  @override
  State<CommercialHubScreen> createState() => _CommercialHubScreenState();
}

class _CommercialHubScreenState extends State<CommercialHubScreen> with SingleTickerProviderStateMixin {
  final CommercialService _commercialService = CommercialService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _targets = [];
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _slowStock = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final targets = await _commercialService.getTargets();
    final promos = await _commercialService.getPromotions();
    final slow = await _commercialService.getSlowMovingStock();
    setState(() {
      _targets = targets;
      _promotions = promos;
      _slowStock = slow;
      _isLoading = false;
    });
  }

  void _showAddPromotionDialog() async {
    final products = await _dbHelper.getProducts();
    if (!mounted) return;

    String? selectedItemId;
    String selectedItemName = '';
    String discountType = 'percentage';
    final discountController = TextEditingController(text: '15');
    final daysController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
          title: Text(tr('commercial.new_promotion'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product picker
                Text(tr('commercial.select_product'), style: TextStyle(color: context.mutedText, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedItemId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: context.bgSurface,
                  hint: Text(tr('commercial.choose_product')),
                  items: products.map((p) => DropdownMenuItem(
                    value: p['id']?.toString(),
                    child: Text("${p['name']} (${tr('commercial.qty')}: ${p['quantity'] ?? 0})"),
                  )).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedItemId = val;
                      selectedItemName = products.firstWhere((p) => p['id']?.toString() == val)['name'] ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Discount type
                Text(tr('commercial.discount_type'), style: TextStyle(color: context.mutedText, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => discountType = 'percentage'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: discountType == 'percentage' ? primaryOrange.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: discountType == 'percentage' ? primaryOrange : Colors.white24),
                          ),
                          child: Center(child: Text(tr('commercial.percentage'), style: TextStyle(fontWeight: FontWeight.bold, color: discountType == 'percentage' ? primaryOrange : null))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => discountType = 'fixed'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: discountType == 'fixed' ? primaryOrange.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: discountType == 'fixed' ? primaryOrange : Colors.white24),
                          ),
                          child: Center(child: Text(tr('commercial.fixed_amount'), style: TextStyle(fontWeight: FontWeight.bold, color: discountType == 'fixed' ? primaryOrange : null))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Discount value
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: discountType == 'percentage' ? tr('commercial.discount_percent') : tr('commercial.discount_value'),
                    suffixText: discountType == 'percentage' ? '%' : tr('onboarding.currency_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                // Campaign duration
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tr('commercial.campaign_days'),
                    suffixText: tr('commercial.days'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton.icon(
              onPressed: () async {
                if (selectedItemId == null) return;
                final discountValue = double.tryParse(discountController.text) ?? 0;
                final days = int.tryParse(daysController.text) ?? 30;
                if (discountValue <= 0) return;

                final now = DateTime.now();
                await _commercialService.addPromotion(
                  selectedItemId!,
                  discountType,
                  discountValue,
                  now,
                  now.add(Duration(days: days)),
                );
                Navigator.pop(ctx);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('commercial.promo_created')), backgroundColor: Colors.green),
                  );
                }
              },
              icon: const Icon(Icons.check, color: Colors.black),
              label: Text(tr('commercial.create_promo'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTargetDialog() async {
    final db = await _dbHelper.database;
    final employees = await db.query('employees');
    if (!mounted) return;

    String? selectedEmployeeId;
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
          title: Text(tr('commercial.new_target'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: tr('commercial.select_employee'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: context.bgSurface,
                items: employees.map((e) => DropdownMenuItem(
                  value: e['id']?.toString(),
                  child: Text(e['name']?.toString() ?? ''),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedEmployeeId = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('commercial.target_amount'),
                  suffixText: tr('onboarding.currency_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton.icon(
              onPressed: () async {
                if (selectedEmployeeId == null) return;
                final target = double.tryParse(targetController.text) ?? 0;
                if (target <= 0) return;

                await _commercialService.addTarget(
                  selectedEmployeeId!,
                  target,
                  DateTime.now(),
                  DateTime.now().add(const Duration(days: 30)),
                );
                Navigator.pop(ctx);
                _loadData();
              },
              icon: const Icon(Icons.check, color: Colors.black),
              label: Text(tr('commercial.save_target'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(context.sectionPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('commercial.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                    Text(tr('commercial.subtitle'), style: TextStyle(fontSize: context.bodySize, color: context.mutedText)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_tabController.index == 0) {
                      _showAddTargetDialog();
                    } else if (_tabController.index == 1) {
                      _showAddPromotionDialog();
                    }
                  },
                  icon: Icon(_tabController.index == 2 ? Icons.refresh : Icons.add, color: Colors.black),
                  label: Text(
                    _tabController.index == 0 ? tr('commercial.new_target') 
                      : _tabController.index == 1 ? tr('commercial.new_promotion')
                      : tr('commercial.refresh'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                )
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(context.cardRadius),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: primaryOrange,
                labelColor: primaryOrange,
                unselectedLabelColor: context.mutedText,
                onTap: (index) => setState((){}),
                tabs: [
                  Tab(icon: const Icon(Icons.track_changes), text: tr('commercial.tab_targets')),
                  Tab(icon: const Icon(Icons.local_offer), text: tr('commercial.tab_promotions')),
                  Tab(icon: const Icon(Icons.inventory_2_outlined), text: tr('commercial.tab_slow_stock')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                  : TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildTargetsTab(),
                        _buildPromotionsTab(),
                        _buildSlowStockTab(),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsTab() {
    if (_targets.isEmpty) {
      return Center(child: Text(tr('commercial.empty_targets'), style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: _targets.length,
      itemBuilder: (ctx, i) {
        final target = _targets[i];
        final targetAmount = (target['target_amount'] as num?)?.toDouble() ?? 0;
        final achievedAmount = (target['achieved_amount'] as num?)?.toDouble() ?? 0;
        final progress = targetAmount > 0 ? (achievedAmount / targetAmount) * 100 : 0.0;
        return Card(
          color: context.cardSurface,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.cardRadius),
              side: BorderSide(color: context.cardBorder.withValues(alpha: 0.3))),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
            title: Text(tr('commercial.employee_label', args: ["Sales Unit", target['employee_id'].toString()]), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('commercial.target_amount', args: [targetAmount.toStringAsFixed(0), achievedAmount.toStringAsFixed(0)])),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (progress.isNaN || progress.isInfinite) ? 0 : progress / 100,
                  backgroundColor: Colors.white12,
                  color: progress >= 100 ? Colors.green : primaryOrange,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotionsTab() {
    if (_promotions.isEmpty) {
      return Center(child: Text(tr('commercial.empty_promotions'), style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: _promotions.length,
      itemBuilder: (ctx, i) {
        final promo = _promotions[i];
        return Card(
          color: context.cardSurface,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.cardRadius),
              side: BorderSide(color: context.cardBorder.withValues(alpha: 0.3))),
          child: ListTile(
            leading: const Icon(Icons.discount, color: Colors.greenAccent, size: 30),
            title: Text(tr('commercial.promo_discount', args: [promo['item_id'].toString()]), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tr('commercial.promo_value', args: [promo['discount_value'].toString(), promo['discount_type']])),
            trailing: Switch(
              value: promo['is_active'] == 1,
              onChanged: (v) async {
                await _commercialService.togglePromotion(promo['id'], v);
                _loadData();
              },
              activeColor: primaryOrange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlowStockTab() {
    if (_slowStock.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
            const SizedBox(height: 12),
            Text(tr('commercial.no_slow_stock'), style: const TextStyle(color: Colors.white54, fontSize: 16)),
            Text(tr('commercial.all_products_moving'), style: TextStyle(color: context.mutedText, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _slowStock.length,
      itemBuilder: (ctx, i) {
        final item = _slowStock[i];
        return Card(
          color: context.cardSurface,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.cardRadius),
              side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3))),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            ),
            title: Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${tr('commercial.qty')}: ${item['quantity']} • ${tr('commercial.last_sold')}: ${item['last_sold_date'] ?? '-'}", style: TextStyle(color: context.mutedText, fontSize: 12)),
            trailing: ElevatedButton(
              onPressed: () {
                // Quick create promotion for this slow item
                _quickCreatePromotion(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange.withValues(alpha: 0.2),
                foregroundColor: primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(tr('commercial.create_offer'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _quickCreatePromotion(Map<String, dynamic> item) async {
    final discountController = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text("${tr('commercial.quick_promo')}: ${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: tr('commercial.discount_percent'),
            suffixText: '%',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              final discount = double.tryParse(discountController.text) ?? 20;
              await _dbHelper.createExpiryPromotion(
                itemId: item['id']?.toString() ?? '',
                discountPercent: discount,
                campaignDays: 30,
              );
              Navigator.pop(ctx);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('commercial.promo_created')), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: Text(tr('commercial.create_promo'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
