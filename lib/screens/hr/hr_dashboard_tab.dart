import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/currency_service.dart';
import '../../theme/app_theme_extension.dart';

class HRDashboardTab extends StatelessWidget {
  final double totalPayrollMonthly;
  final double attendanceRate;
  final int expiringDocsCount;
  final int pendingLeavesCount;
  final bool isMobile;
  final String currency;

  const HRDashboardTab({
    super.key,
    required this.totalPayrollMonthly,
    required this.attendanceRate,
    required this.expiringDocsCount,
    required this.pendingLeavesCount,
    required this.isMobile,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildStatCardsGrid(context),
        const SizedBox(height: 20),
        _buildChartSection(context),
      ],
    );
  }

  Widget _buildStatCardsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(context, tr('hr.stats.total_payroll'), "${totalPayrollMonthly.toStringAsFixed(0)} ${CurrencyService.getSymbol(currency)}", Icons.account_balance_wallet_outlined, Colors.greenAccent),
        _buildStatCard(context, tr('hr.stats.attendance_rate'), "${attendanceRate.toStringAsFixed(1)} %", Icons.how_to_reg_outlined, Colors.blueAccent),
        _buildStatCard(context, tr('hr.stats.expiring_docs'), "$expiringDocsCount", Icons.assignment_late_outlined, Colors.redAccent),
        _buildStatCard(context, tr('hr.stats.pending_leaves'), "$pendingLeavesCount", Icons.event_busy_outlined, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.sheetGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: context.mutedText, fontSize: 9, overflow: TextOverflow.ellipsis)),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 300,
      decoration: BoxDecoration(
        color: context.sheetGlass,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('hr.charts.payroll_analytics'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(tr('hr.charts.comparison_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 12)),
          const Expanded(child: Padding(padding: EdgeInsets.only(top: 24, right: 16), child: LineChartSample())),
        ],
      ),
    );
  }
}

class LineChartSample extends StatelessWidget {
  const LineChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 7,
        minY: 0,
        maxY: 6,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3.44),
              FlSpot(2.6, 3.44),
              FlSpot(4.9, 3.44),
              FlSpot(6.8, 3.44),
              FlSpot(8, 3.44),
              FlSpot(9.5, 3.44),
              FlSpot(11, 3.44),
            ],
            isCurved: true,
            color: primaryOrange,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryOrange.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
