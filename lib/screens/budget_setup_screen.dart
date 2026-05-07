import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});
  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      _budgets = (await db.query('budgets', orderBy: 'created_at DESC')).map((b) => Map<String, dynamic>.from(b)).toList();
      _accounts = (await db.rawQuery("SELECT id, code, name, type FROM accounts WHERE type IN ('expense','revenue') ORDER BY code")).map((a) => Map<String, dynamic>.from(a)).toList();
    } catch (e) { debugPrint("Budget load: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showBudgetDialog({Map<String, dynamic>? budget}) {
    final isEdit = budget != null;
    String? selectedAccountId = budget?['account_id']?.toString();
    final amountCtrl = TextEditingController(text: budget?['budget_amount']?.toString());
    String period = budget?['period']?.toString() ?? 'monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(context.cardPadding * 2),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF1A1A1F) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: context.mutedText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  isEdit ? "تعديل الميزانية" : "ميزانية جديدة", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize + 2, color: context.textColor)
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    value: selectedAccountId,
                    dropdownColor: context.bgSurface,
                    hint: Text("اختر الحساب", style: TextStyle(color: context.mutedText, fontSize: 13)),
                    items: _accounts.map((a) => DropdownMenuItem(
                      value: a['id'] as String, 
                      child: Text("${a['code']} ${a['name']}", style: TextStyle(fontSize: 14, color: context.textColor))
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedAccountId = v),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    labelText: "المبلغ المخصص",
                    labelStyle: TextStyle(color: context.mutedText),
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: context.cardSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _periodChip("شهري", 'monthly', period, (v) => setDialogState(() => period = v)),
                    const SizedBox(width: 8),
                    _periodChip("ربع سنوي", 'quarterly', period, (v) => setDialogState(() => period = v)),
                    const SizedBox(width: 8),
                    _periodChip("سنوي", 'yearly', period, (v) => setDialogState(() => period = v)),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("إلغاء", style: TextStyle(color: context.mutedText)),
                      ),
                    ),
                    if (isEdit) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final db = await _db.database;
                            await db.delete('budgets', where: 'id = ?', whereArgs: [budget!['id']]);
                            if (mounted) { Navigator.pop(ctx); _loadData(); }
                          },
                          child: const Text("حذف", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedAccountId == null || amountCtrl.text.isEmpty) return;
                          final db = await _db.database;
                          final data = {
                            'account_id': selectedAccountId,
                            'budget_amount': double.tryParse(amountCtrl.text) ?? 0,
                            'period': period,
                            'updated_at': DateTime.now().toIso8601String(),
                          };
                          if (isEdit) {
                            await db.update('budgets', data, where: 'id = ?', whereArgs: [budget!['id']]);
                          } else {
                            data['id'] = 'BUD_${DateTime.now().millisecondsSinceEpoch}';
                            data['created_at'] = DateTime.now().toIso8601String();
                            await db.insert('budgets', data);
                          }
                          if (mounted) { Navigator.pop(ctx); _loadData(); }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEdit ? "تحديث" : "حفظ", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _budgets.fold<double>(0, (s, b) => s + ((b['budget_amount'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("إعداد الميزانية", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("${_budgets.length} بند • إجمالي: ${totalBudget.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
            ])),
            GestureDetector(
              onTap: () => _showBudgetDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: Colors.black87), SizedBox(width: 4),
                  Text("بند جديد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _budgets.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.pie_chart, size: 48, color: context.mutedText.withValues(alpha: 0.2)),
                const SizedBox(height: 8), Text("لا توجد بنود ميزانية", style: TextStyle(color: context.mutedText)),
              ]))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                itemCount: _budgets.length,
                itemBuilder: (_, i) {
                  final b = _budgets[i];
                  final accountName = _accounts.firstWhere((a) => a['id'] == b['account_id'], orElse: () => {'name': 'غير معروف', 'code': ''});
                  return GestureDetector(
                    onTap: () => _showBudgetDialog(budget: b),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cardBorder.withValues(alpha: 0.08))),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.pie_chart, size: 16, color: primaryOrange)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("${accountName['code']} ${accountName['name']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                          Text(_periodLabel(b['period']?.toString() ?? 'monthly'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                        ])),
                        Text("${((b['budget_amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryOrange, fontSize: context.bodySize + 2)),
                      ]),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }

  Widget _periodChip(String label, String value, String selected, Function(String) onTap) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: sel ? primaryOrange : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: sel ? primaryOrange : context.cardBorder)),
        child: Text(label, style: TextStyle(color: sel ? Colors.black87 : context.mutedText, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  String _periodLabel(String p) {
    switch (p) { case 'monthly': return 'شهري'; case 'quarterly': return 'ربع سنوي'; case 'yearly': return 'سنوي'; default: return p; }
  }
}
