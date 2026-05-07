import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class FeasibilityStudyScreen extends StatefulWidget {
  const FeasibilityStudyScreen({super.key});
  @override
  State<FeasibilityStudyScreen> createState() => _FeasibilityStudyScreenState();
}

class _FeasibilityStudyScreenState extends State<FeasibilityStudyScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = false;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: "السعودية");
  final _capitalCtrl = TextEditingController();
  final _monthlyCostCtrl = TextEditingController();
  final _monthlyRevenueCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: "5");
  final _discountRateCtrl = TextEditingController(text: "10");

  // Results
  Map<String, dynamic>? _results;
  List<Map<String, dynamic>> _savedStudies = [];
  
  // Scenarios
  String _selectedScenario = 'moderate';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedStudies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _sectorCtrl.dispose(); _countryCtrl.dispose();
    _capitalCtrl.dispose(); _monthlyCostCtrl.dispose(); _monthlyRevenueCtrl.dispose();
    _yearsCtrl.dispose(); _discountRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedStudies() async {
    try { _savedStudies = await _db.getFeasibilityStudies(); } catch (e) { debugPrint("Load studies: $e"); }
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════
  // Financial Calculations
  // ═══════════════════════════════════════════════════


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Ultra-Premium Header
          Padding(
            padding: EdgeInsets.fromLTRB(context.sectionPadding, 16, context.sectionPadding, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF9A66FF), Color(0xFFCE9BFF)],
                            ).createShader(bounds),
                            child: const Text(
                              "دراسات الجدوى",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9A66FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF9A66FF).withValues(alpha: 0.2)),
                            ),
                            child: const Text("PRO", style: TextStyle(color: Color(0xFF9A66FF), fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      Text(
                        "نظام التحليل المالي المتكامل للمشاريع الاستثمارية",
                        style: TextStyle(color: context.mutedText, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                if (_results != null)
                  _buildActionButton(
                    label: "حفظ التقرير",
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.green,
                    onTap: _saveStudy,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // High-End Glowing Pill TabBar with Glassmorphism
          Container(
            height: 38,
            margin: EdgeInsets.symmetric(horizontal: context.sectionPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: isDark ? 8 : 4, sigmaY: isDark ? 8 : 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.1 : 0.05)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF9A66FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9A66FF).withValues(alpha: 0.3)),
                    ),
                    labelColor: const Color(0xFF9A66FF),
                    unselectedLabelColor: context.mutedText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5),
                    tabs: const [
                      Tab(text: "معطيات الدراسة"),
                      Tab(text: "النتائج والتحليل"),
                      Tab(text: "السجل التاريخي"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(),
                _buildResultsTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 0: معطيات الدراسة (Form)
  // ═══════════════════════════════════════════════════
  Widget _buildFormTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        children: [
          // Project Details Card
          _buildGlassContainer(
            title: "بيانات المشروع الأساسية",
            icon: Icons.auto_awesome_rounded,
            child: Column(
              children: [
                _buildGlassInput(_nameCtrl, "اسم المشروع أو العلامة التجارية *", Icons.business_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildGlassInput(_sectorCtrl, "القطاع التجاري", Icons.category_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildGlassInput(_countryCtrl, "الموقع الجغرافي", Icons.location_on_rounded)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // Financial Inputs Card
          _buildGlassContainer(
            title: "المؤشرات المالية (المدخلات)",
            icon: Icons.account_balance_wallet_rounded,
            child: Column(
              children: [
                _buildGlassInput(_capitalCtrl, "رأس المال المبدئي (Investment) *", Icons.monetization_on_rounded, isNumber: true),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildGlassInput(_monthlyRevenueCtrl, "الإيرادات الشهرية", Icons.trending_up_rounded, isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildGlassInput(_monthlyCostCtrl, "المصروفات الشهرية", Icons.trending_down_rounded, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildGlassInput(_yearsCtrl, "مدة الدراسة (سنوات)", Icons.timer_rounded, isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildGlassInput(_discountRateCtrl, "معدل الخصم (%)", Icons.percent_rounded, isNumber: true)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Scenario Selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("توقعات سيناريو السوق", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: context.textColor)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildScenarioCard("متفائل", "نمو عالٍ", 'optimistic', Colors.green),
                    const SizedBox(width: 8),
                    _buildScenarioCard("معتدل", "متوقع", 'moderate', Colors.blue),
                    const SizedBox(width: 8),
                    _buildScenarioCard("متشائم", "مخاطر", 'pessimistic', Colors.red),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateStudy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A66FF),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF9A66FF).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_rounded, size: 20),
                      SizedBox(width: 8),
                      Text("بدء التحليل المالي الذكي", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 1: النتائج (Results)
  // ═══════════════════════════════════════════════════
  Widget _buildResultsTab() {
    if (_results == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 80, color: const Color(0xFF9A66FF).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text("بانتظار مدخلاتك للبدء بالتحليل...", style: TextStyle(color: context.mutedText, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final npv = (_results!['npv'] as double);
    final irr = (_results!['irr'] as double);
    final roi = (_results!['roi'] as double);
    final payback = (_results!['payback_months'] as int);
    final successRate = (_results!['success_rate'] as double);
    final isFeasible = npv > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        children: [
          // Main Verdict Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFeasible 
                  ? [const Color(0xFF2E3192), const Color(0xFF1BFFFF)]
                  : [const Color(0xFFED1C24), const Color(0xFFFCEE21)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isFeasible ? Colors.blue : Colors.red).withValues(alpha: 0.2),
                  blurRadius: 12, offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFeasible ? "المشروع مجدٍ اقتصادياً" : "المشروع يحتاج لإعادة تقييم",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        isFeasible 
                          ? "تظهر المؤشرات قدرة المشروع على تحقيق أرباح مستدامة."
                          : "التكاليف الحالية تفوق العوائد المتوقعة في هذا السيناريو.",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(isFeasible ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Success Rate Circle & Primary Metrics
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildGlassContainer(
                  title: "مؤشرات الربحية",
                  icon: Icons.pie_chart_rounded,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCircularIndicator(successRate / 100, "نسبة النجاح"),
                      Column(
                        children: [
                          _buildMiniMetric("ROI", "${roi.toStringAsFixed(1)}%", Colors.blue),
                          const SizedBox(height: 8),
                          _buildMiniMetric("IRR", "${(irr * 100).toStringAsFixed(1)}%", const Color(0xFF9A66FF)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildSquareMetric("NPV", npv.toStringAsFixed(0), "القيمة الحالية", npv > 0 ? Colors.green : Colors.red),
                    const SizedBox(height: 10),
                    _buildSquareMetric("الاسترداد", payback > 0 ? "$payback شهر" : "N/A", "Payback", Colors.orange),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Cash Flow Chart Section
          _buildGlassContainer(
            title: "جدول التدفقات التراكمي",
            icon: Icons.table_chart_rounded,
            child: _buildCashFlowTable(_results!['cash_flows'] as List<Map<String, dynamic>>),
          ),

          const SizedBox(height: 12),

          // Export Actions
          Row(
            children: [
              Expanded(
                child: _buildLargeActionBtn("تصدير PDF", Icons.picture_as_pdf_rounded, Colors.blueGrey, () => _exportFeasibilityPDF(npv, irr, roi, payback, successRate, _results!['cash_flows'])),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLargeActionBtn("حفظ الأرشيف", Icons.archive_rounded, Colors.green, _saveStudy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Tab 2: الدراسات المحفوظة (Saved)
  // ═══════════════════════════════════════════════════
  Widget _buildSavedTab() {
    if (_savedStudies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 60, color: context.mutedText.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text("لا توجد دراسات مؤرشفة حالياً", style: TextStyle(color: context.mutedText, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.sectionPadding),
      itemCount: _savedStudies.length,
      itemBuilder: (_, i) {
        final s = _savedStudies[i];
        final bool isFeasible = ((s['npv'] as num?)?.toDouble() ?? 0) > 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isFeasible ? Colors.green : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(isFeasible ? Icons.check_circle_rounded : Icons.error_rounded, color: isFeasible ? Colors.green : Colors.red, size: 20),
            ),
            title: Text(s['project_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            subtitle: Text("${s['sector'] ?? ''} • ${s['created_at']?.toString().substring(0, 10) ?? ''}", style: TextStyle(fontSize: 11, color: context.mutedText)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${(s['success_rate'] as num?)?.toInt() ?? 0}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF9A66FF))),
                const Text("Success", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            onTap: () {
              // Load this study back into the form?
              setState(() {
                 _nameCtrl.text = s['project_name'] ?? '';
                 _capitalCtrl.text = s['capital']?.toString() ?? '';
                 _monthlyRevenueCtrl.text = s['monthly_revenue']?.toString() ?? '';
                 _monthlyCostCtrl.text = s['monthly_costs']?.toString() ?? '';
                 _tabController.animateTo(0);
              });
            },
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // Professional Components
  // ═══════════════════════════════════════════════════

  Widget _buildGlassContainer({required String title, required IconData icon, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isDark ? 12 : 6, sigmaY: isDark ? 12 : 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.1 : 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: const Color(0xFF9A66FF)),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2, bottom: 2),
          child: Text(label, style: TextStyle(color: context.mutedText, fontSize: 8.5, fontWeight: FontWeight.w800)),
        ),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 14, color: context.mutedText.withValues(alpha: 0.4)),
            isDense: true,
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioCard(String title, String subtitle, String value, Color color) {
    final isSelected = _selectedScenario == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedScenario = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : color, fontSize: 11)),
              Text(subtitle, style: TextStyle(color: isSelected ? Colors.white70 : context.mutedText, fontSize: 7), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(double percent, String label) {
    return Column(
      children: [
        SizedBox(
          width: 56, height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent,
                strokeWidth: 5,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A66FF)),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 8.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSquareMetric(String label, String value, String desc, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: color, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(desc, style: TextStyle(color: context.mutedText, fontSize: 7.5)),
        ],
      ),
    );
  }

  Widget _buildCashFlowTable(List<Map<String, dynamic>> data) {
    return Column(
      children: data.map((cf) {
        final isHeader = cf['year'] == 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.cardBorder.withValues(alpha: 0.05)))),
          child: Row(
            children: [
              Expanded(child: Text(isHeader ? "التأسيس" : "سنة ${cf['year']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(child: Text("${(cf['net'] as double).toStringAsFixed(0)}", style: TextStyle(fontSize: 11, color: cf['net'] >= 0 ? Colors.green : Colors.red))),
              Expanded(
                child: Text(
                  "${(cf['cumulative'] as double).toStringAsFixed(0)}", 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cf['cumulative'] >= 0 ? Colors.green : Colors.red)
                )
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLargeActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Keep original logic methods (_calculate, _calculateIRR, _generateStudy, _saveStudy, _loadSavedStudies, _exportFeasibilityPDF)
  // ═══════════════════════════════════════════════════

  Map<String, dynamic> _calculate(double capital, double monthlyCost, double monthlyRevenue, int years, double discountRate, String scenario) {
    double revenueMultiplier = 1.0;
    double costMultiplier = 1.0;
    switch (scenario) {
      case 'optimistic': revenueMultiplier = 1.2; costMultiplier = 0.9; break;
      case 'pessimistic': revenueMultiplier = 0.75; costMultiplier = 1.15; break;
      default: break;
    }

    final adjRevenue = monthlyRevenue * revenueMultiplier;
    final adjCost = monthlyCost * costMultiplier;
    final monthlyNetCashFlow = adjRevenue - adjCost;
    final annualNetCashFlow = monthlyNetCashFlow * 12;

    double npv = -capital;
    for (int y = 1; y <= years; y++) {
      npv += annualNetCashFlow / pow(1 + discountRate, y);
    }

    double irr = _calculateIRR(capital, annualNetCashFlow, years);
    int paybackMonths = monthlyNetCashFlow > 0 ? (capital / monthlyNetCashFlow).ceil() : (years * 12) + 1;
    if (paybackMonths > (years * 12)) paybackMonths = -1;

    double totalProfit = (annualNetCashFlow * years) - capital;
    double roi = capital > 0 ? (totalProfit / capital) * 100 : 0;

    double successRate = 50;
    if (npv > 0) successRate += 20;
    if (irr > discountRate) successRate += 15;
    if (paybackMonths > 0 && paybackMonths <= 24) successRate += 10;
    if (roi > 30) successRate += 5;
    successRate = successRate.clamp(0, 99);

    List<Map<String, dynamic>> cashFlows = [];
    double cumulative = -capital;
    for (int y = 0; y <= years; y++) {
      if (y == 0) {
        cashFlows.add({'year': 0, 'inflow': 0.0, 'outflow': capital, 'net': -capital, 'cumulative': cumulative});
      } else {
        cumulative += annualNetCashFlow;
        cashFlows.add({'year': y, 'inflow': adjRevenue * 12, 'outflow': adjCost * 12, 'net': annualNetCashFlow, 'cumulative': cumulative});
      }
    }

    return {
      'npv': npv, 'irr': irr, 'roi': roi,
      'payback_months': paybackMonths,
      'monthly_net': monthlyNetCashFlow,
      'annual_net': annualNetCashFlow,
      'total_profit': totalProfit,
      'success_rate': successRate,
      'cash_flows': cashFlows,
      'scenario': scenario,
    };
  }

  double _calculateIRR(double investment, double annualCashFlow, int years) {
    if (annualCashFlow <= 0) return -1;
    double low = -0.5, high = 5.0;
    for (int iter = 0; iter < 100; iter++) {
      double mid = (low + high) / 2;
      double npv = -investment;
      for (int y = 1; y <= years; y++) { npv += annualCashFlow / pow(1 + mid, y); }
      if (npv.abs() < 0.01) return mid;
      if (npv > 0) { low = mid; } else { high = mid; }
    }
    return (low + high) / 2;
  }

  void _generateStudy() {
    final capital = double.tryParse(_capitalCtrl.text) ?? 0;
    final monthlyCost = double.tryParse(_monthlyCostCtrl.text) ?? 0;
    final monthlyRevenue = double.tryParse(_monthlyRevenueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final discountRate = (double.tryParse(_discountRateCtrl.text) ?? 10) / 100;

    if (capital <= 0 || _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال اسم المشروع ورأس المال")));
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      final results = _calculate(capital, monthlyCost, monthlyRevenue, years, discountRate, _selectedScenario);
      if (mounted) setState(() { _results = results; _isLoading = false; _tabController.animateTo(1); });
    });
  }

  Future<void> _saveStudy() async {
    if (_results == null) return;
    final capital = double.tryParse(_capitalCtrl.text) ?? 0;
    final monthlyCost = double.tryParse(_monthlyCostCtrl.text) ?? 0;
    final monthlyRevenue = double.tryParse(_monthlyRevenueCtrl.text) ?? 0;
    final years = int.tryParse(_yearsCtrl.text) ?? 5;
    final discountRate = (double.tryParse(_discountRateCtrl.text) ?? 10) / 100;

    await _db.saveFeasibilityStudy({
      'id': const Uuid().v4(),
      'project_name': _nameCtrl.text,
      'sector': _sectorCtrl.text,
      'country': _countryCtrl.text,
      'capital': capital,
      'monthly_costs': monthlyCost,
      'monthly_revenue': monthlyRevenue,
      'study_years': years,
      'discount_rate': discountRate,
      'npv': _results!['npv'],
      'irr': _results!['irr'],
      'payback_months': _results!['payback_months'],
      'success_rate': _results!['success_rate'],
      'scenario': _selectedScenario,
    });
    
    await _loadSavedStudies();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حفظ الدراسة بنجاح")));
  }

  Future<void> _exportFeasibilityPDF(double npv, double irr, double roi, int payback, double success, List<Map<String, dynamic>> cashFlows) async {
    try {
      final pdf = pw.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4, textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Center(child: pw.Text('تقرير دراسة الجدوى الاقتصادية', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple))),
          pw.SizedBox(height: 20),
          pw.Text('المشروع: ${_nameCtrl.text}', style: pw.TextStyle(fontSize: 16)),
          pw.Divider(),
          pw.Text('النتائج الأساسية:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('NPV: ${npv.toStringAsFixed(0)}'),
          pw.Text('ROI: ${roi.toStringAsFixed(1)}%'),
          pw.Text('IRR: ${(irr * 100).toStringAsFixed(1)}%'),
          pw.Text('فترة الاسترداد: $payback شهر'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['السنة', 'التدفق', 'التراكمي'],
            data: cashFlows.map((cf) => [cf['year'].toString(), cf['net'].toStringAsFixed(0), cf['cumulative'].toStringAsFixed(0)]).toList(),
          ),
        ]),
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }
}
