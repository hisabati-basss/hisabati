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
          // Premium Glows
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryOrange.withValues(alpha: 0.05)),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton.icon(
                      onPressed: _processAll,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.play_circle_outline, color: Colors.greenAccent, size: 20),
                      label: const Text('تشغيل الكل الآن', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          tr('recurring.title'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          tr('recurring.subtitle'),
          style: TextStyle(color: context.mutedText, fontSize: 12),
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
              blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: TextStyle(color: context.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
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
        
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger Blur
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => _deleteSchedule(s['id']),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      onChanged: (v) => _toggleActive(s['id'], v),
                      activeColor: primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          s['description'] ?? 'بدون وصف',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87, 
                            fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${tr('recurring.next_run')}: ${s['next_run_date']}',
                              style: const TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('recurring.' + s['frequency'].toString().toLowerCase()),
                              style: TextStyle(color: context.mutedText, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: (isActive ? primaryOrange : Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive ? Icons.auto_mode : Icons.pause_circle_outline,
                      color: isActive ? primaryOrange : Colors.grey,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
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
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_send, color: primaryOrange, size: 48),
                    const SizedBox(height: 16),
                    Text(tr('recurring.add'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الوصف (مثلاً: إيجار المكتب)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      dropdownColor: Colors.grey.shade900,
                      style: const TextStyle(color: Colors.white),
                      items: ['daily', 'weekly', 'monthly', 'yearly']
                          .map((f) => DropdownMenuItem(value: f, child: Text(tr('recurring.' + f))))
                          .toList(),
                      onChanged: (v) => setDialogState(() => frequency = v!),
                      decoration: InputDecoration(
                        labelText: tr('recurring.frequency'),
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(tr('common.cancel'), style: const TextStyle(color: Colors.white54)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                            child: Text(tr('common.save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
