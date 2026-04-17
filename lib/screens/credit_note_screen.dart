import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';
import '../core/config/app_constants.dart';

class CreditNoteScreen extends StatefulWidget {
  const CreditNoteScreen({super.key});

  @override
  State<CreditNoteScreen> createState() => _CreditNoteScreenState();
}

class _CreditNoteScreenState extends State<CreditNoteScreen> {
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
      final db = await _db.database;
      final res = await db.query('credit_notes', where: 'is_deleted = 0', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _notes = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading credit notes: $e");
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
              'الإشعارات الدائنة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textColor),
            ),
            Text(
              'إدارة مرتجعات المبيعات والتسويات الضريبية',
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
        onPressed: () => _showCreateDialog(context),
        label: const Text('إشعار دائن جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.assignment_return, color: Colors.white),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_return_outlined, size: 80, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات دائنة حالياً',
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'استخدم الإشعارات الدائنة لتوثيق مرتجعات المبيعات',
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
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.undo_rounded, color: Colors.orange),
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
            Text('العميل: ${note['client_id']}'),
            const SizedBox(height: 2),
            Text('السبب: ${note['reason'] ?? 'غير محدد'}', style: TextStyle(color: context.mutedText, fontSize: 12)),
          ],
        ),
        trailing: Text(
          '${(note['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} ر.س',
          style: TextStyle(
            color: Colors.orange.shade800,
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

  void _showCreateDialog(BuildContext context) {
    final invoiceIdCtrl = TextEditingController();
    final clientIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إصدار إشعار دائن', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clientIdCtrl, decoration: const InputDecoration(labelText: 'معرف العميل', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(controller: invoiceIdCtrl, decoration: const InputDecoration(labelText: 'رقم الفاتورة الأصلية', prefixIcon: Icon(Icons.receipt))),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'المبلغ المسترد', prefixIcon: Icon(Icons.money)), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'سبب الارتجاع', prefixIcon: Icon(Icons.info_outline))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: context.mutedText))),
          ElevatedButton(
            onPressed: () async {
              if (clientIdCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              
              final success = await _engine.processCreditNote(
                invoiceId: invoiceIdCtrl.text,
                clientId: clientIdCtrl.text,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                reason: reasonCtrl.text,
                items: [], // Simplified for now
                returnToStock: false,
              );

              if (success && mounted) {
                Navigator.pop(ctx);
                _loadNotes();
              }
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ترحيل الإشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

