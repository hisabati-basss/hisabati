import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme_extension.dart';
import '../services/reporting_service.dart';
import '../services/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportingService _reportingService = ReportingService();
  final DatabaseHelper _db = DatabaseHelper();
  
  Map<String, double> _pnl = {'revenue': 0, 'expenses': 0, 'net_profit': 0};
  List<Map<String, dynamic>> _ccPerformance = [];
  bool _isLoading = true;
  String _selectedPeriod = "آخر ٣٠ يوم";
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _reportingService.getPNLReport(
      _startDate.toIso8601String().split('T')[0],
      _endDate.toIso8601String().split('T')[0],
    );
    final performance = await _reportingService.getCostCenterPerformance(
      _startDate.toIso8601String().split('T')[0],
      _endDate.toIso8601String().split('T')[0],
    );

    if (mounted) {
      setState(() {
        _pnl = stats;
        _ccPerformance = performance;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePdfExport() async {
    final List<Map<String, dynamic>> records = [
      {'label': 'إجمالي الإيرادات', 'value': _pnl['revenue']},
      {'label': 'إجمالي المصروفات', 'value': _pnl['expenses']},
      {'label': 'صافي الربح', 'value': _pnl['net_profit']},
    ];
    
    // Add cost center breakdown to PDF
    for (var cc in _ccPerformance) {
      records.add({'label': "م.ت: ${cc['name']} (صافي)", 'value': cc['profit']});
    }

    try {
      await _reportingService.generateFinancialPDF(
        title: "تقرير الأداء المالي والربحية",
        period: "${_startDate.toIso8601String().split('T')[0]} إلى ${_endDate.toIso8601String().split('T')[0]}",
        records: records,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل التصدير: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        
        if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 20/24
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16), // 📉 Reduced from 32
              
              _buildModernStatsGrid(isMobile),
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: primaryOrange, size: context.iconSize), // 📉 Added size
                  const SizedBox(width: 8), // 📉 Reduced from 12
                  Text("توزيع التكاليف", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Shortened + Reduced
                ],
              ),
              const SizedBox(height: 12), // 📉 Reduced from 24
              
              _buildChartSection(isMobile),
              const SizedBox(height: 16), // 📉 Reduced from 40
              _buildCostCenterTable(),
              const SizedBox(height: 16), // 📉 Reduced from 60
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("التحليلات المالية", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2, letterSpacing: 1.0)), // 📉 Reduced from 13
            const SizedBox(height: 2), // 📉 Reduced from 4
            Text("التقارير", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Shortened + Reduced 
          ],
        ),
        ElevatedButton.icon(
          onPressed: _handlePdfExport,
          icon: Icon(Icons.picture_as_pdf_outlined, size: context.iconSize - 2), // 📉 Reduced from 20
          label: Text("PDF", style: TextStyle(fontSize: context.bodySize)), // 📉 Shortened
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 📉 Reduced from 20/14
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 12
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatsGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 3,
      crossAxisSpacing: 8, // 📉 Reduced from 16
      mainAxisSpacing: 8, // 📉 Reduced from 16
      childAspectRatio: isMobile ? 2.8 : 2.2, // 📉 Adjusted for compacting
      children: [
        _buildGlassStatCard("الإيرادات", _pnl['revenue']!, Colors.green, Icons.trending_up),
        _buildGlassStatCard("المصروفات", _pnl['expenses']!, Colors.redAccent, Icons.trending_down),
        _buildGlassStatCard("صافي الربح", _pnl['net_profit']!, primaryOrange, Icons.account_balance_wallet_outlined),
      ],
    );
  }

  Widget _buildChartSection(bool isMobile) {
    return Container(
      height: 200, // 📉 Reduced from 300
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: _ccPerformance.map((cc) {
                  final double expense = (cc['expenses'] ?? 0.0);
                  final double totalExpense = _pnl['expenses']! > 0 ? _pnl['expenses']! : 1.0;
                  final double percentage = (expense / totalExpense) * 100;
                  
                  return PieChartSectionData(
                    color: _getColorForIndex(_ccPerformance.indexOf(cc)),
                    value: expense,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          if (!isMobile)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _ccPerformance.map((cc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2), // 📉 Reduced from 4
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _getColorForIndex(_ccPerformance.indexOf(cc)), shape: BoxShape.circle)), // 📉 Reduced from 12
                      const SizedBox(width: 6), // 📉 Reduced from 8
                      Text(cc['name'], style: TextStyle(color: context.textColor, fontSize: context.bodySize - 1)), // 📉 Reduced from 13
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCostCenterTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
            child: Text("أداء مراكز التكلفة", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Reduced from 18
          ),
          DataTable(
            columnSpacing: 12, // 📉 Reduced from 20
            dataRowMaxHeight: 32, // 📉 Added compact heights
            dataRowMinHeight: 24,
            headingRowHeight: 36,
            columns: [
              DataColumn(label: Text("مركز التكلفة", style: TextStyle(fontSize: context.bodySize))),
              DataColumn(label: Text("إيرادات", style: TextStyle(fontSize: context.bodySize))),
              DataColumn(label: Text("مصاريف", style: TextStyle(fontSize: context.bodySize))),
              DataColumn(label: Text("صافي", style: TextStyle(fontSize: context.bodySize))), // 📉 Shortened
            ],
            rows: _ccPerformance.map((cc) => DataRow(
              cells: [
                DataCell(Text(cc['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
                DataCell(Text("${cc['revenue']?.toStringAsFixed(0)}", style: TextStyle(fontSize: context.bodySize - 1))),
                DataCell(Text("${cc['expenses']?.toStringAsFixed(0)}", style: TextStyle(fontSize: context.bodySize - 1))),
                DataCell(Text("${cc['profit']?.toStringAsFixed(0)}", style: TextStyle(color: (cc['profit'] ?? 0) >= 0 ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              ],
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard(String label, double value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 📉 Reduced blur
          child: Padding(
            padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 20
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)), // 📉 Reduced from 14
                    Icon(icon, color: color.withValues(alpha: 0.8), size: context.iconSize - 2), // 📉 Reduced from 20
                  ],
                ),
                const Spacer(),
                Text(
                  "${value.toStringAsFixed(0)} ر.س",
                  style: TextStyle(fontSize: context.headerSize + 2, fontWeight: FontWeight.bold, color: context.textColor, letterSpacing: -1), // 📉 Reduced from 28
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    List<Color> colors = [primaryOrange, Colors.blue, Colors.purple, Colors.teal, Colors.amber];
    return colors[index % colors.length];
  }
}
