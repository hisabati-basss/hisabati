import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import '../widgets/attachment_viewer.dart';

class InvoiceEntryScreen extends StatefulWidget {
  final String? invoiceId;
  const InvoiceEntryScreen({super.key, this.invoiceId});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _UILineItem {
  String? itemId;
  String id;
  String name;
  double price;
  int quantity;
  double discount;
  String? serialNumber;
  String? batchId;

  _UILineItem({
    this.itemId,
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.discount = 0.0,
    this.serialNumber,
    this.batchId,
  });

  double get total => (price * quantity) * (1 - discount / 100);
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final List<_UILineItem> _lines = [];
  Map<String, dynamic> _company = {};
  List<Map<String, dynamic>> _cashAccounts = [];
  double _totalDiscount = 0.0;
  bool _isSaving = false;
  String _paymentType = 'cash';
  String? _selectedAccountId;
  final TextEditingController _commissionCtrl = TextEditingController(text: '0');
  String? _selectedClientId;
  String? _attachmentPath;
  String? _selectedAgentId;
  DateTime? _dueDate;
  String _pickerSearchQuery = "";
  List<Map<String, dynamic>> _salesAgents = [];
  List<Map<String, dynamic>> _clients = [];
  String _currency = 'SAR';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = await _db.database;
    final companies = await db.query('companies', limit: 1);
    if (companies.isNotEmpty) {
      final comp = companies.first;
      setState(() {
        _company = {
          'name': comp['name'],
          'tax_rate': (comp['tax_rate'] as num?)?.toDouble() ?? 15.0,
          'currency': comp['currency_code'] ?? 'SAR',
        };
        _currency = comp['currency_code']?.toString() ?? 'SAR';
      });
    } else {
      setState(() => _company = {'name': tr('ceo.default_company_name'), 'tax_rate': 15.0, 'currency': 'SAR'});
    }

    final accs = await db.query('accounts', where: "type = 'asset'");
    List<Map<String, dynamic>> agents = [];
    List<Map<String, dynamic>> clients = [];
    try { agents = await _db.getSalesAgentsWithStats(); } catch (_) {}
    try { clients = await _db.getClients(); } catch (_) {}
    setState(() {
      _cashAccounts = accs;
      _salesAgents = agents;
      _clients = List<Map<String, dynamic>>.from(clients);
      
      // 🛡️ Harmony Fix: Ensure WALK_IN_CUSTOMER is always available (prevents Dropdown crash)
      final hasWalkIn = _clients.any((c) => c['id'] == 'WALK_IN_CUSTOMER');
      if (!hasWalkIn) {
        _clients.insert(0, {
          'id': 'WALK_IN_CUSTOMER', 
          'name': tr('pos.partner_walkin')
        });
      }

      if (accs.isNotEmpty) _selectedAccountId = accs.first['id']?.toString();
      
      // Default selection logic (for new invoices)
      if (widget.invoiceId == null) {
        _selectedClientId = _clients.firstWhere(
          (c) => c['id'] == 'WALK_IN_CUSTOMER',
          orElse: () => _clients.firstWhere(
            (c) => c['id'] == 'CL_DEFAULT',
            orElse: () => _clients.first
          )
        )['id']?.toString();
      }
    });

    if (widget.invoiceId != null) {
      await _loadInvoiceData(widget.invoiceId!);
    }
  }

  Future<void> _loadInvoiceData(String invoiceId) async {
    final db = await _db.database;
    final invs = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    if (invs.isEmpty) return;
    
    final inv = invs.first;
    setState(() {
      _selectedClientId = inv['client_id']?.toString();
      _selectedAgentId = inv['sales_agent_id']?.toString();
      _paymentType = (inv['payment_type']?.toString() ?? 'cash');
      final dueDateStr = inv['due_date']?.toString();
      if (dueDateStr != null) _dueDate = DateTime.tryParse(dueDateStr);
    });

    final invLines = await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    setState(() {
      _lines.clear();
      for (var l in invLines) {
        final qty = (l['quantity'] as num?)?.toInt() ?? 1;
        final total = (l['total'] as num?)?.toDouble() ?? 0;
        final price = qty > 0 ? (total / qty) : 0;
        
        _lines.add(_UILineItem(
          id: l['id']?.toString() ?? DateTime.now().toString(),
          itemId: l['item_id']?.toString(),
          name: l['name']?.toString() ?? '',
          price: price.toDouble(),
          quantity: qty,
          discount: 0.0,
        ));
      }
    });
  }

