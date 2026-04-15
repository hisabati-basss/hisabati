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

class CEODashboardScreen extends StatefulWidget {
  final bool isMobile;
  const CEODashboardScreen({super.key, this.isMobile = false});
  @override
  State<CEODashboardScreen> createState() => _CEODashboardScreenState();
}

class _CEODashboardScreenState extends State<CEODashboardScreen> with TickerProviderStateMixin {
  final AnalyticsService _analytics = AnalyticsService();
  final AiForecastingService _aiService = AiForecastingService();
  final _fmt = intl.NumberFormat("#,###.##");
  String _currency = 'sar';

  Map<String, double> _livePnl = {'total_revenue': 0, 'total_expense': 0, 'net_profit': 0};
  Map<String, dynamic> _highlights = {};
  Map<String, dynamic> _cashFlowMap = {'projected_net_cash_30d': 0, 'warning_message': ''};
  List<FlSpot> _salesSpots = [];
  List<String> _chartLabels = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  bool _isLoading = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadContext();
    _refreshData();
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
          _isLoading = false;
        });
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
                    Text(tr('ceo.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 12),

                // ═══ 1. QuickBooks-style KPI Cards ═══
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isMobile ? 1.5 : 1.8,
                  children: [
                    _buildKPI(tr('ceo.metrics.revenue'), _livePnl['total_revenue'] ?? 0, Icons.trending_up, Colors.green, tr('dashboard_labels.monthly')),
                    _buildKPI(tr('ceo.metrics.expense'), _livePnl['total_expense'] ?? 0, Icons.trending_down, Colors.red, tr('dashboard_labels.monthly')),
                    _buildKPI(tr('ceo.metrics.profit'), _livePnl['net_profit'] ?? 0, Icons.stacked_line_chart, (_livePnl['net_profit'] ?? 0) >= 0 ? primaryOrange : Colors.red, tr('dashboard_labels.monthly')),
                    _buildKPI(tr('ceo.metrics.liquidity'), (_highlights['total_cash'] as num?)?.toDouble() ?? 0, Icons.account_balance_wallet, Colors.blue, tr('common.details')),
                  ],
                ),
                const SizedBox(height: 8),
                
                // ═══ 2. Secondary KPI Row ═══
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: isMobile ? 2.0 : 2.2,
                  children: [
                    _buildMiniKPI(tr('ceo.metrics.receivables'), (_highlights['total_receivable'] as num?)?.toDouble() ?? 0, Icons.arrow_downward, Colors.orange),
                    _buildMiniKPI(tr('ceo.metrics.payables'), (_highlights['total_payable'] as num?)?.toDouble() ?? 0, Icons.arrow_upward, Colors.purple),
                    _buildMiniKPI(tr('sidebar.hr'), (_highlights['employee_count'] as num?)?.toDouble() ?? 0, Icons.people, Colors.indigo, isCount: true),
                  ],
                ),
                const SizedBox(height: 16),

                // ═══ 3. Sales Chart + AI Prediction ═══
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: GlassContainer(
                    padding: EdgeInsets.all(context.cardPadding), borderRadius: context.cardRadius,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(tr('ceo.charts.sales_trend'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: Colors.white70)),
                         _buildLegendItem(tr('ceo.charts.sales'), Colors.greenAccent),
                      ]),
                      const SizedBox(height: 4),
                      SizedBox(height: 160, child: _buildSalesChart()),
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
                        const SizedBox(height: 12),
                        // Quick stats
                        _buildAIStatRow(tr('ceo.ai.inventory_value'), _fmt.format((_highlights['inventory_value'] as num?)?.toDouble() ?? 0)),
                        _buildAIStatRow(tr('ceo.ai.pending_salaries'), "${(_highlights['pending_salaries_count'] as num?)?.toInt() ?? 0}"),
                        _buildAIStatRow(tr('ceo.ai.open_custodies'), _fmt.format((_highlights['uncleared_custodies_amount'] as num?)?.toDouble() ?? 0)),
                      ]),
                    )),
                  ],
                ]),
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
                const SizedBox(height: 16),

                // ═══ 4. Top Products + Top Customers + Expense Categories ═══
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildListCard(tr('ceo.lists.top_products'), _topProducts, (p) => p['name']?.toString() ?? '', (p) => _fmt.format((p['total_revenue'] as num?)?.toDouble() ?? 0), Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildListCard(tr('ceo.lists.top_customers'), _topCustomers, (c) => c['name']?.toString() ?? tr('pos.partner_walkin'), (c) => _fmt.format((c['total_spent'] as num?)?.toDouble() ?? 0), Colors.blue)),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildListCard(tr('ceo.lists.expense_distribution'), _expenseCategories.take(5).toList(), (e) => e['name']?.toString() ?? '', (e) => _fmt.format((e['total'] as num?)?.toDouble() ?? 0), Colors.red)),
                  ],
                ]),
              ]),
            ),
          ),
    );
  }

  // ═══════════════════════════════════════════════════
  // KPI Cards
  // ═══════════════════════════════════════════════════
  Widget _buildKPI(String title, double value, IconData icon, Color color, String badge) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: context.cardRadius,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: TextStyle(color: context.mutedText, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Spacer(),
        FittedBox(child: Text(_fmt.format(value), style: TextStyle(color: Colors.white, fontSize: context.headerSize, fontWeight: FontWeight.bold))),
        const SizedBox(height: 2),
        Text(CurrencyService.getSymbol(_currency), style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  Widget _buildMiniKPI(String title, double value, IconData icon, Color color, {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: TextStyle(color: context.mutedText, fontSize: 10)),
          Text(isCount ? "${value.toInt()}" : _fmt.format(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ])),
      ]),
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
          getTooltipColor: (_) => Colors.black.withValues(alpha: 0.8),
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem("${_fmt.format(s.y)} ${CurrencyService.getSymbol(_currency)}", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
        ),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500, getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('ceo.ai.projected_liquidity'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text("${_fmt.format(_cashFlowMap['projected_net_cash_30d'] ?? 0)} ${CurrencyService.getSymbol(_currency)}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("${_cashFlowMap['warning_message']}", style: TextStyle(color: isHealthy ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
      ]),
    );
  }

  Widget _buildAIStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  // Lists (Top Products, Customers, Expenses)
  // ═══════════════════════════════════════════════════
  Widget _buildListCard(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) nameGetter, String Function(Map<String, dynamic>) valueGetter, Color color) {
    return GlassContainer(
      padding: EdgeInsets.all(context.cardPadding), borderRadius: context.cardRadius,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: context.subHeaderSize - 1, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 10),
        if (items.isEmpty) Text(tr('ceo.charts.no_data'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ...items.take(5).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 20, height: 20, alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Text("${i + 1}", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(nameGetter(item), style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(valueGetter(item), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          );
        }),
      ]),
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
    if (value == 0) return SideTitleWidget(axisSide: meta.axisSide, child: const Text('0', style: TextStyle(color: Colors.white38, fontSize: 10)));
    String text = value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}K' : value.toInt().toString();
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10)));
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (_chartLabels.isEmpty || value.toInt() >= _chartLabels.length || value.toInt() < 0) return const SizedBox();
    if (value.toInt() % 2 != 0 && _chartLabels.length > 10) return const SizedBox();
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(_chartLabels[value.toInt()], style: const TextStyle(color: Colors.white38, fontSize: 10)));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.white60, fontSize: context.bodySize - 2)),
    ]);
  }
}
