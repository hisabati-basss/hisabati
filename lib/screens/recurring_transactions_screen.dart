import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final schedules = await _db.getRecurringTransactions();
    setState(() {
      _schedules = schedules.where((s) => (s['is_deleted'] ?? 0) == 0).toList();
      _isLoading = false;
    });
  }

  Future<void> _processAll() async {
    setState(() => _isLoading = true);
    await _db.processRecurringTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('recurring.processed_success'))),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium Glow
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildStatsSummary(context),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('common.details'),
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton.icon(
                      onPressed: _processAll,
                      icon: const Icon(Icons.play_circle_outline, color: Colors.greenAccent),
                      label: Text('تشغيل الكل الآن', style: TextStyle(color: context.textColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _schedules.isEmpty
                          ? _buildEmptyState()
                          : _buildSchedulesList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: sunsetStart,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('recurring.title'),
              style: TextStyle(color: context.textColor, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              tr('recurring.subtitle'),
              style: TextStyle(color: context.mutedText, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    int activeCount = _schedules.where((s) => s['is_active'] == 1).length;
    return Row(
      children: [
        _buildStatCard(context, 'النشطة', activeCount.toString(), Colors.greenAccent),
        const SizedBox(width: 16),
        _buildStatCard(context, 'الإجمالي', _schedules.length.toString(), sunsetStart),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: context.mutedText, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesList() {
    return ListView.separated(
      itemCount: _schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = _schedules[index];
        bool isActive = s['is_active'] == 1;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isActive ? Colors.blueAccent : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.auto_mode : Icons.pause_circle_outline,
                  color: isActive ? Colors.blueAccent : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['description'] ?? 'بدون وصف',
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tr('recurring.frequency')}: ${tr('recurring.' + s['frequency'])}',
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                    Text(
                      '${tr('recurring.next_run')}: ${s['next_run_date']}',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (v) => _toggleActive(s['id'], v),
                activeColor: sunsetStart,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteSchedule(s['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_send, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('لا يوجد معاملات مجدولة حالياً', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String frequency = 'monthly';
    String type = 'journal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('recurring.add')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'الوصف (مثلاً: إيجار المكتب)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  items: ['daily', 'weekly', 'monthly', 'yearly']
                      .map((f) => DropdownMenuItem(value: f, child: Text(tr('recurring.' + f))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => frequency = v!),
                  decoration: InputDecoration(labelText: tr('recurring.frequency')),
                ),
                const SizedBox(height: 16),
                const Text('نوع العملية: قيد يومي تلقائي', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.isNotEmpty) {
                  await _db.addRecurringTransaction({
                    'description': descController.text,
                    'frequency': frequency,
                    'type': 'journal',
                    'next_run_date': DateTime.now().toIso8601String().split('T')[0],
                    'template_data': jsonEncode({
                      'lines': [
                        {'account_id': 'ACC_CASH', 'debit': 0.0, 'credit': 100.0},
                        {'account_id': 'ACC_EXPENSE', 'debit': 100.0, 'credit': 0.0},
                      ]
                    }),
                  });
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(String id, bool active) async {
    await _db.updateRecurringTransactionStatus(id, active ? 1 : 0);
    _loadData();
  }

  Future<void> _deleteSchedule(String id) async {
    await _db.deleteRecurringTransaction(id);
    _loadData();
  }
}