  Future<void> _showProductPicker() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: context.mutedText.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(tr('sales_module.invoice_entry.choose_product'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (val) => setModalState(() => _pickerSearchQuery = val),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: tr('sales_module.invoice_entry.search_hint'),
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search, color: primaryOrange),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading 
                          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                          : Builder(builder: (context) {
                              final filtered = products.where((p) {
                                final q = _pickerSearchQuery.toLowerCase();
                                final name = p['name']?.toString().toLowerCase() ?? '';
                                final sku = p['sku']?.toString().toLowerCase() ?? '';
                                return name.contains(q) || sku.contains(q);
                              }).toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white24),
                                      const SizedBox(height: 12),
                                      Text(
                                        _pickerSearchQuery.isEmpty ? tr('sales_module.invoice_entry.empty_inventory') : tr('sales_module.invoice_entry.no_results'),
                                        style: const TextStyle(color: Colors.white38),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final p = filtered[index];
                                  final price = (p['base_price'] as num?)?.toDouble() ?? 0;
                                  final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                    ),
                                    child: ListTile(
                                      title: Text(p['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Text("$price $_currency | ${tr('inventory.available')}: $qty", style: const TextStyle(color: primaryOrange, fontSize: 12)),
                                      trailing: const Icon(Icons.add_circle_outline, color: primaryOrange),
                                      onTap: () {
                                        _addLine(p['name']?.toString() ?? '', price, itemId: p['id']?.toString());
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              );
                            }),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _showAddNewItemDialog();
                                  setModalState(() {}); // Refresh FutureBuilder after dialog closes
                                },
                                icon: const Icon(Icons.add_box_outlined),
                                label: Text(tr('sales_module.invoice_entry.add_product')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryOrange,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _addLine(tr('sales_module.invoice_entry.custom_item'), 0.0);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.edit_note),
                                label: Text(tr('sales_module.invoice_entry.more')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddNewItemDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black54,
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('sales_module.invoice_entry.register_new'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: tr('sales_module.invoice_entry.item_name'),
                      filled: true,
                      fillColor: context.bgSurface.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr('sales_module.invoice_entry.selling_price'),
                      filled: true,
                      fillColor: context.bgSurface.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeCtrl,
                    decoration: InputDecoration(
                      labelText: tr('sales_module.invoice_entry.barcode_optional'),
                      filled: true,
                      fillColor: context.bgSurface.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            tr('sales_module.invoice_entry.cancel'),
                            style: TextStyle(color: context.mutedText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                            await _db.insertProduct({
                              'name': nameCtrl.text,
                              'base_price': double.tryParse(priceCtrl.text) ?? 0.0,
                              'cost_price': (double.tryParse(priceCtrl.text) ?? 0.0) * 0.7,
                              'sku': barcodeCtrl.text.isEmpty ? "BAR_${DateTime.now().millisecondsSinceEpoch}" : barcodeCtrl.text,
                              'quantity': 100,
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            tr('sales_module.invoice_entry.save_return'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get _subtotal => _lines.fold(0.0, (sum, item) => sum + item.total);
  double get _discountAmount => _subtotal * (_totalDiscount / 100);
  double get _taxAmount =>
      (_subtotal - _discountAmount) * ((_company['tax_rate'] ?? 15.0) / 100);
  double get _total => (_subtotal - _discountAmount) + _taxAmount;

  void _addLine(String name, double price, {String? itemId}) {
    setState(() {
      _lines.add(
        _UILineItem(
          id: DateTime.now().toString(),
          name: name,
          price: price,
          itemId: itemId,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.mutedText.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  _buildHeader(context, isDark),

                  // Items List
                  Expanded(
                    child: _lines.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(context.cardPadding),
                            itemCount: _lines.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _lines.length) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: InkWell(
                                    onTap: _showProductPicker,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryOrange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryOrange.withValues(
                                            alpha: 0.3,
                                          ),
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_shopping_cart,
                                            color: primaryOrange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tr('sales_module.invoice_entry.more'),
                                            style: const TextStyle(
                                              color: primaryOrange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _buildLineItem(_lines[index], isDark);
                            },
                          ),
                  ),

                  // Bottom Summary Bar (Live)
                  _buildSummaryBar(context, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('sales_module.tax_invoice'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _company['name'] ?? '',
                    style: TextStyle(color: context.mutedText, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: context.mutedText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // Client Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _clients.any((c) => c['id']?.toString() == _selectedClientId) ? _selectedClientId : (_clients.isNotEmpty ? _clients.first['id']?.toString() : null),
                  decoration: InputDecoration(
                    labelText: tr('sales_module.client'),
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _clients.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['name']?.toString() ?? ''),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedClientId = val),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh, color: primaryOrange, size: 20),
                tooltip: "تحديث القائمة",
              ),
            ],
          ),
        ),
        // Sales Agent Selector (optional)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_selectedAgentId == null || _salesAgents.any((a) => a['id']?.toString() == _selectedAgentId)) ? _selectedAgentId : null,
                  decoration: InputDecoration(
                    labelText: tr('sales_module.invoice_entry.agent_optional'),
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text("بدون مندوب")),
                    ..._salesAgents.map((a) => DropdownMenuItem<String>(
                      value: a['id']?.toString(),
                      child: Text(a['name']?.toString() ?? ''),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedAgentId = val;
                      if (val != null) {
                        final agent = _salesAgents.firstWhere((a) => a['id'].toString() == val);
                        final rate = (agent['commission_rate'] as num?)?.toDouble() ?? 5.0;
                        double subtotal = 0;
                        for (var line in _lines) {
                          subtotal += line.total;
                        }
                        _commissionCtrl.text = (subtotal * (rate / 100)).toStringAsFixed(2);
                      } else {
                        _commissionCtrl.text = "0";
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.sync, color: Colors.blueAccent, size: 20),
                tooltip: "تحديث المندوبين",
              ),
            ],
          ),
        ),
        if (_selectedAgentId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _commissionCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: "مبلغ عمولة المندوب (يدوي)",
                labelStyle: const TextStyle(color: primaryOrange, fontSize: 12),
                isDense: true,
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                prefixIcon: const Icon(Icons.money, color: primaryOrange, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryOrange.withValues(alpha: 0.2))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: context.mutedText.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            tr('sales_module.empty_state'),
            style: TextStyle(
              color: context.mutedText,
              fontSize: context.bodySize,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showProductPicker,
            icon: const Icon(Icons.add),
            label: Text(tr('sales_module.invoice_entry.more')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange.withValues(alpha: 0.1),
              foregroundColor: primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.cardRadius),
                side: const BorderSide(color: primaryOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(_UILineItem line, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodySize,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "${line.price} $_currency",
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildQtyBtn(
                    Icons.remove,
                    () => setState(
                      () => line.quantity = (line.quantity > 1)
                          ? line.quantity - 1
                          : 1,
                    ),
                    isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "${line.quantity}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  _buildQtyBtn(
                    Icons.add,
                    () => setState(() => line.quantity++),
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _lines.remove(line)),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (line.itemId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => line.serialNumber = val,
                    controller: TextEditingController(text: line.serialNumber),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: "الرقم التسلسلي (Serial)",
                      hintStyle: const TextStyle(color: Colors.white24),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => line.batchId = val,
                    controller: TextEditingController(text: line.batchId),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: "رقم الشحنة (Batch)",
                      hintStyle: const TextStyle(color: Colors.white24),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.percent,
                    size: 12,
                    color: primaryOrange.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('sales_module.discount_label'),
                    style: TextStyle(color: context.mutedText, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 35,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                        () => line.discount = double.tryParse(v) ?? 0.0,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "${line.total.toStringAsFixed(2)} $_currency",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryOrange,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${tr('sales_module.subtotal')}: ${_subtotal.toStringAsFixed(2)}",
                  style: TextStyle(color: context.mutedText, fontSize: 12),
                ),
                Text(
                  "${tr('sales_module.tax_vat')} (${_company['tax_rate']}%): ${_taxAmount.toStringAsFixed(2)}",
                  style: TextStyle(color: context.mutedText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('sales_module.total_due'),
                        style: TextStyle(
                          color: context.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          "${_total.toStringAsFixed(2)} ${tr('ceo.currency.sar')}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Payment Type Selector
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(tr('sales_module.cash'), style: const TextStyle(fontSize: 10)),
                            selected: _paymentType == 'cash',
                            onSelected: (s) => setState(() => _paymentType = 'cash'),
                            selectedColor: primaryOrange.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: _paymentType == 'cash' ? primaryOrange : context.mutedText),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(tr('sales_module.credit'), style: const TextStyle(fontSize: 10)),
                            selected: _paymentType == 'credit',
                            onSelected: (s) => setState(() => _paymentType = 'credit'),
                            selectedColor: primaryOrange.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: _paymentType == 'credit' ? primaryOrange : context.mutedText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_paymentType == 'cash')
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccountId,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF151515)
                                : Colors.white,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 13,
                            ),
                            items: _cashAccounts
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id']?.toString(),
                                    child: Text(e['name']?.toString() ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedAccountId = val),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _dueDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: primaryOrange),
                                const SizedBox(width: 8),
                                Text(
                                  _dueDate == null 
                                    ? tr('sales_module.due_date') 
                                    : _dueDate!.toIso8601String().split('T').first,
                                  style: const TextStyle(color: primaryOrange, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndPrint,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.print_outlined),
                      label: Text(
                        tr('sales_module.save_print'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndPrint() async {
    if (_lines.isEmpty) return;
    if (_paymentType == 'cash' && _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('sales_module.invoice_entry.select_account'))));
      return;
    }
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('sales_module.invoice_entry.select_client'))));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final invoiceId = widget.invoiceId ?? () {
        final year = DateTime.now().year;
        return "INV-$year-${DateTime.now().millisecondsSinceEpoch}"; // Fallback, will be overridden below
      }();
      
      String finalInvoiceId = invoiceId;
      if (widget.invoiceId == null) {
        final countRes = await _db.database.then((db) => db.rawQuery('SELECT COUNT(*) as count FROM invoices'));
        final count = (countRes.first['count'] as int) + 1;
        final year = DateTime.now().year;
        finalInvoiceId = "INV-$year-${count.toString().padLeft(5, '0')}";
      }

      final now = DateTime.now().toIso8601String();
      
      final invoiceLines = _lines.map((l) => <String, dynamic>{
        'name': l.name,
        'quantity': l.quantity,
        'price_at_sale': l.price,
        'total': l.total,
        'item_id': l.itemId,
      }).toList();

      await _db.saveInvoiceWithLines(
        invoice: {
          'id': finalInvoiceId,
          'issue_date': now,
          'due_date': _dueDate?.toIso8601String(),
          'subtotal': _subtotal - _discountAmount,
          'tax_amount': _taxAmount,
          'total': _total,
          'payment_type': _paymentType,
          'client_id': _selectedClientId,
          'sales_agent_id': _selectedAgentId,
          'status': _paymentType == 'cash' ? 'paid' : 'draft',
        },
        lines: invoiceLines.map((l) => <String, dynamic>{
          ...l,
          'invoice_id': finalInvoiceId,
        }).toList(),
        paymentAccountId: _paymentType == 'cash' ? _selectedAccountId : null,
      );

      // Save manual commission if agent is selected
      if (_selectedAgentId != null) {
        final manualComm = double.tryParse(_commissionCtrl.text) ?? 0.0;
        if (manualComm > 0) {
          await _db.database.then((db) => db.insert('commissions', {
            'id': 'COM_MANUAL_${DateTime.now().millisecondsSinceEpoch}',
            'employee_id': _selectedAgentId,
            'amount': manualComm,
            'rate': 0.0, // Manual fixed amount
            'sales_amount': _total,
            'period': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
            'status': 'pending',
            'created_at': now,
          }));
        }
      }

      // Generate PDF
      PdfService.generateInvoice(
        invoice: {
          'id': invoiceId,
          'issue_date': now,
          'subtotal': _subtotal - _discountAmount,
          'tax_amount': _taxAmount,
          'total': _total,
          'payment_type': _paymentType,
        },
        items: invoiceLines,
        company: {
          'name': _company['name'],
          'vat_number': _company['vat_number']?.toString() ?? '',
          'currency': 'ر.س',
          'tax_rate': _company['tax_rate'],
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('sales_module.invoice_saved')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('common.save_error', args: ['$e']))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
