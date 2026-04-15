import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  final String? preSelectedSupplierId;
  const PurchaseInvoiceScreen({super.key, this.preSelectedSupplierId});

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
  bool _isMaintenance = false;
  String _paymentType = 'cash';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _invoiceNumController.text = "PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final sups = await _db.getSuppliers();
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
        supplierId: _selectedSupplierId ?? '',
        total: total,
        paymentType: _paymentType,
        lines: lines,
      );

      if (mounted) {
        Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(tr('purchases_module.title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFormCard(),
                const SizedBox(height: 16),
                _buildItemsList(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _invoiceNumController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('purchases_module.invoice_number'), prefixIcon: const Icon(Icons.numbers)),
          ),
          const SizedBox(height: 20),
          _buildDropdown(tr('purchases_module.supplier'), _selectedSupplierId, _suppliers.map((s) => {'id': s['id']?.toString() ?? '', 'name': s['name']?.toString() ?? ''}).toList(), (val) => setState(() => _selectedSupplierId = val)),
          const SizedBox(height: 20),
          TextField(
            controller: _totalController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('purchases_module.total_invoice'), prefixIcon: const Icon(Icons.payments_outlined)),
          ),
          const SizedBox(height: 20),
          _buildDropdown(tr('purchases_module.payment_method'), _paymentType, [{'id': 'cash', 'name': tr('purchases_module.cash')}, {'id': 'credit', 'name': tr('purchases_module.credit')}], (val) => setState(() => _paymentType = val!)),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('purchases_module.selected_items'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _showItemPicker, icon: const Icon(Icons.add_box, color: primaryOrange)),
            ],
          ),
          if (_selectedItems.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(tr('purchases_module.no_items_selected'), style: const TextStyle(color: Colors.white38, fontSize: 12))),
          ..._selectedItems.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory, color: Colors.white38, size: 20),
            title: Text(item['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
            trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _selectedItems.remove(item))),
          )),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<Map<String, dynamic>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A1A),
          items: items.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: _saveInvoice,
        child: Text(tr('purchases_module.save_approve'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
