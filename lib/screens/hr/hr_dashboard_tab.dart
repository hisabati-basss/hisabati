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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildSlimGlassKPIBar(context, isDark),
        const SizedBox(height: 20),
        _buildGlassChartSection(context, isDark),
      ],
    );
  }

  Widget _buildSlimGlassKPIBar(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
             Expanded(child: _buildGlassKPI(context, tr('hr.stats.total_payroll'), "${totalPayrollMonthly.toStringAsFixed(0)} ${CurrencyService.getSymbol(currency)}", Icons.payments_rounded, Colors.greenAccent, isDark)),
             const SizedBox(width: 8),
             Expanded(child: _buildGlassKPI(context, tr('hr.stats.attendance_rate'), "${attendanceRate.toStringAsFixed(1)}%", Icons.how_to_reg_rounded, Colors.blueAccent, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
             Expanded(child: _buildGlassKPI(context, tr('hr.stats.expiring_docs'), "$expiringDocsCount", Icons.warning_amber_rounded, Colors.redAccent, isDark)),
             const SizedBox(width: 8),
             Expanded(child: _buildGlassKPI(context, tr('hr.stats.pending_leaves'), "$pendingLeavesCount", Icons.event_note_rounded, Colors.orangeAccent, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassKPI(BuildContext context, String title, String value, IconData icon, Color color, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: context.mutedText, fontSize: 9, fontWeight: FontWeight.w500)),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChartSection(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('hr.charts.payroll_analytics'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(tr('hr.charts.comparison_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                    ],
                  ),
                  const Icon(Icons.analytics_outlined, color: primaryOrange, size: 20),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 180, child: LineChartSample()),
            ],
          ),
        ),
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
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(2.6, 2),
              FlSpot(4.9, 5),
              FlSpot(6.8, 3.1),
              FlSpot(8, 4),
              FlSpot(9.5, 3),
              FlSpot(11, 4),
            ],
            isCurved: true,
            color: primaryOrange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [primaryOrange.withValues(alpha: 0.2), primaryOrange.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
