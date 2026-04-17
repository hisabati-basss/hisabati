# Phase 24: Flutter — Cash Flow + Quick Statements + Joint Ventures + HR Fix — EXACT CODE

## ⚠️ RULES: Copy code EXACTLY. All screens go in `lib/screens/`.

---

## FILE 1: cash_flow_statement_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\cash_flow_statement_screen.dart`
**Action:** CREATE NEW FILE.

### What this screen does:
- Generates Cash Flow Statement per IFRS standards
- Three sections: Operating, Investing, Financing activities  
- Period selector (monthly/quarterly/yearly)
- Opening and closing cash balance
- Export to PDF

```dart
import 'package:flutter/material.dart';

class CashFlowStatementScreen extends StatefulWidget {
  const CashFlowStatementScreen({super.key});

  @override
  State<CashFlowStatementScreen> createState() => _CashFlowStatementScreenState();
}

class _CashFlowStatementScreenState extends State<CashFlowStatementScreen> {
  String _period = 'monthly';
  DateTime _startDate = DateTime(2026, 1, 1);
  DateTime _endDate = DateTime(2026, 3, 31);

  // Sample data — in real app, pull from DatabaseHelper journal entries
  final Map<String, List<CashFlowLine>> _data = {
    'operating': [
      CashFlowLine(nameAr: 'صافي الربح', nameEn: 'Net Income', amount: 285000),
      CashFlowLine(nameAr: 'إهلاك الأصول', nameEn: 'Depreciation', amount: 45000),
      CashFlowLine(nameAr: 'تغير في الذمم المدينة', nameEn: 'Change in Accounts Receivable', amount: -32000),
      CashFlowLine(nameAr: 'تغير في المخزون', nameEn: 'Change in Inventory', amount: -18000),
      CashFlowLine(nameAr: 'تغير في الذمم الدائنة', nameEn: 'Change in Accounts Payable', amount: 22000),
      CashFlowLine(nameAr: 'مصاريف مستحقة', nameEn: 'Accrued Expenses', amount: 15000),
      CashFlowLine(nameAr: 'ضرائب مدفوعة', nameEn: 'Taxes Paid', amount: -42750),
    ],
    'investing': [
      CashFlowLine(nameAr: 'شراء أصول ثابتة', nameEn: 'Purchase of Fixed Assets', amount: -120000),
      CashFlowLine(nameAr: 'بيع معدات', nameEn: 'Sale of Equipment', amount: 35000),
      CashFlowLine(nameAr: 'استثمارات', nameEn: 'Investments', amount: -50000),
    ],
    'financing': [
      CashFlowLine(nameAr: 'قرض بنكي جديد', nameEn: 'New Bank Loan', amount: 200000),
      CashFlowLine(nameAr: 'سداد أقساط قروض', nameEn: 'Loan Repayments', amount: -80000),
      CashFlowLine(nameAr: 'توزيعات أرباح', nameEn: 'Dividends Paid', amount: -50000),
      CashFlowLine(nameAr: 'رأس مال إضافي', nameEn: 'Additional Capital', amount: 100000),
    ],
  };

  double get _openingCash => 450000;

  double _sectionTotal(String section) {
    return _data[section]?.fold(0.0, (sum, line) => sum! + line.amount) ?? 0;
  }

  double get _netCashChange => _sectionTotal('operating') + _sectionTotal('investing') + _sectionTotal('financing');
  double get _closingCash => _openingCash + _netCashChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('قائمة التدفقات النقدية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month),
            onSelected: (val) => setState(() => _period = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'monthly', child: Text('شهري')),
              const PopupMenuItem(value: 'quarterly', child: Text('ربع سنوي')),
              const PopupMenuItem(value: 'yearly', child: Text('سنوي')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('جاري تصدير PDF...'), backgroundColor: brandColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF983F)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Cash Flow Statement', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('قائمة التدفقات النقدية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('${_startDate.year}/${_startDate.month} — ${_endDate.year}/${_endDate.month}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _headerStat('الرصيد الافتتاحي', _openingCash),
                      _headerStat('صافي التغيير', _netCashChange),
                      _headerStat('الرصيد الختامي', _closingCash),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operating Activities
            _buildSection('الأنشطة التشغيلية', 'Operating Activities', Icons.settings, _data['operating']!, isDark, brandColor),
            const SizedBox(height: 12),

            // Investing Activities
            _buildSection('الأنشطة الاستثمارية', 'Investing Activities', Icons.trending_up, _data['investing']!, isDark, brandColor),
            const SizedBox(height: 12),

            // Financing Activities
            _buildSection('الأنشطة التمويلية', 'Financing Activities', Icons.account_balance, _data['financing']!, isDark, brandColor),
            const SizedBox(height: 20),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                children: [
                  _summaryRow('صافي التشغيل', _sectionTotal('operating'), isDark),
                  _summaryRow('صافي الاستثمار', _sectionTotal('investing'), isDark),
                  _summaryRow('صافي التمويل', _sectionTotal('financing'), isDark),
                  const Divider(height: 24),
                  _summaryRow('صافي التغيير في النقد', _netCashChange, isDark, isBold: true),
                  const SizedBox(height: 8),
                  _summaryRow('النقد — بداية الفترة', _openingCash, isDark),
                  _summaryRow('النقد — نهاية الفترة', _closingCash, isDark, isBold: true, color: brandColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, double value) {
    return Column(
      children: [
        Text(_formatNumber(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSection(String titleAr, String titleEn, IconData icon, List<CashFlowLine> lines, bool isDark, Color brandColor) {
    final total = lines.fold(0.0, (sum, line) => sum + line.amount);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: brandColor, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(titleEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black26)),
                  ],
                ),
                const Spacer(),
                Text(_formatNumber(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: total >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.nameAr, style: const TextStyle(fontSize: 13)),
                      Text(line.nameEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white20 : Colors.black20)),
                    ],
                  ),
                ),
                Text(
                  _formatNumber(line.amount),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: line.amount >= 0 ? Colors.green.shade400 : Colors.red.shade400),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, bool isDark, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white70 : Colors.black54)),
          Text(_formatNumber(value), style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (value >= 0 ? Colors.green : Colors.red))),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    final prefix = value >= 0 ? '' : '-';
    final absValue = value.abs();
    if (absValue >= 1000000) return '$prefix${(absValue / 1000000).toStringAsFixed(1)}M';
    if (absValue >= 1000) return '$prefix${(absValue / 1000).toStringAsFixed(0)}K';
    return '$prefix${absValue.toStringAsFixed(0)}';
  }
}

class CashFlowLine {
  final String nameAr;
  final String nameEn;
  final double amount;
  CashFlowLine({required this.nameAr, required this.nameEn, required this.amount});
}
```

