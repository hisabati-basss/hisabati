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
                        Text(stmt.descAr, style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38, height: 1.3)),
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
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('جاري تصدير ${stmt.nameAr} إلى PDF...'),
                                      backgroundColor: stmt.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                tooltip: 'PDF',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              ),
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('جاري تصدير ${stmt.nameAr} إلى Excel...'),
                                      backgroundColor: stmt.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
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
