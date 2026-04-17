import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  final String? preSelectedSupplierId;
  const PurchaseInvoiceScreen({super.key, this.preSelectedSupplierId});

  static Future<bool?> show(BuildContext context, {String? supplierId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PurchaseInvoiceScreen(preSelectedSupplierId: supplierId),
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

  @override
  void initState() {
    super.initState();
    _invoiceNumController.text = "PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    _loadMetadata();
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
        supplierId: _selectedSupplierId ?? '',
        total: total,
        paymentType: _paymentType,
        lines: lines,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 500,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: context.obsidianGlass,
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: context.cardBorder),
          ),
          child: _isLoading 
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryOrange),
                    SizedBox(height: 16),
                    Text("جاري المعالجة...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Header
              Padding(
                padding: EdgeInsets.all(context.cardPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('purchases_module.title'), style: TextStyle(color: context.textColor, fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close, color: context.mutedText), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.cardPadding),
                  child: Column(
                    children: [
                      _buildTextField(_invoiceNumController, tr('purchases_module.invoice_number'), Icons.numbers),
                      const SizedBox(height: 16),
                      _buildSupplierDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(_totalController, tr('purchases_module.total_invoice'), Icons.payments_outlined, isNumber: true),
                      const SizedBox(height: 16),
                      _buildPaymentDropdown(),
                      const SizedBox(height: 24),
                      _buildItemsSection(),
                    ],
                  ),
                ),
              ),

              // Footer Action
              Padding(
                padding: EdgeInsets.all(context.cardPadding),
                child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(tr('purchases_module.save_approve'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: context.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.mutedText),
        prefixIcon: Icon(icon, color: primaryOrange, size: 20),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.cardBorder), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryOrange), borderRadius: BorderRadius.circular(12)),
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
              items: _suppliers.map((s) => DropdownMenuItem(
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

  Widget _buildItemsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('purchases_module.selected_items'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _showItemPicker, icon: const Icon(Icons.add_box, color: primaryOrange)),
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
