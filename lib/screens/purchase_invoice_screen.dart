import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  final String? preSelectedSupplierId;
  final String? invoiceId;
  const PurchaseInvoiceScreen({super.key, this.preSelectedSupplierId, this.invoiceId});

  static Future<bool?> show(BuildContext context, {String? supplierId, String? invoiceId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => PurchaseInvoiceScreen(preSelectedSupplierId: supplierId, invoiceId: invoiceId),
    );
  }

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _invoiceNumController = TextEditingController();
  
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _selectedItems = [];
  
  String? _selectedSupplierId;
  String _paymentType = 'cash';
  bool _isLoading = true;
  List<Map<String, dynamic>> _landedCosts = [];
  final TextEditingController _landedCostAmountCtrl = TextEditingController();
  final TextEditingController _landedCostDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null) {
      _loadInitialData();
    } else {
      _invoiceNumController.text = "PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      _loadMetadata();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final db = await _db.database;
    final sups = await _db.getSuppliers();
    
    final invRes = await db.query('purchase_invoices', where: 'id = ?', whereArgs: [widget.invoiceId]);
    if (invRes.isNotEmpty) {
      final inv = invRes.first;
      final lines = await db.query('purchase_invoice_lines', where: 'invoice_id = ?', whereArgs: [widget.invoiceId]);
      
      if (mounted) {
        setState(() {
          _suppliers = sups;
          _invoiceNumController.text = inv['id']?.toString() ?? '';
          _totalController.text = inv['total']?.toString() ?? '0';
          _selectedSupplierId = inv['supplier_id']?.toString();
          _paymentType = inv['payment_type']?.toString() ?? 'cash';
          _selectedItems = lines.map((l) => {
            'id': l['item_id'],
            'name': l['name'],
            'cost_price': l['price'],
          }).toList();
          _isLoading = false;
        });
      }
    } else {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    final sups = await _db.getSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = sups;
        if (widget.preSelectedSupplierId != null) {
          _selectedSupplierId = widget.preSelectedSupplierId;
        } else if (sups.isNotEmpty) {
          _selectedSupplierId = sups.first['id']?.toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _showItemPicker() async {
    final products = await _db.getProducts();
    if (!mounted) return;
     
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Text(tr('purchases_module.add_items_stock'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: products.isEmpty 
                 ? Center(child: Text(tr('purchases_module.no_predefined'), style: const TextStyle(color: Colors.white38)))
                 : ListView.builder(
                     itemCount: products.length,
                     itemBuilder: (context, index) {
                       final p = products[index];
                       final cost = (p['cost_price'] as num?)?.toDouble() ?? 0;
                       return ListTile(
                         title: Text(p['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                         subtitle: Text(tr('purchases_module.current_cost', args: [cost.toString()]), style: const TextStyle(color: Colors.white70)),
                         trailing: const Icon(Icons.add_circle, color: primaryOrange),
                         onTap: () {
                           setState(() {
                             _selectedItems.add(p);
                             double currentTotal = double.tryParse(_totalController.text) ?? 0;
                             _totalController.text = (currentTotal + cost).toString();
                           });
                           Navigator.pop(context);
                         },
                       );
                     },
                   ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    final double total = double.tryParse(_totalController.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('purchases_module.enter_amount'))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final lines = _selectedItems.map((item) => {
        'item_id': item['id'],
        'name': item['name'],
        'quantity': 1.0,
        'price': (item['cost_price'] as num?)?.toDouble() ?? 0,
       }).toList();

      await _db.savePurchaseInvoice(
        {
          'supplier_id': _selectedSupplierId ?? '',
          'total': total,
          'payment_type': _paymentType,
        },
        lines,
      );

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          // Clear form if used inside the sidebar
          setState(() {
            _selectedItems.clear();
            _totalController.clear();
            _invoiceNumController.text = "PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('purchases_module.save_success')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('purchases_module.save_error', args: [e.toString()])), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520, // More compact width
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF0F0F12) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.cardBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _isLoading 
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryOrange),
                      const SizedBox(height: 12),
                      Text("جاري المعالجة...", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 32, height: 3,
                    decoration: BoxDecoration(color: context.mutedText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(widget.invoiceId != null ? "تعديل فاتورة مشتريات" : tr('purchases_module.title'), 
                        style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: Icon(Icons.close, color: context.mutedText, size: 20), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _buildTextField(_invoiceNumController, tr('purchases_module.invoice_number'), Icons.numbers),
                        const SizedBox(height: 12),
                        _buildSupplierDropdown(),
                        const SizedBox(height: 12),
                        _buildTextField(_totalController, tr('purchases_module.total_invoice'), Icons.payments_outlined, isNumber: true),
                        const SizedBox(height: 12),
                        _buildPaymentDropdown(),
                        const SizedBox(height: 16),
                        _buildItemsSection(),
                        const SizedBox(height: 12),
                        _buildLandedCostsSection(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(tr('purchases_module.save_approve'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: context.textColor, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelText: label,
        labelStyle: TextStyle(color: context.mutedText, fontSize: 12),
        prefixIcon: Icon(icon, color: primaryOrange, size: 18),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.cardBorder), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryOrange), borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('purchases_module.supplier'), style: TextStyle(fontSize: 12, color: context.mutedText)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupplierId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: TextStyle(color: context.textColor),
              items: _suppliers.isEmpty 
                ? [DropdownMenuItem(value: null, child: Text("لا يوجد موردين - أضف مورد أولاً"))]
                : _suppliers.map((s) => DropdownMenuItem(
                value: s['id']?.toString(),
                child: Text(s['name']?.toString() ?? ''),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSupplierId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('purchases_module.payment_method'), style: TextStyle(fontSize: 12, color: context.mutedText)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paymentType,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: TextStyle(color: context.textColor),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(tr('purchases_module.cash'))),
                DropdownMenuItem(value: 'credit', child: Text(tr('purchases_module.credit'))),
              ],
              onChanged: (val) => setState(() => _paymentType = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandedCostsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('التكاليف الإضافية (Landed Cost)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                onPressed: _showAddLandedCostDialog,
                icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 20),
              ),
            ],
          ),
          const Divider(),
          if (_landedCosts.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("لا توجد تكاليف إضافية", style: TextStyle(color: Colors.white38, fontSize: 11))),
          ..._landedCosts.map((lc) => ListTile(
            dense: true,
            title: Text(lc['description'], style: const TextStyle(color: Colors.white, fontSize: 12)),
            trailing: Text("${lc['amount']} SAR", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            onLongPress: () => setState(() => _landedCosts.remove(lc)),
          )),
        ],
      ),
    );
  }

  void _showAddLandedCostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("إضافة تكلفة إضافية"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _landedCostDescCtrl, decoration: const InputDecoration(labelText: "الوصف (مثلاً: شحن، جمارك)")),
            TextField(controller: _landedCostAmountCtrl, decoration: const InputDecoration(labelText: "المبلغ"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              if (_landedCostAmountCtrl.text.isEmpty) return;
              setState(() {
                _landedCosts.add({
                  'description': _landedCostDescCtrl.text,
                  'amount': double.tryParse(_landedCostAmountCtrl.text) ?? 0.0,
                });
                _landedCostDescCtrl.clear();
                _landedCostAmountCtrl.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('purchases_module.selected_items'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(onPressed: _showItemPicker, icon: const Icon(Icons.add_box, color: primaryOrange, size: 20)),
            ],
          ),
          const Divider(),
          if (_selectedItems.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(tr('purchases_module.no_items_selected'), style: TextStyle(color: context.mutedText, fontSize: 12))),
          ..._selectedItems.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory, color: Colors.white38, size: 20),
            title: Text(item['name']?.toString() ?? '', style: TextStyle(color: context.textColor, fontSize: 14)),
            trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _selectedItems.remove(item))),
          )),
        ],
      ),
    );
  }
}
