import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';
import '../core/config/app_constants.dart';

class DebitNoteScreen extends StatefulWidget {
  const DebitNoteScreen({super.key});

  @override
  State<DebitNoteScreen> createState() => _DebitNoteScreenState();
}

class _DebitNoteScreenState extends State<DebitNoteScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final res = await _db.getDebitNotes();
      if (mounted) {
        setState(() {
          _notes = res.where((n) => (n['is_deleted'] ?? 0) == 0).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading debit notes: $e");
      if (mounted) {
        setState(() {
          _notes = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'الإشعارات المدينة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textColor),
            ),
            Text(
              'إدارة مرتجعات المشتريات والتسويات مع الموردين',
              style: TextStyle(color: context.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryOrange))
        : _notes.isEmpty 
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: EdgeInsets.all(context.sectionPadding),
              itemCount: _notes.length,
              itemBuilder: (context, index) => _buildNoteCard(context, _notes[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        label: const Text('إشعار مدين جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.outbox_rounded, color: Colors.white),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات مدينة حالياً',
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'استخدم الإشعارات المدينة لتوثيق مرتجعات المشتريات للموردين',
            style: TextStyle(color: context.mutedText.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note) {
    final statusColor = note['status'] == 'posted' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.reply_all_rounded, color: Colors.teal),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'إشعار رقم: ${note['id'].toString().substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildStatusChip(note['status'], statusColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('المورد: ${note['supplier_id']}'),
            const SizedBox(height: 2),
            Text('السبب: ${note['reason'] ?? 'غير محدد'}', style: TextStyle(color: context.mutedText, fontSize: 12)),
          ],
        ),
        trailing: Text(
          '${(note['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} ر.س',
          style: TextStyle(
            color: Colors.teal.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status, Color color) {
    bool isPosted = status == 'posted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        isPosted ? 'تم الترحيل' : 'مسودة',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddNoteDialog() {
    final purchaseIdCtrl = TextEditingController();
    final supplierIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إصدار إشعار مدين', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: supplierIdCtrl, decoration: const InputDecoration(labelText: 'معرف المورد', prefixIcon: Icon(Icons.business))),
              const SizedBox(height: 12),
              TextField(controller: purchaseIdCtrl, decoration: const InputDecoration(labelText: 'رقم فاتورة المشتريات', prefixIcon: Icon(Icons.inventory_2))),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'المبلغ', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'السبب', prefixIcon: Icon(Icons.info_outline))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: context.mutedText))),
          ElevatedButton(
            onPressed: () async {
              if (supplierIdCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              
              final success = await _engine.processDebitNote(
                originalPurchaseId: purchaseIdCtrl.text,
                supplierId: supplierIdCtrl.text,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                reason: reasonCtrl.text,
                items: [], // Simplified for now
              );

              if (success && mounted) {
                Navigator.pop(ctx);
                _loadNotes();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ترحيل الإشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

