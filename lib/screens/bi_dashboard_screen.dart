import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme_extension.dart';
import '../services/cash_flow_service.dart';
import '../services/tax_service.dart';
import '../services/reporting_service.dart';

class BIDashboardScreen extends StatefulWidget {
  const BIDashboardScreen({super.key});

  @override
  State<BIDashboardScreen> createState() => _BIDashboardScreenState();
}

class _BIDashboardScreenState extends State<BIDashboardScreen> {
  final CashFlowService _cashFlow = CashFlowService();
  final TaxService _taxService = TaxService();
  final ReportingService _reporting = ReportingService();

  bool _isLoading = true;
  
  Map<String, dynamic> _cashForecast = {};
  Map<String, dynamic> _vatReturn = {};
  List<Map<String, dynamic>> _ccPerformance = [];
  Map<String, double> _pnl = {};

  @override
  void initState() {
    super.initState();
    _loadAllDashboards();
  }

  Future<void> _loadAllDashboards() async {
    setState(() => _isLoading = true);
    
    // Aggregating queries concurrently for speed (v27 optimization logic)
    final String startDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    final String endDate = DateTime.now().toIso8601String().split('T')[0];

    try {
      final results = await Future.wait<dynamic>([
        _cashFlow.forecastLiquidity(30), // Next 30 days
        _taxService.generateVatReturn(startDate, endDate), // VAT for last 30 days
        _reporting.getCostCenterPerformance(startDate, endDate),
        _reporting.getPNLReport(startDate, endDate)
      ]);

      if (mounted) {
        setState(() {
          _cashForecast = results[0] as Map<String, dynamic>;
          _vatReturn = results[1] as Map<String, dynamic>;
          _ccPerformance = results[2] as List<Map<String, dynamic>>;
          _pnl = results[3] as Map<String, double>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Dashboard Load Error: $e');
        setState(() => _isLoading = false); // Hide spinner even on error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
        backgroundColor: Colors.transparent, // Background handled by main shell
        body: SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24/32
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12), // 📉 Reduced from 32
                
                // Top KPIs
                _buildGlobalKPIs(),
                const SizedBox(height: 12), // 📉 Reduced from 32

                // Main Content (Graphs and Analysis)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildCashFlowChart(),
                          const SizedBox(height: 12), // 📉 Reduced from 24
                          _buildTaxDashboard(),
                          const SizedBox(height: 12), // 📉 Reduced from 24
                          _buildCostCenterPreview(),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildCashFlowChart(),
                                const SizedBox(height: 12), // 📉 Reduced from 24
                                _buildTaxDashboard(),
                              ],
                            )
                          ),
                          const SizedBox(width: 12), // 📉 Reduced from 24
                          Expanded(
                            flex: 3,
                            child: _buildCostCenterPreview(),
                          ),
                        ],
                      );
                    }
                  }
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الذكاء الاصطناعي السيادي (v27)", style: TextStyle(color: primaryOrange, fontSize: context.bodySize - 1, letterSpacing: 1.2, fontWeight: FontWeight.bold)), // 📉 Reduced from 13
            const SizedBox(height: 2), // 📉 Reduced from 4
            Text("لوحة القيادة التنفيذية", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Reduced from 32
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 📉 Reduced from 16/8
          decoration: BoxDecoration(
            color: _cashForecast['risk_level'] == 'Low' ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
            border: Border.all(color: _cashForecast['risk_level'] == 'Low' ? Colors.green : Colors.redAccent),
          ),
          child: Row(
            children: [
              Icon((_cashForecast['risk_level'] ?? 'Low') == 'Low' ? Icons.check_circle : Icons.warning_amber, size: context.iconSize - 2, color: (_cashForecast['risk_level'] ?? 'Low') == 'Low' ? Colors.green : Colors.redAccent), // 📉 Reduced
              const SizedBox(width: 6), // 📉 Reduced from 8
              Text("السيولة: ${_cashForecast['risk_level'] ?? 'تحت المراجعة'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize, color: context.textColor)), // 📉 Reduced/Shortened
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGlobalKPIs() {
    return Row(
      children: [
        Expanded(child: _buildGlassKpiCard("صافي الربح", _pnl['net_profit'] ?? 0, Icons.trending_up, Colors.green)),
        const SizedBox(width: 8), // 📉 Reduced from 16
        Expanded(child: _buildGlassKpiCard("السيولة (٣٠ ي)", _cashForecast['projected_cash'] ?? 0, Icons.account_balance_wallet, primaryOrange)), // 📉 Shortened
        const SizedBox(width: 8), // 📉 Reduced from 16
        Expanded(child: _buildGlassKpiCard("الضريبة", _vatReturn['tax_due'] ?? 0, Icons.gavel, Colors.purpleAccent)), // 📉 Shortened
      ],
    );
  }

  Widget _buildGlassKpiCard(String label, double value, IconData icon, Color highlightColor) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
        border: Border.all(color: highlightColor.withValues(alpha: 0.3), width: 1.0), // 📉 Reduced from 1.5
        boxShadow: [BoxShadow(color: highlightColor.withValues(alpha: 0.05), blurRadius: 10)], // 📉 Reduced from 20
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.iconSize - 4, color: highlightColor), // 📉 Reduced from 20
              const SizedBox(width: 6), // 📉 Reduced from 8
              Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)), // 📉 Reduced from 13
            ],
          ),
          const SizedBox(height: 8), // 📉 Reduced from 16
          Text("${value.toStringAsFixed(0)} ر.س", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, letterSpacing: -0.5)), // 📉 Reduced from 24
        ],
      ),
    );
  }

  Widget _buildCashFlowChart() {
    double current = (_cashForecast['current_cash'] as num?)?.toDouble() ?? 0.0;
    double projected = (_cashForecast['projected_cash'] as num?)?.toDouble() ?? 0.0;
    double expectedInflow = (_cashForecast['expected_inflow'] as num?)?.toDouble() ?? 0.0;
    double expectedOutflow = (_cashForecast['expected_outflow'] as num?)?.toDouble() ?? 0.0;
    
    List<FlSpot> spots = [
      FlSpot(0, current),
      FlSpot(1, current + (expectedInflow * 0.1)),
      FlSpot(2, current + (expectedInflow * 0.4) - (expectedOutflow * 0.2)),
      FlSpot(3, current + (expectedInflow * 0.8) - (expectedOutflow * 0.5)),
      FlSpot(4, projected),
    ];

    return Container(
      height: 220, // 📉 Reduced from 350
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.cardSurface.withValues(alpha: 0.8), context.cardSurface.withValues(alpha: 0.4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 32
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)), // 📉 Reduced opacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("تنبؤ النقد (30 ي) - AI Flow", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced/Shortened
          const SizedBox(height: 4), // 📉 Reduced from 8
          Text("توقعات قائمة على المبيعات، الشراء والرواتب", style: TextStyle(fontSize: context.bodySize - 2, color: context.mutedText)), // 📉 Reduced/Shortened
          const SizedBox(height: 12), // 📉 Reduced from 24
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: context.cardBorder, strokeWidth: 1)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryOrange,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 6, color: primaryOrange, strokeWidth: 2, strokeColor: Colors.white)),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [primaryOrange.withValues(alpha: 0.3), primaryOrange.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter
                      ),
                    ),
                  )
                ]
              )
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTaxDashboard() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 32
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الإقرار الضريبي (ZATCA)", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 18/Shortened
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text("تلقائي", style: TextStyle(color: Colors.purple, fontSize: context.bodySize - 3, fontWeight: FontWeight.bold))), // 📉 Reduced/Shortened
            ],
          ),
          const SizedBox(height: 12), // 📉 Reduced from 24
          _buildTaxRow("ضريبة المخرجات (المبيعات)", _vatReturn['output_vat'] ?? 0, isSub: false),
          const Divider(),
          _buildTaxRow("خصم المرتجعات (Credit Notes)", _vatReturn['credit_notes_vat'] ?? 0, isSub: true),
          const Divider(),
          _buildTaxRow("صافي ضريبة المخرجات", _vatReturn['net_output_vat'] ?? 0, isSub: false, isBold: true),
          const SizedBox(height: 16),
          _buildTaxRow("ضريبة المدخلات (المشتريات المعتمدة)", _vatReturn['net_input_vat'] ?? 0, isSub: true),
          const Divider(thickness: 2),
          _buildTaxRow("الضريبة المستحقة (ZATCA)", _vatReturn['tax_due'] ?? 0, isSub: false, isBold: true, color: primaryOrange),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double value, {bool isSub = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 📉 Reduced from 8
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? context.textColor : context.mutedText, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? context.bodySize : context.bodySize - 1)), // 📉 Reduced from 16/14
          Text("${isSub ? '- ' : ''}${value.toStringAsFixed(0)} ر.س", style: TextStyle(color: color ?? context.textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? context.bodySize : context.bodySize - 1)), // 📉 Reduced/Rounded
        ],
      ),
    );
  }

  Widget _buildCostCenterPreview() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 32
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ربحية مراكز التكلفة", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 18/Shortened
          const SizedBox(height: 12), // 📉 Reduced from 24
          ..._ccPerformance.map((cc) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // 📉 Reduced from 16
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cc['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)), // 📉 Added size
                    Text("${(cc['profit'] ?? 0).toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize, color: (cc['profit'] ?? 0) >= 0 ? Colors.green : Colors.redAccent)), // 📉 Shortened
                  ],
                ),
                const SizedBox(height: 4), // 📉 Reduced from 8
                Row(
                  children: [
                    Expanded(child: Text("إ: ${(cc['revenue'] ?? 0).toStringAsFixed(0)}", style: TextStyle(fontSize: 8, color: Colors.green))), // 📉 Reduced from 10
                    Expanded(child: Text("م: ${(cc['expenses'] ?? 0).toStringAsFixed(0)}", style: TextStyle(fontSize: 8, color: Colors.redAccent))), // 📉 Reduced from 10
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (cc['revenue'] ?? 0) > 0 ? (cc['profit'] ?? 0) / (cc['revenue'] ?? 1) : 0,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>((cc['profit'] ?? 0) >= 0 ? Colors.green : Colors.redAccent),
                )
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
