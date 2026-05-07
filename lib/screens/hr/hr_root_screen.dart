import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';
import '../../services/database_helper.dart';
import '../../services/payroll_service.dart';

import 'hr_dashboard_tab.dart';
import 'employee_list_view.dart';
import 'employee_form.dart';
import 'employee_details_view.dart';
import 'attendance_tab.dart';
import 'leaves_tab.dart';
import 'payroll_tab.dart';
import 'recruitment_tab.dart';
import 'tabs/shift_management_tab.dart';
import '../../services/attendance_service.dart';

class HrRootScreen extends StatefulWidget {
  const HrRootScreen({super.key});

  @override
  State<HrRootScreen> createState() => _HrRootScreenState();
}

class _HrRootScreenState extends State<HrRootScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final PayrollService _payrollService = PayrollService();
  final AttendanceService _attendanceService = AttendanceService();
  
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _candidates = [];
  List<Map<String, dynamic>> _costCenters = [];
  List<Map<String, dynamic>> _attendanceToday = [];
  List<Map<String, dynamic>> _salarySlips = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  
  bool _isLoading = true;
  bool _isProcessingPayroll = false;

  // Dashboard Stats
  double _totalPayrollMonthly = 0.0;
  int _expiringDocsCount = 0;
  double _attendanceRate = 0.0;
  int _pendingLeavesCount = 0;
  String _currency = 'sar';

  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadContext();
    _loadData();
  }

  Future<void> _loadContext() async {
    final ctx = await _db.getCurrentCompanyContext();
    if (mounted) setState(() => _currency = ctx['currency'] ?? 'sar');
  }

  Future<void> _loadData() async {
    try {
      final employees = await _payrollService.getEmployees();
      final db = await _db.database;
      final costCenters = await db.query('accounts', where: "type = 'expense'");
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day + 1).toIso8601String();

      final attendanceToday = await db.query('attendance_logs', where: "date >= '$startOfDay' AND date < '$endOfDay'");
      final slips = await db.query('salary_slips', orderBy: 'payment_date DESC', limit: 50);
      final leaves = await db.query('leave_requests', orderBy: 'start_date DESC');

      if (mounted) {
        setState(() {
          _employees = employees.where((e) => e['status'] == 'active').toList();
          _candidates = employees.where((e) => e['status'] == 'candidate').toList();
          _costCenters = costCenters;
          _attendanceToday = attendanceToday;
          _salarySlips = slips;
          _leaveRequests = leaves;
          
          _totalPayrollMonthly = _employees.fold(0.0, (sum, e) => sum + 
            ((e['basic_salary'] as num?)?.toDouble() ?? 0) + 
            ((e['housing_allowance'] as num?)?.toDouble() ?? 0) + 
            ((e['transport_allowance'] as num?)?.toDouble() ?? 0));
            
          _expiringDocsCount = _employees.where((e) {
            final idExp = e['id_expiry_date'];
            if (idExp == null) return false;
            try { 
              return DateTime.parse(idExp.toString()).difference(DateTime.now()).inDays < 30; 
            } catch (_) { return false; }
          }).length;
          
          _attendanceRate = _employees.isEmpty ? 0 : (_attendanceToday.length / _employees.length) * 100;
          _pendingLeavesCount = _leaveRequests.where((r) => r['status'] == 'pending').length;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${tr('hr.processing_error')}$e")));
      }
    }
  }

  void _showEmployeeForm({Map<String, dynamic>? employee, bool asCandidate = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmployeeForm(
        employee: employee,
        asCandidate: asCandidate,
        costCenters: _costCenters,
        onSuccess: _loadData,
      ),
    );
  }

  Future<void> _hireCandidate(Map<String, dynamic> candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryOrange.withValues(alpha: 0.3))),
        title: Row(
          children: [
            Icon(Icons.how_to_reg, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Text(tr('hr.hire_confirm_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('hr.hire_confirm_msg', args: [candidate['name']]), style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Text(tr('hr.hire_confirm_note'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel'), style: const TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, color: Colors.black, size: 18),
            label: Text(tr('hr.form.buttons.hire_confirm'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _payrollService.updateEmployee(
          candidate['id']?.toString() ?? '',
          {
            'status': 'active',
            'hiring_date': DateTime.now().toIso8601String(),
            'sync_status': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('hr.hire_success', args: [candidate['name'] ?? ''])),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${tr('common.error')}: $e'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    }
  }


  void _viewDetails(Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmployeeDetailsView(
        employee: emp,
        onEdit: () {
          Navigator.pop(ctx);
          _showEmployeeForm(employee: emp);
        },
        statusColorPicker: _getStatusColor,
        statusTextPicker: _getStatusText,
      ),
    );
  }

  Color _getStatusColor(DateTime? expiryDate) {
    if (expiryDate == null) return Colors.greenAccent;
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.redAccent;
    if (diff < 30) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _getStatusText(DateTime? expiryDate) {
    if (expiryDate == null) return tr('hr.status.valid');
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return tr('hr.status.expired');
    if (diff < 30) return tr('hr.status.expiring_soon');
    return tr('hr.status.valid');
  }

  Future<void> _handleAttendanceScan(String barcode, String type) async {
    if (barcode.isEmpty) return;
    final emp = _employees.where((e) => e['employee_id'] == barcode).firstOrNull;
    if (emp == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('hr.invalid_barcode'))));
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
      return;
    }

    if (type == 'check_in') {
      await _db.recordCheckIn(emp['id']);
    } else {
      final today = DateTime.now();
      final dateStr = today.toIso8601String().split('T')[0];
      final db = await _db.database;
      final existing = await db.query('attendance_logs',
        where: "employee_id = ? AND date = ?",
        whereArgs: [emp['id'], dateStr]);
      
      if (existing.isNotEmpty) {
        await _db.recordCheckOut(existing.first['id'].toString());
      }
    }

    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
    _loadData();
  }

  Future<void> _handleBulkPayroll() async {
    final String currentMonth = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    setState(() => _isProcessingPayroll = true);
    try {
      final result = await _payrollService.processMonthlyPayroll(currentMonth);
      if (result['success'] == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('hr.payroll.success_msg')), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${tr('common.error')}: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessingPayroll = false);
    }
  }

  void _viewSlipDetails(Map<String, dynamic> slip) {
    final empName = _employees.firstWhere(
      (e) => e['id'] == slip['employee_id'],
      orElse: () => {'name': 'employee'},
    )['name'] ?? 'employee';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$empName - ${slip['month'] ?? ''}'.trim()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _slipRow(tr('hr.payroll.basic'), '${(slip['basic_salary'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow(tr('hr.payroll.housing'), '${(slip['housing_allowance'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow(tr('hr.payroll.transport'), '${(slip['transport_allowance'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              const Divider(),
              _slipRow(tr('hr.payroll.insurance'), '${(slip['insurance_deduction'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              _slipRow(tr('hr.payroll.absence'), '${(slip['absence_deduction'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency'),
              const Divider(),
              _slipRow(tr('hr.payroll.net'), '${(slip['net_salary'] as num?)?.toStringAsFixed(2) ?? '0'} $_currency', isBold: true),
              _slipRow(tr('hr.payroll.status'), slip['payment_status']?.toString() ?? 'draft'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.close'))),
        ],
      ),
    );
  }

  Widget _slipRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 13,
            color: isBold ? primaryOrange : null,
          )),
        ],
      ),
    );
  }

  String _getCCName(String? id) {
    if (id == null) return '';
    final cc = _costCenters.firstWhere((c) => c['id']?.toString() == id.toString(), orElse: () => {});
    return cc['name']?.toString() ?? id;
  }

  void _showLeaveForm() {
    String? selectedEmpId;
    String leaveType = 'ANNUAL';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('hr.leaves.add_request')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedEmpId,
                  decoration: InputDecoration(
                    labelText: tr('hr.leaves.employee'),
                    hintText: tr('hr.leaves.select_employee'),
                  ),
                  items: _employees
                      .where((e) => e['id'] != null)
                      .map((e) => e['id'].toString())
                      .toSet() // Ensure unique IDs
                      .map((id) {
                        final emp = _employees.firstWhere((e) => e['id'].toString() == id);
                        return DropdownMenuItem(
                          value: id,
                          child: Text(emp['name']?.toString() ?? id),
                        );
                      }).toList(),
                  onChanged: (v) => setDialogState(() => selectedEmpId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: leaveType,
                  decoration: InputDecoration(labelText: tr('hr.leaves.type')),
                  items: [
                    DropdownMenuItem(value: 'ANNUAL', child: Text(tr('hr.leaves.types.annual'))),
                    DropdownMenuItem(value: 'SICK', child: Text(tr('hr.leaves.types.sick'))),
                    DropdownMenuItem(value: 'EMERGENCY', child: Text(tr('hr.leaves.types.emergency'))),
                    DropdownMenuItem(value: 'UNPAID', child: Text(tr('hr.leaves.types.unpaid'))),
                  ],
                  onChanged: (v) => setDialogState(() => leaveType = v ?? 'ANNUAL'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(tr('hr.leaves.from')),
                  subtitle: Text(startDate.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  title: Text(tr('hr.leaves.to')),
                  subtitle: Text(endDate.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(labelText: tr('hr.leaves.reason')),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null) return;
                await _payrollService.submitLeaveRequest({
                  'employee_id': selectedEmpId,
                  'type': leaveType,
                  'start_date': startDate.toIso8601String(),
                  'end_date': endDate.toIso8601String(),
                  'reason': reasonCtrl.text,
                });
                if (mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: Text(tr('common.submit')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerateAttendanceReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: primaryOrange)),
    );

    final report = await _attendanceService.generateDailyReport(DateTime.now());
    
    if (mounted) Navigator.pop(context); // Close loading

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(tr('hr.attendance.report_title'), style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReportStatRow(tr('common.all'), report['total_employees'].toString(), Colors.blueAccent),
                _buildReportStatRow(tr('hr.attendance.on_time'), report['on_time'].length.toString(), Colors.greenAccent),
                _buildReportStatRow(tr('hr.attendance.late'), report['late_count'].toString(), Colors.orangeAccent),
                _buildReportStatRow(tr('hr.attendance.absent'), report['absent_count'].toString(), Colors.redAccent),
                const Divider(color: Colors.white10),
                const Text("المتأخرون:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ... (report['latecomers'] as List).map((l) => ListTile(
                  dense: true,
                  title: Text(l['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text("تأخير ${l['delay_minutes']} دقيقة", style: const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                )),
                if ((report['latecomers'] as List).isEmpty) const Text("لا يوجد متأخرون", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.close'))),
          ],
        ),
      );
    }
  }

  Widget _buildReportStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : DefaultTabController(
            length: 7,
            child: Column(
              children: [
                _buildSlimGlassHeader(isMobile, isDark),
                _buildGlassTabBar(isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: TabBarView(
                      children: [
                        HRDashboardTab(
                          totalPayrollMonthly: _totalPayrollMonthly,
                          attendanceRate: _attendanceRate,
                          expiringDocsCount: _expiringDocsCount,
                          pendingLeavesCount: _pendingLeavesCount,
                          isMobile: isMobile,
                          currency: _currency,
                        ),
                        EmployeeListView(
                          employees: _employees,
                          isMobile: isMobile,
                          onEmployeeTap: (emp) => _viewDetails(emp),
                          statusColorPicker: _getStatusColor,
                          currency: _currency,
                        ),
                        AttendanceTab(
                          attendanceToday: _attendanceToday,
                          barcodeController: _barcodeController,
                          barcodeFocusNode: _barcodeFocusNode,
                          onScan: _handleAttendanceScan,
                          onGenerateReport: _handleGenerateAttendanceReport,
                        ),
                        LeavesTab(
                          leaveRequests: _leaveRequests,
                          onAddRequest: _showLeaveForm,
                          onUpdateStatus: (id, status) async {
                            await _payrollService.updateLeaveStatus(id, status);
                            _loadData();
                          },
                        ),
                        PayrollTab(
                          salarySlips: _salarySlips,
                          isProcessing: _isProcessingPayroll,
                          onProcessPayroll: _handleBulkPayroll,
                          onViewSlip: _viewSlipDetails,
                          getCCName: _getCCName,
                        ),
                          RecruitmentTab(
                            candidates: _candidates,
                            onAddCandidate: () => _showEmployeeForm(asCandidate: true),
                            onHire: (c) => _hireCandidate(c),
                          ),
                          const ShiftManagementTab(),
                        ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSlimGlassHeader(bool isMobile, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
            border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: context.textColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.people_alt_rounded, color: primaryOrange, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('hr.header.module_title'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                          Text(tr('hr.header.module_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 9), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isMobile)
                GestureDetector(
                  onTap: () => _showEmployeeForm(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: primaryOrange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(tr('hr.header.add_employee_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        ),
        labelColor: primaryOrange,
        unselectedLabelColor: context.mutedText,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: tr('hr.tabs.general')),
          Tab(text: tr('hr.tabs.employees')),
          Tab(text: tr('hr.tabs.attendance')),
          Tab(text: tr('hr.tabs.leaves')),
          Tab(text: tr('hr.tabs.payroll')),
          Tab(text: tr('hr.tabs.recruitment')),
          Tab(text: tr('hr.tabs.shifts')),
        ],
      ),
    );
  }
}