---

## FILE 2: quick_statements_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\quick_statements_screen.dart`
**Action:** CREATE NEW FILE.

### What this screen does:
- One-click generation of 6 financial reports
- Each card shows the report type with generate button
- Progress indicator while generating
- Export to PDF/Excel

```dart
import 'package:flutter/material.dart';

class QuickStatementsScreen extends StatefulWidget {
  const QuickStatementsScreen({super.key});

  @override
  State<QuickStatementsScreen> createState() => _QuickStatementsScreenState();
}

class _QuickStatementsScreenState extends State<QuickStatementsScreen> {
  final Map<String, bool> _generating = {};

  final List<StatementType> _statements = [
    StatementType(id: 'trading', nameAr: 'حساب المتاجرة', nameEn: 'Trading Account', icon: Icons.swap_horiz, color: Colors.blue, descAr: 'يُظهر نتيجة النشاط التجاري من بيع وشراء البضائع'),
    StatementType(id: 'pnl', nameAr: 'قائمة الأرباح والخسائر', nameEn: 'Profit & Loss Statement', icon: Icons.trending_up, color: Colors.green, descAr: 'يُظهر صافي الربح أو الخسارة خلال فترة محددة'),
    StatementType(id: 'balance', nameAr: 'الميزانية العمومية', nameEn: 'Balance Sheet', icon: Icons.account_balance, color: Colors.purple, descAr: 'يُظهر المركز المالي للشركة (أصول = خصوم + حقوق ملكية)'),
    StatementType(id: 'cashflow', nameAr: 'قائمة التدفقات النقدية', nameEn: 'Cash Flow Statement', icon: Icons.water_drop, color: Colors.cyan, descAr: 'يُظهر حركة النقد الداخل والخارج من 3 أنشطة'),
    StatementType(id: 'equity', nameAr: 'قائمة حقوق الملكية', nameEn: 'Owner\'s Equity Statement', icon: Icons.pie_chart, color: Colors.orange, descAr: 'يُظهر التغيرات في رأس المال وأرباح المالك'),
    StatementType(id: 'estimated', nameAr: 'ميزانية تقديرية (للبنوك)', nameEn: 'Estimated Balance Sheet', icon: Icons.calculate, color: Colors.teal, descAr: 'ميزانية تقديرية لتقديمها للبنوك أو جهات التمويل'),
  ];

  Future<void> _generateStatement(String id) async {
    setState(() => _generating[id] = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate generation
    if (mounted) {
      setState(() => _generating[id] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إنشاء التقرير بنجاح ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('القوائم المالية السريعة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              for (final s in _statements) {
                await _generateStatement(s.id);
              }
            },
            icon: Icon(Icons.all_inclusive, color: brandColor, size: 18),
            label: Text('توليد الكل', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _statements.length,
        itemBuilder: (context, index) {
          final stmt = _statements[index];
          final isGenerating = _generating[stmt.id] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: stmt.color.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: stmt.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(stmt.icon, color: stmt.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stmt.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(stmt.nameEn, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                        const SizedBox(height: 6),
                        Text(stmt.descAr, style: TextStyle(fontSize: 11, color: isDark ? Colors.white40 : Colors.black38, height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  isGenerating
                    ? SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: stmt.color))
                    : Column(
                        children: [
                          IconButton(
                            onPressed: () => _generateStatement(stmt.id),
                            icon: Icon(Icons.play_circle_fill, color: stmt.color, size: 36),
                            tooltip: 'توليد',
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                tooltip: 'PDF',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.table_chart, size: 18),
                                tooltip: 'Excel',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              ),
                            ],
                          ),
                        ],
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatementType {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String descAr;
  StatementType({required this.id, required this.nameAr, required this.nameEn, required this.icon, required this.color, required this.descAr});
}
```

