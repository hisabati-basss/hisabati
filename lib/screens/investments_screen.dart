import 'dart:ui';
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
      _investments = await _db.getInvestments();
      final db = await _db.database;
      try {
        _transactions = (await db.rawQuery('''
          SELECT it.*, inv.name as investment_name FROM investment_transactions it
          LEFT JOIN investments inv ON it.investment_id = inv.id
          ORDER BY it.date DESC LIMIT 50
        ''')).map((t) => Map<String, dynamic>.from(t)).toList();
      } catch (_) {
        _transactions = [];
      }
    } catch (e) { debugPrint("Investments: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'stock';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Center(
                            child: Text(
                              "إضافة استثمار جديد", 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: context.textColor, 
                                fontSize: 18
                              )
                            ),
                          ),
                          const SizedBox(height: 24),
                          _input(nameCtrl, "اسم الاستثمار *"),
                          const SizedBox(height: 12),
                          _input(amountCtrl, "المبلغ المستثمر (ر.س)", isNum: true),
                          const SizedBox(height: 16),
                          Text("نوع الاستثمار", style: TextStyle(color: context.mutedText, fontSize: 11)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              _typeChip("أسهم", 'stock', type, (v) => setDialogState(() => type = v)),
                              _typeChip("عقارات", 'real_estate', type, (v) => setDialogState(() => type = v)),
                              _typeChip("صناديق", 'fund', type, (v) => setDialogState(() => type = v)),
                              _typeChip("أخرى", 'other', type, (v) => setDialogState(() => type = v)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text("إلغاء", style: TextStyle(color: context.mutedText)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (nameCtrl.text.trim().isEmpty) return;
                                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                                    try {
                                      await _db.addInvestment({
                                        'name': nameCtrl.text.trim(),
                                        'type': type,
                                        'initial_amount': amount,
                                        'current_value': amount,
                                        'status': 'active',
                                      });
                                      if (mounted) { 
                                        Navigator.pop(ctx); 
                                        _loadData(); 
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء الحفظ: $e"), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange, 
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                  child: const Text("حفظ الاستثمار", style: TextStyle(fontWeight: FontWeight.bold)),
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
          ),
        );
      },
    );
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
    return GestureDetector(
      onTap: () => onTap(value), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: s ? primaryOrange : Colors.white.withValues(alpha: 0.05), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: s ? primaryOrange : Colors.white.withValues(alpha: 0.1))
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: s ? Colors.black : Colors.white70, 
            fontWeight: FontWeight.bold, 
            fontSize: 11
          )
        ),
      )
    );
  }

  Widget _input(TextEditingController c, String h, {bool isNum = false}) => TextField(
    controller: c, 
    keyboardType: isNum ? TextInputType.number : TextInputType.text, 
    style: const TextStyle(color: Colors.white, fontSize: 14),
    textAlign: TextAlign.right,
    decoration: InputDecoration(
      hintText: h, 
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), 
      filled: true, 
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryOrange)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
    ),
  );

  Color _typeColor(String t) { switch(t) { case 'stock': return Colors.blue; case 'real_estate': return Colors.teal; case 'fund': return Colors.purple; default: return Colors.grey; } }
  IconData _typeIcon(String t) { switch(t) { case 'stock': return Icons.candlestick_chart; case 'real_estate': return Icons.domain; case 'fund': return Icons.account_balance; default: return Icons.trending_up; } }
  String _typeLabel(String t) { switch(t) { case 'stock': return 'أسهم'; case 'real_estate': return 'عقارات'; case 'fund': return 'صناديق'; default: return 'أخرى'; } }
}
