import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  
  bool _isLoading = true;
  String _cashierId = 'EMP_1';
  String _currency = 'SAR';
  double _taxRate = 15.0;

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

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
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
        lines: _cart,
        total: _total,
        taxAmount: _vat,
        subtotal: _subtotal,
        shiftId: _activeShift!['id']?.toString() ?? '',
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
              Text(tr('pos.tax_number', args: ["3005891100003"]), style: const TextStyle(color: Colors.black87, fontSize: 12)),
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
          RawKeyboardListener(
            focusNode: _scannerFocusNode,
            autofocus: true,
            onKey: _handleKey,
            child: Row(
              children: [
                Expanded(
                  flex: widget.isMobile ? 1 : 2,
                  child: _buildItemsArea(),
                ),
                if (!widget.isMobile || _cart.isNotEmpty)
                  Container(
                    width: widget.isMobile ? MediaQuery.of(context).size.width * 0.4 : 350,
                    decoration: BoxDecoration(
                      color: context.cardSurface,
                      border: Border(right: BorderSide(color: context.cardBorder)),
                    ),
                    child: _buildCartSidebar(),
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
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.cardPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('pos.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: primaryOrange, size: context.iconSize + 4),
                    onPressed: () => setState(() => _isCameraScannerOpen = true),
                    tooltip: tr('pos.scan_tooltip'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          _activeShift == null ? tr('pos.shift_closed') : tr('pos.shift_open', args: [(_activeShift!['id']?.toString() ?? '').length > 6 ? (_activeShift!['id'].toString()).substring(0,6) : 'OPEN']),
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(context.cardPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isMobile ? 2 : 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final price = (item['base_price'] as num?)?.toDouble() ?? 0;
              return InkWell(
                onTap: () => _addToCart(item),
                borderRadius: BorderRadius.circular(context.cardRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(context.cardRadius),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.inventory_2, color: primaryOrange, size: context.iconSize - 2),
                      ),
                      const SizedBox(height: 8),
                      Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: context.bodySize - 1), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text("$price $_currency", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.subHeaderSize - 2)),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
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
              ? Center(child: Text(tr('pos.cart_empty'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize)))
              : ListView.builder(
                  padding: EdgeInsets.all(context.cardPadding),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final line = _cart[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                            child: Text("${line['quantity'].toInt()}x", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
                                Text("${line['price']} $_currency", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)),
                              ],
                            ),
                          ),
                          Text("${line['total']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
                          IconButton(icon: Icon(Icons.close, size: context.iconSize - 4), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _removeFromCart(index)),
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(tr('pos.total_due'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: context.bodySize + 1)),
                Text("${_total.toStringAsFixed(2)} $_currency", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.headerSize + 4)),
              ]),
              const SizedBox(height: 20),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cart.isEmpty ? Colors.grey : primaryOrange,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
                ),
                onPressed: _cart.isEmpty ? null : _handleCheckout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: context.iconSize - 2),
                    const SizedBox(width: 8),
                    Text(tr('pos.checkout_btn'), style: TextStyle(fontSize: context.bodySize + 2, fontWeight: FontWeight.bold)),
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
