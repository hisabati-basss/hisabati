import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class BudgetMonitoringScreen extends StatefulWidget {
  const BudgetMonitoringScreen({super.key});
  @override
  State<BudgetMonitoringScreen> createState() => _BudgetMonitoringScreenState();
}

class _BudgetMonitoringScreenState extends State<BudgetMonitoringScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _comparisons = [];
  bool _isLoading = true;
  double _totalBudget = 0;
  double _totalActual = 0;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      final budgets = await db.query('budgets');
      
      List<Map<String, dynamic>> comparisons = [];
      double totalBudget = 0;
      double totalActual = 0;

      for (var budget in budgets) {
        final accountId = budget['account_id']?.toString() ?? '';
        final budgetAmount = (budget['budget_amount'] as num?)?.toDouble() ?? 0;

        // Get account info
        final accInfo = await db.query('accounts', where: 'id = ?', whereArgs: [accountId]);
        final accName = accInfo.isNotEmpty ? accInfo.first['name']?.toString() ?? '' : 'غير معروف';
        final accCode = accInfo.isNotEmpty ? accInfo.first['code']?.toString() ?? '' : '';
        final accType = accInfo.isNotEmpty ? accInfo.first['type']?.toString() ?? '' : '';

        // Get actual spend from journal entries
        final actualRes = await db.rawQuery('''
          SELECT COALESCE(SUM(CASE WHEN ? = 'expense' THEN debit ELSE credit END), 0) as actual
          FROM journal_entry_lines WHERE account_id = ?
        ''', [accType, accountId]);
        final actual = (actualRes.first['actual'] as num?)?.toDouble() ?? 0;

        final variance = budgetAmount - actual;
        final pct = budgetAmount > 0 ? (actual / budgetAmount * 100) : 0.0;

        totalBudget += budgetAmount;
        totalActual += actual;

        comparisons.add({
          'account_name': "$accCode $accName",
          'budget': budgetAmount,
          'actual': actual,
          'variance': variance,
          'pct': pct,
          'period': budget['period']?.toString() ?? 'monthly',
        });
      }

      comparisons.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));

      if (mounted) setState(() {
        _comparisons = comparisons;
        _totalBudget = totalBudget;
        _totalActual = totalActual;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Budget monitor: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVariance = _totalBudget - _totalActual;
    final overallPct = _totalBudget > 0 ? (_totalActual / _totalBudget * 100) : 0.0;
    final overruns = _comparisons.where((c) => (c['pct'] as double) > 100).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("مراقبة الميزانية", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text(overruns == 0 ? "✅ جميع البنود ضمن الميزانية" : "⚠️ $overruns بند تجاوز الميزانية",
                style: TextStyle(color: overruns == 0 ? Colors.green : Colors.red, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            ])),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryOrange.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh, size: 14, color: primaryOrange), const SizedBox(width: 4),
                  Text("تحديث", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Summary KPIs
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Row(children: [
            Expanded(child: _buildKPI("الميزانية", _totalBudget.toStringAsFixed(0), Colors.blue)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI("الفعلي", _totalActual.toStringAsFixed(0), _totalActual > _totalBudget ? Colors.red : Colors.green)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI("الفرق", totalVariance.toStringAsFixed(0), totalVariance >= 0 ? Colors.green : Colors.red)),
            const SizedBox(width: 6),
            Expanded(child: _buildKPI("الاستخدام", "${overallPct.toStringAsFixed(0)}%", overallPct > 100 ? Colors.red : overallPct > 80 ? Colors.orange : Colors.green)),
          ]),
        ),
        const SizedBox(height: 10),

        // Table Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(flex: 2, child: Text("البند", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(child: Text("الميزانية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(child: Text("الفعلي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Expanded(child: Text("النسبة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ]),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _comparisons.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.insights, size: 48, color: context.mutedText.withValues(alpha: 0.2)),
                const SizedBox(height: 8), Text("أضف بنود ميزانية أولاً", style: TextStyle(color: context.mutedText)),
              ]))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
                itemCount: _comparisons.length,
                itemBuilder: (_, i) => _buildComparisonRow(_comparisons[i], i),
              ),
        ),
      ]),
    );
  }

  Widget _buildComparisonRow(Map<String, dynamic> c, int index) {
    final budget = (c['budget'] as double);
    final actual = (c['actual'] as double);
    final pct = (c['pct'] as double);
    final isOver = pct > 100;
    final color = isOver ? Colors.red : pct > 80 ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.transparent : context.cardSurface.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.05))),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(flex: 2, child: Text(c['account_name'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(budget.toStringAsFixed(0), style: TextStyle(fontSize: 11))),
          Expanded(child: Text(actual.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text("${pct.toStringAsFixed(0)}%", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          )),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1.5),
            minHeight: 3,
            backgroundColor: context.cardSurface.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }

  Widget _buildKPI(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.mutedText, fontSize: 9)),
        const SizedBox(height: 2),
        FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color))),
      ]),
    );
  }
}
