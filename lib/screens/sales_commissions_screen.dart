import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class SalesCommissionsScreen extends StatefulWidget {
  const SalesCommissionsScreen({super.key});
  @override
  State<SalesCommissionsScreen> createState() => _SalesCommissionsScreenState();
}

class _SalesCommissionsScreenState extends State<SalesCommissionsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _salespeople = [];
  List<Map<String, dynamic>> _commissions = [];

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

      // Get employees with sales role
      final employees = await db.rawQuery('''
        SELECT e.id, e.name, e.department,
          COALESCE((SELECT SUM(i.total) FROM invoices i WHERE i.salesperson_id = e.id), 0) as total_sales,
          COALESCE((SELECT COUNT(*) FROM invoices i WHERE i.salesperson_id = e.id), 0) as invoice_count
        FROM employees e
        ORDER BY total_sales DESC
      ''');

      // Get commissions log
      final comms = await db.rawQuery('''
        SELECT c.*, e.name as employee_name FROM commissions c
        LEFT JOIN employees e ON c.employee_id = e.id
        ORDER BY c.created_at DESC LIMIT 50
      ''');

      if (mounted) setState(() {
        _salespeople = employees.map((e) => Map<String, dynamic>.from(e)).toList();
        _commissions = comms.map((c) => Map<String, dynamic>.from(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Commissions error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateCommissions() async {
    try {
      final db = await _db.database;
      final commissionRate = 0.05; // 5% default

      for (var sp in _salespeople) {
        final totalSales = (sp['total_sales'] as num?)?.toDouble() ?? 0;
        if (totalSales > 0) {
          final commission = totalSales * commissionRate;
          await db.insert('commissions', {
            'id': 'COM_${DateTime.now().millisecondsSinceEpoch}_${sp['id']}',
            'employee_id': sp['id'],
            'amount': commission,
            'rate': commissionRate,
            'sales_amount': totalSales,
            'period': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حساب العمولات"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSales = _salespeople.fold<double>(0, (s, sp) => s + ((sp['total_sales'] as num?)?.toDouble() ?? 0));
    final totalCommissions = _commissions.fold<double>(0, (s, c) => s + ((c['amount'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("عمولات المبيعات", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("إجمالي: ${totalSales.toStringAsFixed(0)} • عمولات: ${totalCommissions.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
            ])),
            GestureDetector(
              onTap: _calculateCommissions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calculate, size: 14, color: Colors.black87), SizedBox(width: 4),
                  Text("حساب العمولات", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
          child: TabBar(
            controller: _tabController, isScrollable: false,
            labelColor: Colors.black87, unselectedLabelColor: context.mutedText,
            indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
            indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
            tabs: const [Tab(text: "المندوبين"), Tab(text: "سجل العمولات")],
          ),
        ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : TabBarView(controller: _tabController, children: [
                _buildSalespeopleTab(),
                _buildCommissionsLog(),
              ]),
        ),
      ]),
    );
  }

  Widget _buildSalespeopleTab() {
    if (_salespeople.isEmpty) return Center(child: Text("لا يوجد موظفين", style: TextStyle(color: context.mutedText)));
    return ListView.builder(
      padding: EdgeInsets.all(context.sectionPadding),
      itemCount: _salespeople.length,
      itemBuilder: (_, i) {
        final sp = _salespeople[i];
        final sales = (sp['total_sales'] as num?)?.toDouble() ?? 0;
        final count = (sp['invoice_count'] as num?)?.toInt() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cardBorder.withValues(alpha: 0.08))),
          child: Row(children: [
            Container(
              width: 36, height: 36, alignment: Alignment.center,
              decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Text("${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sp['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
              Text("$count فاتورة • ${sp['department'] ?? ''}", style: TextStyle(color: context.mutedText, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${sales.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: context.bodySize + 1)),
              Text("عمولة: ${(sales * 0.05).toStringAsFixed(0)}", style: TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildCommissionsLog() {
    if (_commissions.isEmpty) return Center(child: Text("لا توجد عمولات محسوبة", style: TextStyle(color: context.mutedText)));
    return ListView.builder(
      padding: EdgeInsets.all(context.sectionPadding),
      itemCount: _commissions.length,
      itemBuilder: (_, i) {
        final c = _commissions[i];
        final amount = (c['amount'] as num?)?.toDouble() ?? 0;
        final status = c['status']?.toString() ?? 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['employee_name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
              Text("فترة: ${c['period'] ?? ''} • ${c['created_at']?.toString().substring(0, 10) ?? ''}", style: TextStyle(color: context.mutedText, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: (status == 'paid' ? Colors.green : Colors.orange).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status == 'paid' ? "مدفوع" : "معلق", style: TextStyle(color: status == 'paid' ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        );
      },
    );
  }
}
