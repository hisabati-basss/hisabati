import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';

class PayrollTab extends StatelessWidget {
  final List<Map<String, dynamic>> salarySlips;
  final bool isProcessing;
  final VoidCallback onProcessPayroll;
  final Function(Map<String, dynamic>) onViewSlip;
  final String Function(String) getCCName;

  const PayrollTab({
    super.key,
    required this.salarySlips,
    required this.isProcessing,
    required this.onProcessPayroll,
    required this.onViewSlip,
    required this.getCCName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildBulkActionButton(context),
        const SizedBox(height: 12),
        _buildSlipsList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(tr('hr.payroll.title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
        IconButton(
          icon: Icon(Icons.download_rounded, color: context.mutedText),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جاري تصدير كشف الرواتب إلى PDF...'),
                backgroundColor: Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },        ),
      ],
    );
  }

  Widget _buildBulkActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isProcessing 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
        label: Text(
          isProcessing ? tr('hr.payroll.processing') : tr('hr.payroll.process_btn'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isProcessing ? null : onProcessPayroll,
      ),
    );
  }

  Widget _buildSlipsList(BuildContext context) {
    return Expanded(
      child: salarySlips.isEmpty
        ? Center(child: Text(tr('hr.payroll.no_records'), style: TextStyle(color: context.mutedText)))
        : ListView.builder(
            itemCount: salarySlips.length,
            itemBuilder: (ctx, idx) => _buildSlipCard(context, salarySlips[idx]),
          ),
    );
  }

  Widget _buildSlipCard(BuildContext context, Map<String, dynamic> slip) {
    final String safeName = slip['employee_name']?.toString() ?? slip['employee_id']?.toString() ?? tr('hr.unknown_employee');
    final String month = slip['month']?.toString() ?? '';
    final double netSalary = (slip['net_salary'] as num?)?.toDouble() ?? 0;
    final String costCenter = slip['cost_center_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: const Icon(Icons.receipt_long_rounded, color: Colors.greenAccent),
        title: Text("$safeName - $month", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("${tr('hr.payroll.net_label')}: $netSalary ${tr('ceo.currency.sar')} | ${tr('hr.payroll.cost_center_label')}: ${getCCName(costCenter)}", style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 16),
        onTap: () => onViewSlip(slip),
      ),
    );
  }
}
