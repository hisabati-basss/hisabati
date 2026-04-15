import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';

class LeavesTab extends StatelessWidget {
  final List<Map<String, dynamic>> leaveRequests;
  final VoidCallback onAddRequest;
  final Function(String, String) onUpdateStatus;

  const LeavesTab({
    super.key,
    required this.leaveRequests,
    required this.onAddRequest,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildRequestsList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("طلبات الإجازات والمعلقات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
        ElevatedButton.icon(
          onPressed: onAddRequest,
          icon: const Icon(Icons.add, color: Colors.black, size: 18),
          label: const Text("طلب إجازة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    return Expanded(
      child: leaveRequests.isEmpty
        ? Center(child: Text(tr('hr.no_data'), style: TextStyle(color: context.mutedText)))
        : ListView.builder(
            itemCount: leaveRequests.length,
            itemBuilder: (ctx, idx) => _buildRequestCard(context, leaveRequests[idx]),
          ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> req) {
    final empName = req['employee_name']?.toString() ?? 'موظف غير معروف';
    final startDateStr = req['start_date']?.toString().split('T').first ?? '';
    final endDateStr = req['end_date']?.toString().split('T').first ?? '';
    final leaveType = req['leave_type']?.toString() ?? '';
    final status = req['status']?.toString() ?? 'pending';
    final reqId = req['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.sheetGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(empName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("$startDateStr - $endDateStr", style: TextStyle(color: context.mutedText, fontSize: 12)),
                    Text("النوع: $leaveType", style: const TextStyle(color: primaryOrange, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    _buildStatusBadge(status),
                    if (status == 'pending') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () => onUpdateStatus(reqId, 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        onPressed: () => onUpdateStatus(reqId, 'rejected'),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String label = "معلق";
    if (status == 'approved') { color = Colors.green; label = "مقبول"; }
    if (status == 'rejected') { color = Colors.redAccent; label = "مرفوض"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: color.withValues(alpha: 0.3))
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
