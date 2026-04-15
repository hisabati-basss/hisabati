import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';
import 'tabs/documents_tab.dart';
import 'tabs/custody_tab.dart';
import 'tabs/performance_tab.dart';
import 'tabs/contracts_tab.dart';

class EmployeeDetailsView extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onEdit;
  final Color Function(DateTime?) statusColorPicker;
  final String Function(DateTime?) statusTextPicker;

  const EmployeeDetailsView({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.statusColorPicker,
    required this.statusTextPicker,
  });

  @override
  Widget build(BuildContext context) {
    final empName = employee['name']?.toString() ?? '';
    final empJobTitle = employee['job_title']?.toString() ?? 'N/A';
    final empPhone = employee['phone']?.toString() ?? 'N/A';
    final empEmail = employee['email']?.toString() ?? 'N/A';
    final empNationality = employee['nationality']?.toString() ?? 'السعودية';
    final empIdNumber = employee['id_number']?.toString() ?? 'N/A';
    final empPassportNumber = employee['passport_number']?.toString() ?? 'N/A';
    final empDepartment = employee['department']?.toString() ?? 'N/A';
    final empHiringDate = employee['hiring_date']?.toString() ?? 'N/A';
    final empInsuranceNumber = employee['insurance_number']?.toString() ?? 'N/A';
    final empEmergencyPhone = employee['emergency_phone']?.toString() ?? 'N/A';
    final empBasicSalary = (employee['basic_salary'] as num?)?.toDouble() ?? 0;
    final empAnnualLeave = (employee['annual_leave_balance'] as num?)?.toDouble() ?? 0;
    final empSickLeave = (employee['sick_leave_balance'] as num?)?.toDouble() ?? 0;

    DateTime? idExpiryDate;
    DateTime? passExpiryDate;
    try { idExpiryDate = employee['id_expiry_date'] != null ? DateTime.parse(employee['id_expiry_date'].toString()) : null; } catch (_) {}
    try { passExpiryDate = employee['passport_expiry_date'] != null ? DateTime.parse(employee['passport_expiry_date'].toString()) : null; } catch (_) {}

    return DefaultTabController(
      length: 7,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: context.sheetGlass, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildHeader(context, empName, empJobTitle),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPersonalTab(context, empPhone, empEmail, empNationality, empIdNumber, idExpiryDate, empPassportNumber, passExpiryDate),
                      ContractsTab(employeeId: employee['id']?.toString() ?? 'unknown', employee: employee),
                      _buildBalancesTab(context, empAnnualLeave, empSickLeave, empBasicSalary),
                      CustodyTab(employeeId: employee['id']?.toString() ?? 'unknown'),
                      PerformanceTab(employeeId: employee['id']?.toString() ?? 'unknown'),
                      DocumentsTab(employeeId: employee['id']?.toString() ?? 'unknown'),
                      _buildHealthTab(context, empDepartment, empHiringDate, empInsuranceNumber, empEmergencyPhone),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String job) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32, 
            backgroundColor: primaryOrange.withValues(alpha: 0.1), 
            child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 24, color: primaryOrange, fontWeight: FontWeight.bold))
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(job, style: TextStyle(color: context.mutedText, fontSize: 13)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.edit_note, color: primaryOrange), onPressed: onEdit),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      isScrollable: true,
      tabs: [
        const Tab(icon: Icon(Icons.person_outline, size: 18), text: "hr.tabs.personal"), 
        const Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: "hr.tabs.contracts"),
        const Tab(icon: Icon(Icons.payments_outlined, size: 18), text: "hr.tabs.financial"), 
        const Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: "hr.tabs.custody"),
        const Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: "hr.tabs.performance"),
        const Tab(icon: Icon(Icons.folder_shared_outlined, size: 18), text: "hr.tabs.documents"),
        const Tab(icon: Icon(Icons.medical_services_outlined, size: 18), text: "hr.tabs.health"), 
      ].map((tab) => Tab(icon: tab.icon, text: (tab.text ?? "").tr())).toList(),
      labelColor: primaryOrange, 
      unselectedLabelColor: Colors.white30,
      indicatorColor: primaryOrange,
    );
  }

  Widget _buildPersonalTab(BuildContext context, String phone, String email, String nationality, String idNum, DateTime? idExp, String passNum, DateTime? passExp) {
    return _buildDetailView([
      _buildInfoTile(context, "الهاتف", phone, Icons.phone),
      _buildInfoTile(context, "البريد", email, Icons.email),
      _buildInfoTile(context, "الجنسية", nationality, Icons.public_rounded, statusColor: primaryOrange),
      _buildInfoTile(
        context, 
        "رقم الهوية", 
        idNum, 
        Icons.badge_outlined, 
        statusColor: statusColorPicker(idExp),
        statusText: statusTextPicker(idExp),
      ),
      _buildInfoTile(
        context, 
        "رقم الجواز", 
        passNum, 
        Icons.airplane_ticket_outlined, 
        statusColor: statusColorPicker(passExp),
        statusText: statusTextPicker(passExp),
      ),
    ]);
  }

  Widget _buildHealthTab(BuildContext context, String dept, String hiring, String ins, String emergency) {
    return _buildDetailView([
      _buildInfoTile(context, "القسم", dept, Icons.business),
      _buildInfoTile(context, "تاريخ التعيين", hiring.split('T').first, Icons.calendar_month),
      _buildInfoTile(context, "رقم التأمينات", ins, Icons.health_and_safety_outlined),
      _buildInfoTile(context, "هاتف الطوارئ", emergency, Icons.emergency),
    ]);
  }

  Widget _buildBalancesTab(BuildContext context, double annual, double sick, double basic) {
    return _buildDetailView([
      _buildBalanceMeter(context, "رصيد الإجازات السنوية", annual, 21.0, Icons.beach_access),
      _buildBalanceMeter(context, "رصيد الإجازات المرضية", sick, 15.0, Icons.medical_services),
      _buildInfoTile(context, "الراتب الأساسي", "$basic ر.س", Icons.money),
    ]);
  }

  Widget _buildDetailView(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon, {Color? statusColor, String? statusText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor?.withValues(alpha: 0.3) ?? primaryOrange.withValues(alpha: 0.2), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.mutedText, fontSize: 11)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (statusText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: statusColor?.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMeter(BuildContext context, String label, double current, double total, IconData icon) {
    double progress = (current / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white24, size: 16),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Text("${current.toStringAsFixed(1)} / $total يوماً", style: const TextStyle(color: primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: primaryOrange, minHeight: 6, borderRadius: BorderRadius.circular(3)),
        ],
      ),
    );
  }
}
