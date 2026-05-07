import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/glass_container.dart';

class PosScreen extends StatefulWidget {
  final bool isMobile;
  const PosScreen({super.key, this.isMobile = false});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final FocusNode _scannerFocusNode = FocusNode();
  String _barcodeBuffer = "";
  bool _isCameraScannerOpen = false;
  
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _cart = [];
  Map<String, dynamic>? _activeShift;
  Map<String, dynamic>? _company;
  
  bool _isLoading = true;
  String _cashierId = 'EMP_1';
  String _currency = 'SAR';
  double _taxRate = 15.0;
  String _selectedCategory = 'ALL';
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initPos();
  }

  @override
  void dispose() {
    _scannerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initPos() async {
    final db = await _db.database;
    final company = await _db.getCurrentCompanyContext();
    final items = await _db.getProducts();
    _activeShift = await _db.getActiveShift(_cashierId);
    
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
        _company = company;
        if (company != null) {
          _currency = company['currency_code'] ?? 'SAR';
          _taxRate = (company['tax_rate'] as num?)?.toDouble() ?? 15.0;
        }
      });
      
      if (_activeShift == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showOpenShiftDialog());
      } else {
        _scannerFocusNode.requestFocus();
      }
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processScannedBarcode(_barcodeBuffer);
          _barcodeBuffer = "";
        }
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  void _processScannedBarcode(String code) {
    final itemIndex = _items.indexWhere((i) => (i['sku'] ?? i['barcode'] ?? '') == code);
    if (itemIndex >= 0) {
      _addToCart(_items[itemIndex]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('pos.barcode_error', args: [code])), backgroundColor: Colors.red));
    }
  }

  Future<void> _showOpenShiftDialog() async {
    final TextEditingController balanceController = TextEditingController(text: "0");
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('pos.open_shift_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('pos.opening_balance_msg')),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixText: _currency,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black),
            onPressed: () async {
              double opening = double.tryParse(balanceController.text) ?? 0.0;
              await _db.openShift(_cashierId, opening);
              Navigator.pop(ctx);
              _initPos();
            },
            child: Text(tr('pos.start_selling')),
          ),
        ],
      ),
    );
  }

  Future<void> _showZReportDialog() async {
    if (_activeShift == null) return;
    
    final db = await _db.database;
    final shiftId = _activeShift!['id'];
    
    // Calculate totals
    final invoices = await db.query('invoices', where: 'shift_id = ? AND status = ?', whereArgs: [shiftId, 'paid']);
    double totalSales = 0.0;
    double totalTax = 0.0;
    double cashSales = 0.0;
    double cardSales = 0.0;
    
    for (var inv in invoices) {
      final total = (inv['total'] as num?)?.toDouble() ?? 0.0;
      final tax = (inv['tax_amount'] as num?)?.toDouble() ?? 0.0;
      totalSales += total;
      totalTax += tax;
      if (inv['payment_type'] == 'cash') {
        cashSales += total;
      } else {
        cardSales += total;
      }
    }
    
    final openingBalance = (_activeShift!['opening_balance'] as num?)?.toDouble() ?? 0.0;
    final expectedCash = openingBalance + cashSales;
    
    final TextEditingController actualCashCtrl = TextEditingController(text: expectedCash.toStringAsFixed(2));

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.summarize, color: primaryOrange),
            const SizedBox(width: 8),
            Text(tr('pos.z_report_title')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _zReportRow('Shift ID', shiftId.toString().substring(0, 10)),
              _zReportRow('Opening Balance', '$openingBalance $_currency'),
              const Divider(color: Colors.white24),
              _zReportRow('Total Sales', '${totalSales.toStringAsFixed(2)} $_currency'),
              _zReportRow('Total Tax', '${totalTax.toStringAsFixed(2)} $_currency'),
              const Divider(color: Colors.white24),
              _zReportRow('Cash Sales', '${cashSales.toStringAsFixed(2)} $_currency'),
              _zReportRow('Card/Other Sales', '${cardSales.toStringAsFixed(2)} $_currency'),
              const Divider(color: Colors.white24),
              _zReportRow('Expected Cash in Drawer', '${expectedCash.toStringAsFixed(2)} $_currency', isBold: true),
              const SizedBox(height: 16),
              Text('Actual Cash Count:', style: TextStyle(color: context.textColor, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: actualCashCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixText: _currency,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              double actualCash = double.tryParse(actualCashCtrl.text) ?? 0.0;
              await _db.closeShift(shiftId, actualCash);
              Navigator.pop(ctx);
              _initPos();
            },
            child: Text(tr('pos.close_shift_btn')),
          ),
        ],
      ),
    );
  }

  Widget _zReportRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? context.textColor : context.mutedText, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isBold ? primaryOrange : context.textColor, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    double availableQty = (item['quantity'] as num?)?.toDouble() ?? 0;
    double price = (item['base_price'] as num?)?.toDouble() ?? 0;
    String itemId = item['id']?.toString() ?? '';
    
    setState(() {
      int idx = _cart.indexWhere((e) => e['item_id'] == itemId);
      double currentCartQty = idx >= 0 ? _cart[idx]['quantity'] : 0.0;

      if (currentCartQty + 1 > availableQty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('pos.qty_not_available', args: [availableQty.toString()])), 
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      if (idx >= 0) {
        _cart[idx]['quantity'] += 1;
        _cart[idx]['total'] = _cart[idx]['quantity'] * price;
      } else {
        _cart.add({
          'item_id': itemId,
          'name': item['name'] ?? '',
          'price': price,
          'quantity': 1.0,
          'total': price,
        });
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  double get _subtotal => _cart.fold(0.0, (sum, i) => sum + i['total']);
  double get _vat => _subtotal * (_taxRate / 100);
  double get _total => _subtotal + _vat;

  Future<void> _handleCheckout() async {
    if (_cart.isEmpty || _activeShift == null) return;
    
    try {
      await _db.savePosReceipt(
        {
          'id': 'POS_REC_${DateTime.now().millisecondsSinceEpoch}',
          'total': _total,
          'tax_amount': _vat,
          'subtotal': _subtotal,
          'shift_id': _activeShift!['id']?.toString() ?? '',
        },
        _cart,
      );
      _showReceiptDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${tr('pos.checkout_error')}: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReceiptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 48, color: Colors.black54),
              const SizedBox(height: 8),
              Text(tr('pos.receipt_header'), style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(tr('pos.main_showroom'), style: const TextStyle(color: Colors.black87, fontSize: 12)),
              Text(tr('pos.tax_number', args: [_company?['vat_number']?.toString() ?? '']), style: const TextStyle(color: Colors.black87, fontSize: 12)),
              const Divider(color: Colors.black26, height: 24, thickness: 1),
              
              ..._cart.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text("${line['quantity'].toInt()}x ${line['name']}", style: const TextStyle(color: Colors.black))),
                    Text("${line['total'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.black)),
                  ],
                ),
              )),
              
              const Divider(color: Colors.black26, height: 24, thickness: 1),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.subtotal_no_tax'), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text("${_subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.vat_label', args: [_taxRate.toInt().toString()]), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text("${_vat.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.total_due'), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${_total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              
              const SizedBox(height: 24),
              Container(width: 80, height: 80, color: Colors.black12, child: const Icon(Icons.qr_code_2, size: 64, color: Colors.black87)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _clearCart();
                },
                child: Text(tr('pos.print_and_pass')),
              )
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          KeyboardListener(
            focusNode: _scannerFocusNode,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: Row(
              children: [
                Expanded(
                  flex: widget.isMobile ? 1 : 2,
                  child: _buildItemsArea(),
                ),
                if (!widget.isMobile || _cart.isNotEmpty)
                  Container(
                    width: widget.isMobile ? MediaQuery.of(context).size.width * 0.4 : 380,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: context.cardBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: -10)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: _buildCartSidebar(),
                      ),
                    ),
                  )
              ],
            ),
          ),
          if (_isCameraScannerOpen)
            _buildCameraScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraScannerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() => _isCameraScannerOpen = false);
                  _processScannedBarcode(barcodes.first.rawValue!);
                }
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => setState(() => _isCameraScannerOpen = false),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: primaryOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                tr('pos.camera_scanner_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildItemsArea() {
    final filteredItems = _items.where((item) {
      final matchesCategory = _selectedCategory == 'ALL' || item['industry_type'] == _selectedCategory;
      final matchesSearch = item['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
      return matchesCategory && matchesSearch;
    }).toList();

    final categories = ['ALL', ..._items.map((e) => e['industry_type']?.toString() ?? 'Other').toSet()];

    return Column(
      children: [
        // Premium Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('pos.title'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: context.textColor, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                        Text(tr('pos.subtitle'), style: TextStyle(fontSize: 12, color: context.mutedText), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      if (!Platform.isWindows) 
                        _buildHeaderAction(Icons.qr_code_scanner, () => setState(() => _isCameraScannerOpen = true)),
                      if (!Platform.isWindows) const SizedBox(width: 12),
                      _buildShiftStatus(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: 16,
                blur: 10,
                opacity: 0.05,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: tr('pos.search_hint'),
                    hintStyle: TextStyle(color: context.mutedText.withValues(alpha: 0.5)),
                    icon: Icon(Icons.search, color: primaryOrange, size: 20),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category Selector
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(colors: [primaryOrange, primaryOrange.withValues(alpha: 0.8)]) : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? primaryOrange.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                    boxShadow: isSelected ? [BoxShadow(color: primaryOrange.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: -5)] : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.isMobile ? 2 : 4,
                childAspectRatio: widget.isMobile ? 0.70 : 0.66,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: widget.isMobile ? 2 : 4,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildProductCard(item),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
        child: Icon(icon, color: primaryOrange, size: 20),
      ),
    );
  }

  Widget _buildShiftStatus() {
    return GestureDetector(
      onTap: _activeShift != null ? _showZReportDialog : _showOpenShiftDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (_activeShift == null ? Colors.red : Colors.green).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (_activeShift == null ? Colors.red : Colors.green).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, color: _activeShift == null ? Colors.red : Colors.green, size: 8),
            const SizedBox(width: 8),
            Text(
              _activeShift == null ? tr('pos.shift_closed') : tr('pos.shift_open', args: [(_activeShift!['id']?.toString() ?? '').length > 6 ? (_activeShift!['id'].toString()).substring(0,6) : 'OPEN']),
              style: TextStyle(color: _activeShift == null ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 10)
            ),
            if (_activeShift != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_clock, color: Colors.redAccent, size: 12),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final price = (item['base_price'] as num?)?.toDouble() ?? 0;
    final qty = (item['quantity'] as num?)?.toDouble() ?? 0;

    return InkWell(
      onTap: () => _addToCart(item),
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        borderRadius: 20,
        blur: 20,
        opacity: 0.08,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 2),
            // Icon Container with Glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryOrange.withValues(alpha: 0.25), primaryOrange.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: primaryOrange.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: -2)
                ],
              ),
              child: Icon(Icons.shopping_bag_rounded, color: primaryOrange, size: 24),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              "${item['industry_type'] ?? ''}".toUpperCase(),
              style: TextStyle(color: context.mutedText, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                "$price $_currency",
                style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            if (qty < 10)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tr('pos.low_stock', args: [qty.toInt().toString()]),
                    style: TextStyle(color: qty < 5 ? Colors.redAccent : Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSidebar() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.cardBorder)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: primaryOrange, size: 18),
              const SizedBox(width: 8),
              Text(tr('pos.cart_title'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_cart.isNotEmpty)
                IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: _clearCart),
            ],
          ),
        ),
        
        Expanded(
          child: _cart.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(tr('pos.cart_empty'), style: TextStyle(color: context.mutedText, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(context.cardPadding),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final line = _cart[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${line['quantity'].toInt()}x",
                              style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis),
                                Text("${line['price']} $_currency", style: TextStyle(color: context.mutedText, fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${line['total'].toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: primaryOrange),
                              ),
                              GestureDetector(
                                onTap: () => _removeFromCart(index),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        
        Container(
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: Border(top: BorderSide(color: context.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.subtotal'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize)),
                Text("${_subtotal.toStringAsFixed(2)} $_currency", style: TextStyle(color: context.textColor, fontSize: context.bodySize)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.tax_amount', args: [_taxRate.toInt().toString()]), style: TextStyle(color: context.mutedText, fontSize: context.bodySize)),
                Text("${_vat.toStringAsFixed(2)} $_currency", style: TextStyle(color: context.textColor, fontSize: context.bodySize)),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(tr('pos.total_due'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: context.bodySize + 1)),
                  const SizedBox(width: 20),
                  Text("${_total.toStringAsFixed(2)} $_currency", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.headerSize + 4)),
                ]),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cart.isEmpty ? Colors.grey.withValues(alpha: 0.2) : primaryOrange,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: primaryOrange.withValues(alpha: 0.3),
                ),
                onPressed: _cart.isEmpty ? null : _handleCheckout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      tr('pos.checkout_btn').toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
