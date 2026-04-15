// lib/screens/purchase_order_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final db = await _db.database;
      final res = await db.query('purchase_orders', where: 'is_deleted = 0', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _orders = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading purchase orders: $e");
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.surface,
                    Colors.blue.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: context.sectionPadding),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _orders.isEmpty 
                        ? _buildEmptyState(theme)
                        : _buildOrdersList(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // PO Creation Flow
        label: const Text('أمر شراء جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.shopping_cart_checkout),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أوامر الشراء',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'أتمتة الطلبات والتحويل إلى فواتير مشتريات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 80, color: theme.colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد أوامر شراء حالياً',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final bool isConverted = order['status'] == 'received';
        
        return Container(
          margin: EdgeInsets.only(bottom: context.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ListTile(
                contentPadding: EdgeInsets.all(context.cardPadding),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أمر رقم: ${order['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildStatusChip(order['status'], theme),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('المورد: ${order['supplier_id']}'),
                    Text('تاريخ التوريد المتوقع: ${order['expected_delivery']}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order['total']} ر.س',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isConverted)
                      TextButton(
                        onPressed: () => _convertToInvoice(order['id']),
                        child: const Text('تحويل لفاتورة', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color = Colors.orange;
    String label = 'مسودة';
    if (status == 'sent') { color = Colors.blue; label = 'تم الإرسال'; }
    if (status == 'received') { color = Colors.green; label = 'تم الاستلام'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _convertToInvoice(String poId) async {
    final success = await _engine.convertPOToInvoice(poId, 'credit');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحويل أمر الشراء إلى فاتورة مشتريات وتم تحديث المخزون'), backgroundColor: Colors.green),
      );
      _loadOrders();
    }
  }
}
