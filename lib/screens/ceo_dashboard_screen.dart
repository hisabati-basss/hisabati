import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme_extension.dart';
import '../services/analytics_service.dart';
import '../services/ai_forecasting_service.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../widgets/glass_container.dart';
import 'package:intl/intl.dart' as intl;
import 'package:easy_localization/easy_localization.dart';
import '../services/reporting_service.dart';

class CEODashboardScreen extends StatefulWidget {
  final bool isMobile;
  const CEODashboardScreen({super.key, this.isMobile = false});
  @override
  State<CEODashboardScreen> createState() => _CEODashboardScreenState();
}

class _CEODashboardScreenState extends State<CEODashboardScreen> with TickerProviderStateMixin {
  final AnalyticsService _analytics = AnalyticsService();
  final AiForecastingService _aiService = AiForecastingService();
  final ReportingService _reportingService = ReportingService();
  String _currency = 'sar';
  Map<String, double> _livePnl = {'total_revenue': 0, 'total_expense': 0, 'net_profit': 0};
  Map<String, dynamic> _highlights = {};
  Map<String, dynamic> _cashFlowMap = {'projected_net_cash_30d': 0, 'warning_message': '', 'is_healthy': true};
  
  late intl.NumberFormat _fmt;

  String _formatCurrency(double value) {
    final sign = value < 0 ? '-' : '';
    return "$sign${_fmt.format(value.abs())}";
  }
  List<FlSpot> _salesSpots = [];
  List<String> _chartLabels = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  Map<String, dynamic> _agentPerformance = {};
  Map<String, dynamic> _supplierPerformance = {};
  bool _isLoading = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadContext();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fmt = intl.NumberFormat("#,###.##", context.locale.toString());
  }

  Future<void> _loadContext() async {
    final ctx = await DatabaseHelper().getCurrentCompanyContext();
    if (mounted) setState(() => _currency = ctx['currency'] ?? 'sar');
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _fadeController.reset();

    try {
      final pnl = await _analytics.getLivePNL();
      final highlights = await _analytics.getExecutiveHighlights();
      final trend = await _analytics.getSalesTrendLast7Days();
      final cashFlowMap = await _aiService.predictCashFlow30Days();
      final topProducts = await _analytics.getTopSellingProducts();
      final topCustomers = await _analytics.getTopCustomers();
      final expenseCats = await _analytics.getExpenseByCategory();

      List<FlSpot> sales = [];
      List<String> labels = [];
      for (int i = 0; i < trend.length; i++) {
        labels.add(trend[i]['day_name'].toString().substring(0, 3));
        sales.add(FlSpot(i.toDouble(), (trend[i]['amount'] as num).toDouble()));
      }

      if (mounted) {
        setState(() {
          _livePnl = pnl;
          _highlights = highlights;
          _salesSpots = sales;
          _chartLabels = labels;
          _cashFlowMap = cashFlowMap;
          _topProducts = topProducts;
          _topCustomers = topCustomers;
          _expenseCategories = expenseCats;
        });
        
        final agentData = await _reportingService.getAgentPerformanceReport();
        final supplierData = await _reportingService.getSupplierPerformanceReport();

        if (mounted) {
          setState(() {
            _agentPerformance = agentData.isNotEmpty ? agentData.first : {};
            _supplierPerformance = supplierData.isNotEmpty ? supplierData.first : {};
            _isLoading = false;
          });
        }
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint("CEO Dashboard Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.sectionPadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('ceo.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                    Text(_getGreeting(), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                  ])),
                  GestureDetector(
                    onTap: _refreshData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryOrange.withValues(alpha: 0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.refresh, size: 14, color: primaryOrange),
                        const SizedBox(width: 4),
                        Text(tr('common.refresh'), style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),

                // ═══ 1. QuickBooks-style KPI Cards ═══
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isMobile ? 1.5 : 2.05,
                  children: [
                    _buildKPI(tr('ceo.metrics.revenue'), _livePnl['total_revenue'] ?? 0, Icons.trending_up, Colors.green, tr('dashboard_labels.yearly')),
                    _buildKPI(tr('ceo.metrics.expense'), _livePnl['total_expense'] ?? 0, Icons.trending_down, Colors.red, tr('dashboard_labels.yearly')),
                    _buildKPI(tr('ceo.metrics.profit'), _livePnl['net_profit'] ?? 0, Icons.stacked_line_chart, (_livePnl['net_profit'] ?? 0) >= 0 ? primaryOrange : Colors.red, tr('dashboard_labels.yearly')),
                    _buildKPI(tr('ceo.metrics.liquidity'), (_highlights['total_cash'] as num?)?.toDouble() ?? 0, Icons.account_balance_wallet, Colors.blue, tr('common.details')),
                  ],
                ),
                const SizedBox(height: 4),
                
                // ═══ 2. Secondary KPI Row ═══
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isMobile ? 2.5 : 4.0,
                  children: [
                    _buildMiniKPI(tr('ceo.metrics.receivables'), (_highlights['total_receivable'] as num?)?.toDouble() ?? 0, Icons.arrow_downward, Colors.orange),
                    _buildMiniKPI(tr('ceo.metrics.payables'), (_highlights['total_payable'] as num?)?.toDouble() ?? 0, Icons.arrow_upward, Colors.purple),
                    _buildMiniKPI(tr('sidebar.hr'), (_highlights['employee_count'] as num?)?.toDouble() ?? 0, Icons.people, Colors.indigo, isCount: true),
                  ],
                ),
                const SizedBox(height: 12),

                // ═══ 3. Sales Chart + AI Prediction ═══
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: 3, child: GlassContainer(
                      padding: EdgeInsets.all(context.cardPadding), borderRadius: context.cardRadius,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(tr('ceo.charts.sales_trend'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor.withValues(alpha: 0.7))),
                           _buildLegendItem(tr('ceo.charts.sales'), Colors.greenAccent),
                        ]),
                        const SizedBox(height: 4),
                        Expanded(child: SizedBox(height: 130, child: _buildSalesChart())),
                      ]),
                    )),
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: GlassContainer(
                        padding: EdgeInsets.all(context.cardPadding), borderRadius: context.cardRadius,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Text("🤖", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(tr('ceo.ai.financial_forecast'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ]),
                          const SizedBox(height: 12),
                          _buildAIPrediction(),
                          const Spacer(),
                          const SizedBox(height: 12),
                          // Quick stats
                          _buildAIStatRow(tr('ceo.ai.inventory_value'), _formatCurrency((_highlights['inventory_value'] as num?)?.toDouble() ?? 0)),
                          _buildAIStatRow(tr('ceo.ai.pending_salaries'), "${(_highlights['pending_salaries_count'] as num?)?.toInt() ?? 0}"),
                          _buildAIStatRow(tr('ceo.ai.open_custodies'), _formatCurrency((_highlights['uncleared_custodies_amount'] as num?)?.toDouble() ?? 0)),
                        ]),
                      )),
                    ],
                  ]),
                ),
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: EdgeInsets.all(context.cardPadding), borderRadius: context.cardRadius,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("🤖 ${tr('ceo.ai.financial_forecast')}", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: Colors.amber)),
                      const SizedBox(height: 8),
                      _buildAIPrediction(),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),

                // ═══ 4. Top Products + Top Customers + Expense Categories ═══
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildListCard(tr('ceo.lists.top_products'), _topProducts, (p) => p['name']?.toString() ?? '', (p) => _formatCurrency((p['total_revenue'] as num?)?.toDouble() ?? 0), Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildListCard(tr('ceo.lists.top_customers'), _topCustomers, (c) => c['name']?.toString() ?? tr('pos.partner_walkin'), (c) => _formatCurrency((c['total_spent'] as num?)?.toDouble() ?? 0), Colors.blue)),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildListCard(tr('ceo.lists.expense_distribution'), _expenseCategories.take(5).toList(), (e) => e['name']?.toString() ?? '', (e) => _formatCurrency((e['total'] as num?)?.toDouble() ?? 0), Colors.red)),
                  ],
                ]),
                const SizedBox(height: 24),
                
                // ═══ 5. BI Insights Row ═══
                Text(tr('ceo.bi_insights'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBIInsightCard(tr('ceo.top_agent'), _agentPerformance['agent_name'] ?? tr('ceo.charts.no_data'), "تحقيق الهدف: ${_agentPerformance['target_achievement']?.toStringAsFixed(1) ?? 0}%", Icons.stars, Colors.amber)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBIInsightCard(tr('ceo.top_supplier'), _supplierPerformance['supplier_name'] ?? tr('ceo.charts.no_data'), "التقييم العام: ${_supplierPerformance['overall_rating']?.toStringAsFixed(1) ?? 0}/5", Icons.verified_user, Colors.teal)),
                  ],
                ),
                const SizedBox(height: 20),

                // ═══ 6. Diverse Industry KPIs ═══
                Text(tr('ceo.cross_industry'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>>(
                  future: _analytics.getIndustryDiverseKPIs(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final kpis = snapshot.data!;
                    return GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isMobile ? 2.5 : 3.5,
                      children: [
                        _buildIndustryCard(tr('ceo.medical'), "مرضى: ${kpis['medical']?['total_patients'] ?? 0}", "مواعيد: ${kpis['medical']?['pending_appointments'] ?? 0}", Icons.medical_services, Colors.redAccent),
                        _buildIndustryCard(tr('ceo.hospitality'), "الإشغال: ${kpis['hospitality']?['occupancy_rate']?.toStringAsFixed(1) ?? 0}%", "غرف: ${kpis['hospitality']?['total_rooms'] ?? 0}", Icons.hotel, Colors.orangeAccent),
                        _buildIndustryCard(tr('ceo.manufacturing'), "أوامر نشطة: ${kpis['manufacturing']?['active_orders'] ?? 0}", "كفاءة: 94%", Icons.factory, Colors.blueAccent),
                        _buildIndustryCard(tr('ceo.real_estate'), "إشغال العقارات: ${kpis['real_estate']?['occupancy_rate']?.toStringAsFixed(1) ?? 0}%", "وحدات: ${kpis['real_estate']?['total_units'] ?? 0}", Icons.business, Colors.purpleAccent),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
    );
  }

  Widget _buildIndustryCard(String title, String mainVal, String subVal, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 12.0,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: context.textColor.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(mainVal, style: TextStyle(color: context.textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(subVal, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // KPI Cards
  // ═══════════════════════════════════════════════════
  Widget _buildKPI(String title, double value, IconData icon, Color color, String badge) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.cardRadius),
        boxShadow: [
          if (perfShowShadows.value) BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -10,
          )
        ],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: context.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: context.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [context.textColor, context.textColor.withValues(alpha: 0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCurrency(value),
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    shadows: [
                      if (perfShowShadows.value) Shadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  CurrencyService.getSymbol(_currency),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKPI(String title, double value, IconData icon, Color color, {bool isCount = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.cardRadius),
        boxShadow: [
          if (perfShowShadows.value) BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: context.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: context.mutedText, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isCount ? "${value.toInt()}" : _formatCurrency(value),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: context.textColor,
                      shadows: [
                        if (perfShowShadows.value) Shadow(color: color.withValues(alpha: 0.3), blurRadius: 5)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Charts
  // ═══════════════════════════════════════════════════
  Widget _buildSalesChart() {
    return LineChart(LineChartData(
      minY: 0,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => context.isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem("${_formatCurrency(s.y)} ${CurrencyService.getSymbol(_currency)}", TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
        ),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500, getDrawingHorizontalLine: (_) => FlLine(color: context.textColor.withValues(alpha: 0.1), strokeWidth: 1)),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: _leftTitleWidgets)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: _bottomTitleWidgets)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _salesSpots.isEmpty ? [const FlSpot(0, 0)] : _salesSpots,
          isCurved: true, color: Colors.greenAccent, barWidth: 3, isStrokeCapRound: true,
          dotData: FlDotData(show: _salesSpots.length < 10),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.greenAccent.withValues(alpha: 0.2), Colors.greenAccent.withValues(alpha: 0)])),
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════
  // AI Prediction
  // ═══════════════════════════════════════════════════
  Widget _buildAIPrediction() {
    final isHealthy = _cashFlowMap['is_healthy'] == true;
    final color = isHealthy ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          if (perfShowShadows.value) BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isHealthy ? Icons.auto_graph : Icons.warning_rounded, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                tr('ceo.ai.projected_liquidity'),
                style: TextStyle(color: context.textColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [context.textColor, color],
            ).createShader(bounds),
            child: Text(
              "${_formatCurrency((_cashFlowMap['projected_net_cash_30d'] as num?)?.toDouble() ?? 0)} ${CurrencyService.getSymbol(_currency)}",
              style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${_cashFlowMap['warning_message']}",
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: context.textColor.withValues(alpha: 0.5), fontSize: 12)),
        Text(value, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Lists (Top Products, Customers, Expenses)
  // ═══════════════════════════════════════════════════
  Widget _buildListCard(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) nameGetter, String Function(Map<String, dynamic>) valueGetter, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: context.cardRadius,
      border: Border.all(color: context.textColor.withValues(alpha: 0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: context.textColor.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text(tr('ceo.charts.no_data'), style: TextStyle(color: context.textColor.withValues(alpha: 0.2), fontSize: 11))),
            ),
          ...items.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.textColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text("${i + 1}", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nameGetter(item),
                      style: TextStyle(color: context.textColor.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    valueGetter(item),
                    style: TextStyle(color: context.textColor, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return tr('ceo.greeting_morning');
    if (h < 17) return tr('ceo.greeting_afternoon');
    return tr('ceo.greeting_evening');
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0) return SideTitleWidget(axisSide: meta.axisSide, child: Text('0', style: TextStyle(color: context.textColor.withValues(alpha: 0.4), fontSize: 10)));
    String text = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}K' : value.toInt().toString();
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: TextStyle(color: context.textColor.withValues(alpha: 0.4), fontSize: 10)));
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (_chartLabels.isEmpty || value.toInt() >= _chartLabels.length || value.toInt() < 0) return const SizedBox();
    if (value.toInt() % 2 != 0 && _chartLabels.length > 10) return const SizedBox();
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(_chartLabels[value.toInt()], style: TextStyle(color: context.textColor.withValues(alpha: 0.4), fontSize: 10)));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: context.textColor.withValues(alpha: 0.6), fontSize: context.bodySize - 2)),
    ]);
  }

  Widget _buildBIInsightCard(String title, String mainValue, String subValue, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: context.cardRadius,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.mutedText, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(mainValue, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subValue, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
