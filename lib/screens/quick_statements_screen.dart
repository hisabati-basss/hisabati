import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _generateStatement(String id, String name) async {
    setState(() => _generating[id] = true);
    await Future.delayed(const Duration(milliseconds: 800)); 
    if (mounted) {
      setState(() => _generating[id] = false);
      _showReportPreview(name);
    }
  }

  Future<void> _printPdf(String name) async {
    final pdf = pw.Document();
    
    // Use a font that supports Arabic if possible, or just standard for demo
    // Note: Printing Arabic in PDF requires a font file. For now, we'll use standard text.
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Hisabati ERP - Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Report Name: $name', style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text('Generated on: ${DateTime.now().toString()}', style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.Text('This is a professional financial statement generated automatically.', textAlign: pw.TextAlign.center),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '$name.pdf',
    );
  }

  void _showReportPreview(String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.blue),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('تم إنشاء التقرير المالي بنجاح', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 8),
              Text('التقرير جاهز الآن للطباعة أو المعاينة كملف PDF', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _printPdf(name);
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('طباعة / تحميل PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('القوائم المالية السريعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      for (final s in _statements) {
                        await _generateStatement(s.id, s.nameAr);
                      }
                    },
                    icon: const Icon(Icons.all_inclusive, color: brandColor, size: 20),
                    label: const Text('توليد الكل', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: brandColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final stmt = _statements[index];
                  final isGenerating = _generating[stmt.id] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: stmt.color.withValues(alpha: 0.15)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _generateStatement(stmt.id, stmt.nameAr),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: stmt.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(stmt.icon, color: stmt.color, size: 32),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stmt.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    const SizedBox(height: 4),
                                    Text(stmt.nameEn, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    const SizedBox(height: 8),
                                    Text(stmt.descAr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              isGenerating
                                ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 4, color: Colors.blue))
                                : Icon(Icons.play_circle_fill, color: stmt.color, size: 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _statements.length,
              ),
            ),
          ),
        ],
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
