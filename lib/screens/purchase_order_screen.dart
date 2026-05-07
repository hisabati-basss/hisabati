import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/approval_service.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';
import '../core/config/app_constants.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  final ApprovalService _approvalService = ApprovalService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _currentBranchId;
  bool _isMultiBranch = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final contextData = await _db.getCurrentCompanyContext();
      _currentBranchId = contextData['branch_id'];
      _isMultiBranch = contextData['is_multi_branch'] == 1;

      final res = await _db.getPurchaseOrders();
      if (mounted) {
        setState(() {
          _orders = res.where((o) {
            final matchesBranch = !_isMultiBranch || _currentBranchId == null || o['branch_id'] == _currentBranchId;
            return matchesBranch && (o['is_deleted'] ?? 0) == 0;
          }).toList();
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.bgSurface,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: context.textColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أوامر الشراء',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: context.textColor,
              ),
            ),
            Text(
              'أتمتة الطلبات والتحويل إلى فواتير مشتريات',
              style: TextStyle(
                color: context.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh, color: context.textColor),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryOrange))
        : _orders.isEmpty 
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: EdgeInsets.all(context.sectionPadding),
              itemCount: _orders.length,
              itemBuilder: (context, index) => _buildOrderCard(context, _orders[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrderDialog,
        label: const Text('أمر شراء جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد أوامر شراء حالياً',
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أول أمر شراء للموردين',
            style: TextStyle(color: context.mutedText.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final bool isConverted = order['status'] == 'received';
    final statusColor = _getStatusColor(order['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long, color: statusColor),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أمر رقم: ${order['id'].toString().substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                _buildStatusChip(order['status'], statusColor),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'المورد: ${order['supplier_name'] ?? order['supplier_id'] ?? 'غير محدد'}',
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: context.mutedText),
                    const SizedBox(width: 4),
                    Text(
                      'المتوقع: ${order['expected_delivery'] ?? order['expected_date'] ?? '-'}',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${(order['total'] as num?)?.toStringAsFixed(2) ?? '0.00'} ر.س',
              style: TextStyle(
                color: AppConstants.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.mutedText.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isMultiBranch && order['status'] == 'sent')
                    TextButton.icon(
                      onPressed: () => _requestApproval(order['id']),
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text('طلب اعتماد', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    )
                  else if (order['status'] == 'approved' || !_isMultiBranch)
                    TextButton.icon(
                      onPressed: () => _convertToInvoice(order['id']),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('تحويل لفاتورة مشتريات', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    String label = 'مسودة';
    if (status == 'sent') label = 'تم الإرسال';
    if (status == 'pending_approval') label = 'بانتظار الاعتماد';
    if (status == 'approved') label = 'معتمد';
    if (status == 'received') label = 'تم الاستلام';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'sent') return Colors.blue;
    if (status == 'pending_approval') return Colors.orange;
    if (status == 'approved') return Colors.teal;
    if (status == 'received') return Colors.green;
    return Colors.orange;
  }

  Future<void> _requestApproval(String poId) async {
    // In a real scenario, we'd get the current user ID
    await _approvalService.requestApproval(
      entityType: 'purchase_order',
      entityId: poId,
      requesterId: 'CURRENT_USER',
      comments: 'يرجى اعتماد أمر الشراء للبدء في التوريد',
    );
    
    // Update PO status to pending_approval
    await _db.updatePurchaseOrderStatus(poId, 'pending_approval');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الاعتماد بنجاح'), backgroundColor: Colors.orange),
      );
      _loadOrders();
    }
  }

  Future<void> _convertToInvoice(String poId) async {
    final success = await _engine.convertPOToInvoice(poId, 'credit');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحويل أمر الشراء إلى فاتورة مشتريات بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadOrders();
      }
    }
  }

  void _showAddOrderDialog() {
    final supplierCtrl = TextEditingController();
    final totalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('أمر شراء جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: supplierCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المورد',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalCtrl,
              decoration: const InputDecoration(
                labelText: 'المبلغ الإجمالي المتوقع',
                prefixIcon: Icon(Icons.monetization_on),
                suffixText: 'ر.س',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: context.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (supplierCtrl.text.isEmpty) return;
              await _db.addPurchaseOrder({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'supplier_id': 'SUP_${DateTime.now().millisecondsSinceEpoch}',
                'supplier_name': supplierCtrl.text,
                'issue_date': DateTime.now().toIso8601String().split('T')[0],
                'expected_date': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
                'total': double.tryParse(totalCtrl.text) ?? 0,
                'status': 'sent',
                'branch_id': _currentBranchId,
                'is_deleted': 0,
              }, []);
              if (mounted) {
                Navigator.pop(ctx);
                _loadOrders();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حفظ وإرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

