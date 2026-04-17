import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import 'package:easy_localization/easy_localization.dart';

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
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: context.obsidianGlass,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.cardBorder, width: 1.5)),
        title: Text(isEdit ? tr('inventory_module.edit_item_dialog') : tr('inventory_module.add_new_item'), style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(nameCtrl, tr('inventory_module.name_label')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(skuCtrl, tr('inventory_module.barcode'))),
            const SizedBox(width: 8),
            Expanded(child: _dialogField(categoryCtrl, tr('inventory_module.category'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(priceCtrl, tr('inventory_module.sale_price'), isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: _dialogField(costCtrl, tr('inventory_module.cost_label'), isNum: true)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dialogField(qtyCtrl, tr('inventory_module.available_qty'), isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: _dialogField(minQtyCtrl, tr('inventory_module.min_limit_label'), isNum: true)),
          ]),
          const SizedBox(height: 8),
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
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'), style: TextStyle(color: context.mutedText))),
          if (isEdit) TextButton(
            onPressed: () async {
              await _db.deleteProduct(item!['id']);
              if (mounted) { Navigator.pop(ctx); _loadItems(); }
            },
            child: Text(tr('common.delete'), style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'sku': skuCtrl.text.trim().isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : skuCtrl.text.trim(),
                'base_price': double.tryParse(priceCtrl.text) ?? 0.0,
                'cost_price': double.tryParse(costCtrl.text) ?? 0.0,
                'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                'min_stock_level': double.tryParse(minQtyCtrl.text) ?? 5.0,
                'industry_type': categoryCtrl.text.trim(),
                'expiry_date': expiryCtrl.text.trim(),
              };
              try {
                if (isEdit) { data['id'] = item!['id']; await _db.updateProduct(data); }
                else { 
                  data['id'] = 'ITM_${DateTime.now().millisecondsSinceEpoch}';
                  await _db.insertProduct(data); 
                }
                if (mounted) { 
                  Navigator.pop(ctx); 
                  _loadItems(); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء الحفظ: $e"), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(isEdit ? tr('inventory_module.update') : tr('common.save'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _items.length;
    final totalValue = _items.fold<double>(0, (s, i) => s + ((i['base_price'] as num?)?.toDouble() ?? 0) * ((i['quantity'] as num?)?.toDouble() ?? 0));
    final costValue = _items.fold<double>(0, (s, i) => s + ((i['cost_price'] as num?)?.toDouble() ?? 0) * ((i['quantity'] as num?)?.toDouble() ?? 0));
    final lowStock = _items.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) > 0 && ((i['quantity'] as num?)?.toDouble() ?? 0) <= 5).length;
    final outOfStock = _items.where((i) => ((i['quantity'] as num?)?.toDouble() ?? 0) <= 0).length;
    final profit = totalValue - costValue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('inventory_module.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("$totalItems ${tr('inventory_module.item_count')} • ${tr('inventory_module.sale_value')}: ${totalValue.toStringAsFixed(0)} ${CurrencyService.getSymbol(_currency)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
            ])),
            GestureDetector(
              onTap: () => _showItemDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, size: 14, color: Colors.black87),
                  const SizedBox(width: 4),
                  Text(tr('inventory_module.new_item'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        // KPIs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            Expanded(child: _buildKPI(tr('inventory_module.cost_value'), "${costValue.toStringAsFixed(0)}", Colors.blue)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI(tr('inventory_module.expected_profit'), "${profit.toStringAsFixed(0)}", profit >= 0 ? Colors.green : Colors.red)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI(tr('inventory_module.low_stock'), "$lowStock", lowStock > 0 ? Colors.orange : Colors.green)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI(tr('inventory_module.out_of_stock_kpi'), "$outOfStock", outOfStock > 0 ? Colors.red : Colors.green)),
          ]),
        ),
        const SizedBox(height: 8),

        // Search + Filter
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            Expanded(child: TextField(
              onChanged: (v) => setState(() { _searchQuery = v; _applyFilter(); }),
              style: TextStyle(fontSize: 13, color: context.textColor),
              decoration: InputDecoration(
                hintText: tr('inventory_module.search_hint'), hintStyle: TextStyle(color: context.mutedText, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 16, color: context.mutedText),
                filled: true, fillColor: context.cardSurface.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            )),
            const SizedBox(width: 8),
            _buildFilterChip(tr('common.all'), 'all'),
            const SizedBox(width: 4),
            _buildFilterChip(tr('inventory_module.low_stock'), 'low'),
            const SizedBox(width: 4),
            _buildFilterChip(tr('inventory_module.out_of_stock_kpi'), 'out'),
          ]),
        ),
        const SizedBox(height: 8),

        // Products List
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_2, size: 48, color: context.mutedText.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text(tr('common.no_data'), style: TextStyle(color: context.mutedText)),
                ]))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildProductRow(_filtered[i]),
                ),
        ),
      ]),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '';
    final sku = item['sku']?.toString() ?? '';
    final price = (item['base_price'] as num?)?.toDouble() ?? 0;
    final cost = (item['cost_price'] as num?)?.toDouble() ?? 0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
    final category = item['industry_type']?.toString() ?? '';
    final margin = price > 0 ? ((price - cost) / price * 100) : 0.0;
    final isLow = qty > 0 && qty <= 5;
    final isOut = qty <= 0;

    return GestureDetector(
      onTap: () => _showItemDialog(item: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOut ? Colors.red.withValues(alpha: 0.04) : isLow ? Colors.orange.withValues(alpha: 0.04) : context.cardSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isOut ? Colors.red.withValues(alpha: 0.15) : isLow ? Colors.orange.withValues(alpha: 0.15) : context.cardBorder.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2_outlined, color: primaryOrange, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize), maxLines: 1, overflow: TextOverflow.ellipsis),
            Row(children: [
              Text("SKU: $sku", style: TextStyle(color: context.mutedText, fontSize: 10)),
              if (category.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(category, style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${price.toStringAsFixed(0)} ${CurrencyService.getSymbol(_currency)}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: context.bodySize)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: (isOut ? Colors.red : isLow ? Colors.orange : Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text("${qty.toStringAsFixed(0)} ${tr('inventory_module.unit')}", style: TextStyle(color: isOut ? Colors.red : isLow ? Colors.orange : Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              Text("${tr('inventory_module.margin')} ${margin.toStringAsFixed(0)}%", style: TextStyle(color: context.mutedText, fontSize: 9)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildKPI(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.mutedText, fontSize: 9)),
        const SizedBox(height: 2),
        FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
      ]),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final sel = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() { _filterType = type; _applyFilter(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: sel ? primaryOrange : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: sel ? primaryOrange : context.cardBorder.withValues(alpha: 0.2))),
        child: Text(label, style: TextStyle(color: sel ? Colors.black87 : context.mutedText, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, {bool isNum = false, bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: context.textColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: context.mutedText, fontSize: 12),
        filled: true, fillColor: context.cardSurface.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