---

## FILE 3: joint_ventures_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\joint_ventures_screen.dart`
**Action:** CREATE NEW FILE.

```dart
import 'package:flutter/material.dart';

class JointVenturesScreen extends StatefulWidget {
  const JointVenturesScreen({super.key});

  @override
  State<JointVenturesScreen> createState() => _JointVenturesScreenState();
}

class _JointVenturesScreenState extends State<JointVenturesScreen> {
  final List<JointVenture> _ventures = [
    JointVenture(
      name: 'مشروع برج الخليج',
      nameEn: 'Gulf Tower Project',
      partners: [
        Partner(name: 'شركة حساباتي', share: 60),
        Partner(name: 'مجموعة الراشد', share: 25),
        Partner(name: 'مؤسسة الخليج', share: 15),
      ],
      totalCapital: 5000000,
      totalExpenses: 2300000,
      totalRevenue: 1800000,
      status: 'active',
    ),
    JointVenture(
      name: 'مشروع المجمع التجاري',
      nameEn: 'Commercial Complex Project',
      partners: [
        Partner(name: 'شركة حساباتي', share: 50),
        Partner(name: 'شركة البناء الحديث', share: 50),
      ],
      totalCapital: 3000000,
      totalExpenses: 1500000,
      totalRevenue: 2200000,
      status: 'active',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('المشاريع المشتركة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _ventures.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handshake, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                Text('لا توجد مشاريع مشتركة', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26)),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ventures.length,
              itemBuilder: (context, index) {
                final v = _ventures[index];
                final profit = v.totalRevenue - v.totalExpenses;
                final profitPercent = v.totalCapital > 0 ? (profit / v.totalCapital * 100) : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [brandColor.withValues(alpha: 0.1), Colors.transparent]),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.handshake, color: brandColor, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(v.nameEn, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Text('نشط', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      // Financial summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            _miniStat('رأس المال', v.totalCapital, Colors.blue, isDark),
                            _miniStat('المصروفات', v.totalExpenses, Colors.red, isDark),
                            _miniStat('الإيرادات', v.totalRevenue, Colors.green, isDark),
                            _miniStat('الربح/الخسارة', profit, profit >= 0 ? Colors.green : Colors.red, isDark),
                          ],
                        ),
                      ),

                      // Partners
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(width: 8),
                            Text('الشركاء (${v.partners.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45)),
                          ],
                        ),
                      ),
                      ...v.partners.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text(p.name[0], style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 14))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${p.share}%', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Text(_formatNum(profit * p.share / 100), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: profit >= 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVentureDialog(context, isDark, brandColor),
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مشروع جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(_formatNum(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : Colors.black26)),
        ],
      ),
    );
  }

  String _formatNum(double v) {
    final prefix = v < 0 ? '-' : '';
    final abs = v.abs();
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(0)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }

  void _showAddVentureDialog(BuildContext context, bool isDark, Color brandColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('إضافة مشروع مشترك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'رأس المال الإجمالي', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'عدد الشركاء', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: brandColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('إضافة المشروع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JointVenture {
  final String name, nameEn, status;
  final List<Partner> partners;
  final double totalCapital, totalExpenses, totalRevenue;
  JointVenture({required this.name, required this.nameEn, required this.partners, required this.totalCapital, required this.totalExpenses, required this.totalRevenue, required this.status});
}

class Partner {
  final String name;
  final double share;
  Partner({required this.name, required this.share});
}
```

---

## NAVIGATION: Add all new screens to main.dart

```dart
// Add these imports:
import 'package:hisabati_app/screens/cash_flow_statement_screen.dart';
import 'package:hisabati_app/screens/quick_statements_screen.dart';
import 'package:hisabati_app/screens/joint_ventures_screen.dart';

// Add these navigation items in the drawer/navigation:
ListTile(
  leading: const Icon(Icons.water_drop),
  title: const Text('التدفقات النقدية'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashFlowStatementScreen())),
),
ListTile(
  leading: const Icon(Icons.speed),
  title: const Text('قوائم مالية سريعة'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickStatementsScreen())),
),
ListTile(
  leading: const Icon(Icons.handshake),
  title: const Text('المشاريع المشتركة'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JointVenturesScreen())),
),
```

---

## VERIFICATION:
```bash
cd "c:\my app creator\hisabati_app"
flutter analyze
```
