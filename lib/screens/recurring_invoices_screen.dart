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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = _recurring.where((r) => r['is_active'] == 1).length;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildSummaryRow(activeCount),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'التفاصيل',
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_outline, size: 16, color: Colors.greenAccent),
                  label: const Text('تشغيل الكل الان', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                )
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                : _recurring.isEmpty 
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _recurring.length,
                      itemBuilder: (context, index) => _buildRecurringCard(context, _recurring[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: primaryOrange,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  tr('recurring.title'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
                ),
              ],
            ),
            Text(
              'جدولة وأتمتة العمليات المالية',
              style: TextStyle(color: context.mutedText, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(int activeCount) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('الإجمالي', '${_recurring.length}', Colors.blueAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('النشطة', '$activeCount', Colors.greenAccent)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = item['is_active'] == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.autorenew, color: Colors.orangeAccent, size: 16),
        ),
        title: Text(
          item['description'] ?? tr('common.unknown'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          'التشغيل القادم: ${item['next_run_date'] ?? '-'}',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: isActive,
                onChanged: (val) => _toggleActive(item['id'], val),
                activeColor: Colors.orangeAccent,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              onPressed: () {}, // Delete logic if needed
            )
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
    String frequency = 'monthly';

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
                  DropdownMenuItem(value: 'daily', child: Text(tr('recurring.daily'))),
                  DropdownMenuItem(value: 'weekly', child: Text(tr('recurring.weekly'))),
                  DropdownMenuItem(value: 'monthly', child: Text(tr('recurring.monthly'))),
                  DropdownMenuItem(value: 'yearly', child: Text(tr('recurring.yearly'))),
                ],
                onChanged: (val) => setDialogState(() => frequency = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'), style: TextStyle(color: context.mutedText))),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الوصف والمبلغ')));
                  return;
                }
                
                try {
                  final db = await _db.database;
                  DateTime nextDate;
                  switch (frequency) {
                    case 'daily': nextDate = DateTime.now().add(const Duration(days: 1)); break;
                    case 'weekly': nextDate = DateTime.now().add(const Duration(days: 7)); break;
                    case 'yearly': nextDate = DateTime.now().add(const Duration(days: 365)); break;
                    case 'monthly': 
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
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                  }
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

