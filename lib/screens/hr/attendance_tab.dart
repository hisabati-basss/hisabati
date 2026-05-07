import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';

class AttendanceTab extends StatelessWidget {
  final List<Map<String, dynamic>> attendanceToday;
  final TextEditingController barcodeController;
  final FocusNode barcodeFocusNode;
  final Function(String, String) onScan;
  final VoidCallback onGenerateReport;

  const AttendanceTab({
    super.key,
    required this.attendanceToday,
    required this.barcodeController,
    required this.barcodeFocusNode,
    required this.onScan,
    required this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tr('hr.attendance_today'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
            ElevatedButton.icon(
              onPressed: () => onGenerateReport(),
              icon: const Icon(Icons.assessment_outlined, size: 18),
              label: Text(tr('hr.attendance.generate_report'), style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange.withValues(alpha: 0.1),
                foregroundColor: primaryOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: primaryOrange)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildScannerArea(context),
        const SizedBox(height: 16),
        _buildAttendanceList(context),
      ],
    );
  }

  Widget _buildScannerArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.cardRadius / 2),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: primaryOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: barcodeController,
              focusNode: barcodeFocusNode,
              autofocus: true,
              style: TextStyle(fontSize: context.bodySize),
              decoration: InputDecoration(
                hintText: tr('hr.barcode_hint'),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (val) => onScan(val, "check_in"),
            ),
          ),
          _buildActionButton(context, Icons.login_rounded, tr('hr.check_in'), onPressed: () => onScan(barcodeController.text, "check_in"), isPrimary: true),
          const SizedBox(width: 8),
          _buildActionButton(context, Icons.logout_rounded, tr('hr.check_out'), onPressed: () => onScan(barcodeController.text, "check_out")),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: attendanceToday.isEmpty 
              ? Center(child: Text(tr('hr.no_attendance'), style: TextStyle(color: context.mutedText)))
              : ListView.builder(
                  itemCount: attendanceToday.length,
                  itemBuilder: (ctx, idx) => _buildLogCard(context, attendanceToday[idx]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    final String safeName = log['employee_name']?.toString() ?? log['employee_id']?.toString() ?? tr('hr.unknown_employee');
    final String jobTitle = log['job_title']?.toString() ?? '';
    final String checkIn = log['check_in_time']?.toString() ?? '';
    final String checkOut = log['check_out_time']?.toString() ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.cardRadius / 2),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryOrange.withValues(alpha: 0.1),
            child: Text(safeName.isNotEmpty ? safeName[0] : "?", style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(safeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                Text(jobTitle, style: TextStyle(color: context.mutedText, fontSize: 10)),
              ],
            ),
          ),
          _buildTimeBadge(context, tr('hr.check_in_short'), checkIn.isNotEmpty ? checkIn : null),
          const SizedBox(width: 8),
          _buildTimeBadge(context, tr('hr.check_out_short'), checkOut.isNotEmpty ? checkOut : null, isOut: true),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(BuildContext context, String label, String? time, {bool isOut = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (time == null) ? context.mutedText.withValues(alpha: 0.05) : (isOut ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 8, color: context.mutedText)),
          Text(time ?? "--:--", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: time == null ? context.mutedText : (isOut ? Colors.redAccent : Colors.greenAccent))),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, {required VoidCallback onPressed, bool isPrimary = false}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryOrange : context.cardSurface,
        foregroundColor: isPrimary ? Colors.black : context.textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: onPressed,
    );
  }
}
