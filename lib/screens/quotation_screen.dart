import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _UILineItem {
  String? itemId;
  String id;
  String name;
  double price;
  int quantity;
  double discount;
  double taxAmount;

  _UILineItem({
    this.itemId,
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.discount = 0.0,
    this.taxAmount = 0.0,
  });

  double get total => ((price * quantity) - discount) + taxAmount;
}

class _QuotationScreenState extends State<QuotationScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  final List<_UILineItem> _lines = [];
  Map<String, dynamic> _company = {};
  bool _isSaving = false;
  String? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];
  String _currency = 'SAR';
  double _taxRate = 15.0;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _pickerSearchQuery = "";
  List<Map<String, dynamic>> _quotations = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final db = await _db.database;
      final companies = await db.query('companies', limit: 1);
      if (companies.isNotEmpty) {
        final c = companies.first;
        if (mounted) {
          setState(() {
            _company = {'name': c['name'], 'tax_rate': (c['tax_rate'] as num?)?.toDouble() ?? 15.0};
            _currency = c['currency_code']?.toString() ?? 'SAR';
            _taxRate = _company['tax_rate'] ?? 15.0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _company = {'name': tr('quotations.potential_client'), 'tax_rate': 15.0};
            _currency = 'SAR';
            _taxRate = 15.0;
          });
        }
      }

      final clients = await db.query('clients');
      final quotes = await db.query('quotations', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _clients = clients;
          _quotations = quotes;
          if (clients.isNotEmpty) _selectedClientId = clients.first['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint("Error loading quotations: $e");
      if (mounted) {
        setState(() {
          _clients = [];
          _quotations = [];
        });
      }
    }
  }

  double get _subtotal => _lines.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _discountAmount => _lines.fold(0, (sum, item) => sum + item.discount);
  double get _taxAmount => _lines.fold(0, (sum, item) => sum + item.taxAmount);
  double get _total => (_subtotal - _discountAmount) + _taxAmount;

  Future<void> _saveQuotation() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('quotations.error_empty'))));
      return;
    }
    
    setState(() => _isSaving = true);
    
    final clientName = _clients.firstWhere((c) => c['id'] == _selectedClientId, orElse: () => {'name': tr('quotations.potential_client')})['name'];
    
    final items = _lines.map((l) => {
      'id': l.itemId ?? l.id,
      'name': l.name,
      'price': l.price,
      'quantity': l.quantity,
      'tax_amount': l.taxAmount,
    }).toList();

    final res = await _engine.processQuotation(
      clientId: _selectedClientId ?? 'CASH',
      clientName: clientName,
      items: items,
      expiryDate: _expiryDate.toIso8601String(),
      notes: "Validity: 30 days",
    );

    setState(() => _isSaving = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('quotations.save_success')), backgroundColor: Colors.green));
      _lines.clear();
      _loadInitialData();
      _tabController.animateTo(1); // Go to history
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.save_error')), backgroundColor: Colors.red));
    }
  }

  Future<void> _convertToInvoice(String id) async {
    final res = await _engine.convertQuotationToInvoice(id, 'credit');
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('invoice_entry.save_invoice')), backgroundColor: Colors.green));
      _loadInitialData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('vouchers.receipt.save_error')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Scaffold(
          backgroundColor: context.obsidianGlass,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(100 + context.headerSize),
            child: Container(
              padding: EdgeInsets.fromLTRB(context.cardPadding, 8, context.cardPadding, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('sales_module.title'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                          Text(tr('quotations.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: context.mutedText),
                      ),
                    ],
                  ),
              TabBar(
                controller: _tabController,
                indicatorColor: primaryOrange,
                labelColor: primaryOrange,
                unselectedLabelColor: context.mutedText,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: tr('quotations.new_tab'), height: 28),
                  Tab(text: tr('quotations.history_tab'), height: 28),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewQuoteTab(isDark),
          _buildHistoryTab(isDark),
        ],
      ),
    )));
  }

  Widget _buildNewQuoteTab(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderDetails(isDark),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('quotations.items_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                    ElevatedButton.icon(
                      onPressed: _showProductPicker,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(tr('quotations.add_item')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange.withValues(alpha: 0.1),
                        foregroundColor: primaryOrange,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (_lines.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(tr('quotations.no_quotes'), style: TextStyle(color: context.mutedText)),
                    ),
                  )
                else
                  ..._lines.map((l) => _buildLineItem(l, isDark)).toList(),
              ],
            ),
          ),
        ),
        _buildBottomSummary(isDark),
      ],
    );
  }

  Widget _buildHeaderDetails(bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: InputDecoration(
              labelText: tr('quotations.client_label'),
              labelStyle: TextStyle(color: context.mutedText, fontSize: 13),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            dropdownColor: context.bgSurface,
            items: _clients.map((c) => DropdownMenuItem<String>(
              value: c['id']?.toString(),
              child: Text(c['name']?.toString() ?? ''),
            )).toList(),
            onChanged: (v) => setState(() => _selectedClientId = v),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _expiryDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _expiryDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: primaryOrange),
                  const SizedBox(width: 8),
                  Text("${tr('quotations.expiry_label')}: ", style: TextStyle(color: context.mutedText, fontSize: 13)),
                  Text(DateFormat('yyyy-MM-dd').format(_expiryDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => line.quantity = line.quantity > 1 ? line.quantity - 1 : 1),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text("${line.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => line.quantity++),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _lines.remove(line)),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${tr('sales_module.item_picker.price_col')}: ${line.price} $_currency", style: TextStyle(color: context.mutedText, fontSize: 12)),
              Text("${tr('sales_module.item_picker.total_col')}: ${line.total.toStringAsFixed(2)} $_currency", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border(top: BorderSide(color: context.cardBorder.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${tr('quotations.subtotal')}: ${_subtotal.toStringAsFixed(2)}", style: TextStyle(color: context.mutedText)),
                Text("${tr('quotations.tax')}: ${_taxAmount.toStringAsFixed(2)}", style: TextStyle(color: context.mutedText)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('quotations.total'), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${_total.toStringAsFixed(2)} $_currency", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveQuotation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(tr('quotations.save_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(context.cardPadding),
      itemCount: _quotations.length,
      itemBuilder: (context, index) {
        final q = _quotations[index];
        bool isConverted = q['status'] == 'converted';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${tr('quotations.quote_prefix')} ${q['id'].toString().split('_').last}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConverted ? Colors.green.withValues(alpha: 0.2) : primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isConverted ? tr('invoice_entry.tabs.invoices_list') : tr('quotations.status_pending'),
                      style: TextStyle(
                        color: isConverted ? Colors.green : primaryOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("${tr('quotations.client_label')}: ${q['client_name']}", style: TextStyle(color: context.mutedText, fontSize: 13)),
              Text("${tr('quotations.expiry_label')}: ${q['expiry_date']}", style: TextStyle(color: context.mutedText, fontSize: 12)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${q['total']} $_currency", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (!isConverted)
                    TextButton.icon(
                      onPressed: () => _convertToInvoice(q['id']),
                      icon: const Icon(Icons.move_up, size: 16),
                      label: Text(tr('invoice_entry.save_invoice')),
                      style: TextButton.styleFrom(foregroundColor: primaryOrange),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProductPicker() async {
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
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (val) => setModalState(() => _pickerSearchQuery = val),
                        decoration: InputDecoration(
                          hintText: tr('sales_module.item_picker.search_hint'),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: context.cardSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          if (!p['name'].toString().toLowerCase().contains(_pickerSearchQuery.toLowerCase())) return const SizedBox();
                          return ListTile(
                            title: Text(p['name']),
                            subtitle: Text("${p['base_price']} $_currency"),
                            trailing: const Icon(Icons.add_circle, color: primaryOrange),
                            onTap: () {
                              final price = (p['base_price'] as num).toDouble();
                              setState(() {
                                _lines.add(_UILineItem(
                                  id: DateTime.now().toString(),
                                  itemId: p['id'].toString(),
                                  name: p['name'].toString(),
                                  price: price,
                                  taxAmount: price * (_taxRate / 100),
                                ));
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
