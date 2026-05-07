import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'warehouse_management_screen.dart';
import 'inter_warehouse_transfer_screen.dart';
import '../widgets/glass_container.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, low, out
  String _currency = 'sar';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContext();
    _loadItems();
  }

  Future<void> _loadContext() async {
    final ctx = await _db.getCurrentCompanyContext();
    if (mounted) setState(() => _currency = ctx['currency'] ?? 'sar');
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final res = await _db.getProducts();
      if (mounted) setState(() { _items = res; _applyFilter(); _isLoading = false; });
    } catch (e) {
      debugPrint("Inventory load error: $e");
      if (mounted) setState(() { _items = []; _filtered = []; _isLoading = false; });
    }
  }

  void _applyFilter() {
    var list = _items.where((i) {
      final name = i['name']?.toString().toLowerCase() ?? '';
      final sku = i['sku']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || sku.contains(_searchQuery.toLowerCase());
    }).toList();

    if (_filterType == 'low') {
      list = list.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) > 0 && ((i['quantity'] as num?)?.toDouble() ?? 0) <= 5).toList();
    } else if (_filterType == 'out') {
      list = list.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) <= 0).toList();
    }
    _filtered = list;
  }

  void _showItemDialog({Map<String, dynamic>? item}) {
    final bool isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name']?.toString());
    final priceCtrl = TextEditingController(text: item?['base_price']?.toString());
    final costCtrl = TextEditingController(text: item?['cost_price']?.toString());
    final qtyCtrl = TextEditingController(text: (item?['quantity'] ?? 0).toString());
    final skuCtrl = TextEditingController(text: item?['sku']?.toString());
    final minQtyCtrl = TextEditingController(text: (item?['min_quantity'] ?? 5).toString());
    final categoryCtrl = TextEditingController(text: item?['category']?.toString());
    final expiryCtrl = TextEditingController(text: item?['expiry_date']?.toString());

    showDialog(context: context, builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: AlertDialog(
        backgroundColor: context.cardSurface.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            isEdit ? tr('inventory_module.edit_item_dialog') : tr('inventory_module.add_new_item'), 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
          )
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              _dialogField(nameCtrl, tr('inventory_module.name_label')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dialogField(skuCtrl, tr('inventory_module.barcode'))),
                const SizedBox(width: 10),
                Expanded(child: _dialogField(categoryCtrl, tr('inventory_module.category'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dialogField(priceCtrl, tr('inventory_module.sale_price'), isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _dialogField(costCtrl, tr('inventory_module.cost_label'), isNum: true)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dialogField(qtyCtrl, tr('inventory_module.available_qty'), isNum: true)),
                const SizedBox(width: 10),
                Expanded(child: _dialogField(minQtyCtrl, tr('inventory_module.min_limit_label'), isNum: true)),
              ]),
              const SizedBox(height: 10),
              _dialogField(
                expiryCtrl, 
                'تاريخ الصلاحية (اختياري)', 
                readOnly: true, 
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) {
                    expiryCtrl.text = picked.toIso8601String().split('T')[0];
                  }
                }
              ),
            ]
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          if (isEdit) IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await _db.deleteProduct(item!['id']);
              Navigator.pop(ctx); _loadItems();
            }
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final data = {
                'name': nameCtrl.text,
                'sku': skuCtrl.text.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : skuCtrl.text,
                'base_price': double.tryParse(priceCtrl.text) ?? 0.0,
                'cost_price': double.tryParse(costCtrl.text) ?? 0.0,
                'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                'min_stock_level': double.tryParse(minQtyCtrl.text) ?? 5.0,
                'industry_type': categoryCtrl.text,
                'expiry_date': expiryCtrl.text,
              };
              if (isEdit) { data['id'] = item!['id']; await _db.updateProduct(data); }
              else { data['id'] = 'ITM_${DateTime.now().millisecondsSinceEpoch}'; await _db.insertProduct(data); }
              Navigator.pop(ctx); _loadItems();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white),
            child: Text(tr('common.save')),
          )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _items.fold<double>(0, (s, i) => s + ((i['base_price'] as num?)?.toDouble() ?? 0) * ((i['quantity'] as num?)?.toDouble() ?? 0));
    final lowStock = _items.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) > 0 && ((i['quantity'] as num?)?.toDouble() ?? 0) <= 5).length;
    final outOfStock = _items.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) <= 0).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                style: IconButton.styleFrom(backgroundColor: context.cardSurface.withValues(alpha: 0.5)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tr('inventory_module.title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("${_items.length} ${tr('inventory_module.item_count')}", style: TextStyle(color: context.mutedText, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildStatsRow(totalValue, lowStock, outOfStock),
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) => _buildProductCard(_filtered[i]),
              ),
        ),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _actionBtn(Icons.swap_horiz, "تحويل مخزني", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterWarehouseTransferScreen()))),
          const SizedBox(width: 12),
          _actionBtn(Icons.warehouse_outlined, "إدارة المخازن", Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseManagementScreen()))),
          const SizedBox(width: 12),
          _actionBtn(Icons.add_box_outlined, "صنف جديد", primaryOrange, () => _showItemDialog()),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(double totalValue, int low, int out) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _miniStat("قيمة المخزون", "${totalValue.toStringAsFixed(0)}", Colors.blue),
          const SizedBox(width: 12),
          _miniStat("نقص مخزون", "$low", Colors.orange),
          const SizedBox(width: 12),
          _miniStat("نفاد كمية", "$out", Colors.red),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label, style: TextStyle(color: context.mutedText, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() { _searchQuery = v; _applyFilter(); }),
              decoration: InputDecoration(
                hintText: tr('inventory_module.search_hint'),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: context.cardSurface.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _filterChip("الكل", "all"),
          const SizedBox(width: 8),
          _filterChip("نقص", "low"),
          const SizedBox(width: 8),
          _filterChip("نفاد", "out"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    final sel = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() { _filterType = type; _applyFilter(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? primaryOrange : context.cardSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : context.mutedText, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
    final isLow = qty > 0 && qty <= 5;
    final isOut = qty <= 0;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: (isOut ? Colors.red : isLow ? Colors.orange : primaryOrange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(
              isOut ? Icons.warning_amber_rounded : isLow ? Icons.hourglass_bottom : Icons.inventory_2_outlined,
              color: isOut ? Colors.red : isLow ? Colors.orange : primaryOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("SKU: ${item['sku'] ?? 'N/A'}", style: TextStyle(color: context.mutedText, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${qty.toStringAsFixed(0)} وحدة", style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOut ? Colors.red : isLow ? Colors.orange : context.textColor
              )),
              Text("${item['base_price'] ?? 0} SAR", style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showItemDialog(item: item),
            icon: const Icon(Icons.edit_note, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, {bool isNum = false, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: context.bgSurface.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
