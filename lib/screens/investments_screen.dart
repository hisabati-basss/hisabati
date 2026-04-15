import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _investments = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      _investments = (await db.query('investments', orderBy: 'created_at DESC')).map((i) => Map<String, dynamic>.from(i)).toList();
      _transactions = (await db.rawQuery('''
        SELECT it.*, inv.name as investment_name FROM investment_transactions it
        LEFT JOIN investments inv ON it.investment_id = inv.id
        ORDER BY it.date DESC LIMIT 50
      ''')).map((t) => Map<String, dynamic>.from(t)).toList();
    } catch (e) { debugPrint("Investments: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final returnCtrl = TextEditingController(text: "8");
    String type = 'stock';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: context.cardSurface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("استثمار جديد", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _input(nameCtrl, "اسم الاستثمار *"),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _input(amountCtrl, "المبلغ المستثمر", isNum: true)),
            const SizedBox(width: 8),
            Expanded(child: _input(returnCtrl, "العائد المتوقع %", isNum: true)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _typeChip("أسهم", 'stock', type, (v) => setDialogState(() => type = v)),
            const SizedBox(width: 6),
            _typeChip("عقارات", 'real_estate', type, (v) => setDialogState(() => type = v)),
            const SizedBox(width: 6),
            _typeChip("صناديق", 'fund', type, (v) => setDialogState(() => type = v)),
            const SizedBox(width: 6),
            _typeChip("أخرى", 'other', type, (v) => setDialogState(() => type = v)),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("إلغاء", style: TextStyle(color: context.mutedText))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final db = await _db.database;
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              await db.insert('investments', {
                'id': 'INV_${DateTime.now().millisecondsSinceEpoch}',
                'name': nameCtrl.text.trim(),
                'type': type,
                'initial_amount': amount,
                'current_value': amount,
                'expected_return': (double.tryParse(returnCtrl.text) ?? 8) / 100,
                'status': 'active',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
              if (mounted) { Navigator.pop(ctx); _loadData(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black87),
            child: const Text("حفظ"),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalInvested = _investments.fold<double>(0, (s, i) => s + ((i['initial_amount'] as num?)?.toDouble() ?? 0));
    final totalCurrent = _investments.fold<double>(0, (s, i) => s + ((i['current_value'] as num?)?.toDouble() ?? 0));
    final pnl = totalCurrent - totalInvested;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("إدارة الاستثمارات", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("${_investments.length} استثمار • الربح/الخسارة: ${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(0)}", style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            ])),
            GestureDetector(onTap: _showAddDialog, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: Colors.black87), SizedBox(width: 4), Text("استثمار جديد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12))]),
            )),
          ]),
        ),
        const SizedBox(height: 8),
        // KPIs
        Padding(padding: EdgeInsets.symmetric(horizontal: context.sectionPadding), child: Row(children: [
          Expanded(child: _buildKPI("المستثمر", totalInvested.toStringAsFixed(0), Colors.blue)),
          const SizedBox(width: 6),
          Expanded(child: _buildKPI("القيمة الحالية", totalCurrent.toStringAsFixed(0), Colors.purple)),
          const SizedBox(width: 6),
          Expanded(child: _buildKPI("صافي الربح", pnl.toStringAsFixed(0), pnl >= 0 ? Colors.green : Colors.red)),
        ])),
        const SizedBox(height: 8),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.sectionPadding),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
          child: TabBar(controller: _tabController, isScrollable: false, labelColor: Colors.black87, unselectedLabelColor: context.mutedText,
            indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)), indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
            tabs: const [Tab(text: "المحفظة"), Tab(text: "المعاملات")]),
        ),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : TabBarView(controller: _tabController, children: [_buildPortfolioTab(), _buildTransactionsTab()])),
      ]),
    );
  }

  Widget _buildPortfolioTab() {
    if (_investments.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.trending_up, size: 48, color: context.mutedText.withValues(alpha: 0.2)), const SizedBox(height: 8),
      Text("أضف استثمارات للبدء", style: TextStyle(color: context.mutedText)),
    ]));
    return ListView.builder(padding: EdgeInsets.all(context.sectionPadding), itemCount: _investments.length, itemBuilder: (_, i) {
      final inv = _investments[i];
      final initial = (inv['initial_amount'] as num?)?.toDouble() ?? 0;
      final current = (inv['current_value'] as num?)?.toDouble() ?? 0;
      final pnl = current - initial;
      final pnlPct = initial > 0 ? (pnl / initial * 100) : 0.0;
      final type = inv['type']?.toString() ?? '';
      return Container(
        margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: (pnl >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: (pnl >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.12))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _typeColor(type).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_typeIcon(type), size: 16, color: _typeColor(type))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inv['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            Text("${_typeLabel(type)} • مستثمر: ${initial.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${current.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 1)),
            Text("${pnl >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%", style: TextStyle(color: pnl >= 0 ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ]),
      );
    });
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) return Center(child: Text("لا توجد معاملات", style: TextStyle(color: context.mutedText)));
    return ListView.builder(padding: EdgeInsets.all(context.sectionPadding), itemCount: _transactions.length, itemBuilder: (_, i) {
      final t = _transactions[i];
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final type = t['type']?.toString() ?? 'buy';
      return Container(
        margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(type == 'buy' ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: type == 'buy' ? Colors.blue : Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['investment_name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
            Text("${type == 'buy' ? 'شراء' : 'بيع'} • ${t['date']?.toString().substring(0, 10) ?? ''}", style: TextStyle(color: context.mutedText, fontSize: 10)),
          ])),
          Text("${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: type == 'buy' ? Colors.blue : Colors.green)),
        ]),
      );
    });
  }

  Widget _buildKPI(String t, String v, Color c) => Container(
    padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.15))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: context.mutedText, fontSize: 9)), const SizedBox(height: 2), FittedBox(child: Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c)))]),
  );

  Widget _typeChip(String label, String value, String sel, Function(String) onTap) {
    final s = sel == value;
    return GestureDetector(onTap: () => onTap(value), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: s ? primaryOrange : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: s ? primaryOrange : context.cardBorder)),
      child: Text(label, style: TextStyle(color: s ? Colors.black87 : context.mutedText, fontWeight: FontWeight.bold, fontSize: 11)),
    ));
  }

  Widget _input(TextEditingController c, String h, {bool isNum = false}) => TextField(
    controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, style: TextStyle(color: context.textColor, fontSize: 13),
    decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: context.mutedText, fontSize: 12), filled: true, fillColor: context.cardSurface.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
  );

  Color _typeColor(String t) { switch(t) { case 'stock': return Colors.blue; case 'real_estate': return Colors.teal; case 'fund': return Colors.purple; default: return Colors.grey; } }
  IconData _typeIcon(String t) { switch(t) { case 'stock': return Icons.candlestick_chart; case 'real_estate': return Icons.domain; case 'fund': return Icons.account_balance; default: return Icons.trending_up; } }
  String _typeLabel(String t) { switch(t) { case 'stock': return 'أسهم'; case 'real_estate': return 'عقارات'; case 'fund': return 'صناديق'; default: return 'أخرى'; } }
}
