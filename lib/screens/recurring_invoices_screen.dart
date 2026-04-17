import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class RecurringInvoicesScreen extends StatefulWidget {
  const RecurringInvoicesScreen({super.key});

  @override
  State<RecurringInvoicesScreen> createState() => _RecurringInvoicesScreenState();
}

class _RecurringInvoicesScreenState extends State<RecurringInvoicesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _recurring = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecurring();
  }

  Future<void> _loadRecurring() async {
    try {
      final db = await _db.database;
      final res = await db.query('recurring_transactions', where: 'is_deleted = 0');
      if (mounted) {
        setState(() {
          _recurring = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading recurring: $e");
      if (mounted) {
        setState(() {
          _recurring = [];
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
              tr('recurring.title'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textColor),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : _recurring.isEmpty 
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: EdgeInsets.all(context.sectionPadding),
              itemCount: _recurring.length,
              itemBuilder: (context, index) => _buildRecurringCard(context, _recurring[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: Text(tr('recurring.new_template'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.autorenew, color: Colors.white),
        backgroundColor: Colors.purple.shade700,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            tr('common.no_data'),
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'أتمتة عمليات الفوترة الدورية لتوفير الوقت',
            style: TextStyle(color: context.mutedText.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringCard(BuildContext context, Map<String, dynamic> item) {
    final isActive = item['is_active'] == 1;
    
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
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.refresh_rounded, color: Colors.purple),
        ),
        title: Text(
          item['description'] ?? tr('common.unknown'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${tr('recurring.frequency')}: ${item['frequency'] ?? tr('recurring.monthly')}', style: TextStyle(color: context.textColor, fontSize: 13)),
            const SizedBox(height: 2),
            Text('${tr('recurring.next_run')}: ${item['next_run_date'] ?? tr('common.unknown')}', style: TextStyle(color: context.mutedText, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(item['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} ${tr('common.currency_symbol')}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isActive,
              onChanged: (val) => _toggleActive(item['id'], val),
              activeColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(String id, bool active) async {
    final db = await _db.database;
    await db.update('recurring_transactions', {'is_active': active ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    _loadRecurring();
  }

  void _showAddDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String frequency = 'شهري';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('recurring.new_template'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl, 
                decoration: InputDecoration(labelText: tr('recurring.description'), prefixIcon: const Icon(Icons.description))
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl, 
                decoration: InputDecoration(labelText: tr('recurring.amount'), prefixIcon: const Icon(Icons.money)), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: InputDecoration(labelText: tr('recurring.frequency'), prefixIcon: const Icon(Icons.event_repeat)),
                items: [
                  DropdownMenuItem(value: 'Daily', child: Text(tr('recurring.daily'))),
                  DropdownMenuItem(value: 'Weekly', child: Text(tr('recurring.weekly'))),
                  DropdownMenuItem(value: 'Monthly', child: Text(tr('recurring.monthly'))),
                  DropdownMenuItem(value: 'Yearly', child: Text(tr('recurring.yearly'))),
                ],
                onChanged: (val) => setDialogState(() => frequency = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'), style: TextStyle(color: context.mutedText))),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                final db = await _db.database;
                DateTime nextDate;
                switch (frequency) {
                  case 'Daily': nextDate = DateTime.now().add(const Duration(days: 1)); break;
                  case 'Weekly': nextDate = DateTime.now().add(const Duration(days: 7)); break;
                  case 'Yearly': nextDate = DateTime.now().add(const Duration(days: 365)); break;
                  case 'Monthly': 
                  default: nextDate = DateTime.now().add(const Duration(days: 30)); break;
                }

                await db.insert('recurring_transactions', {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'description': descCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'frequency': frequency,
                  'next_run_date': nextDate.toIso8601String().split('T')[0],
                  'is_active': 1,
                  'created_at': DateTime.now().toIso8601String(),
                  'is_deleted': 0,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadRecurring();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('recurring.start_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

