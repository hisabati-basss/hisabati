import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
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

class HrRootScreen extends StatefulWidget {
  const HrRootScreen({super.key});

  @override
  State<HrRootScreen> createState() => _HrRootScreenState();
}

class _HrRootScreenState extends State<HrRootScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final PayrollService _payrollService = PayrollService();
  
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
    if (expiryDate == null) return "ساري";
    final diff = expiryDate.difference(DateTime.now()).inDays;
    if (diff < 0) return "منتهي";
    if (diff < 30) return "ينتهي قريباً";
    return "ساري";
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

    final today = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(today);
    final db = await _db.database;

    final existing = await db.query('attendance_logs',
      where: "employee_id = ? AND date >= ? AND date < ?",
      whereArgs: [emp['id'], DateTime(today.year, today.month, today.day).toIso8601String(), DateTime(today.year, today.month, today.day + 1).toIso8601String()]);

    if (existing.isEmpty) {
      await db.insert('attendance_logs', {
        'id': 'ATT_${DateTime.now().millisecondsSinceEpoch}',
        'employee_id': emp['id'],
        'date': today.toIso8601String(),
        'status': 'present',
        'check_in_time': type == 'check_in' ? timeStr : null,
        'check_out_time': type == 'check_out' ? timeStr : null,
        'sync_status': 0,
        'updated_at': today.toIso8601String(),
      });
    } else {
      final updateField = type == 'check_in' ? 'check_in_time' : 'check_out_time';
      await db.update('attendance_logs', {updateField: timeStr, 'sync_status': 0},
        where: 'id = ?', whereArgs: [existing.first['id']]);
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
    // Show summary or dialog (Reuse helper from hr_screen or moved)
  }

  String _getCCName(String id) {
    final cc = _costCenters.where((c) => c['code']?.toString() == id).firstOrNull;
    return cc?['name']?.toString() ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : DefaultTabController(
            length: 6,
            child: Column(
              children: [
                _buildScreenHeader(isMobile),
                _buildTabBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        ),
                        LeavesTab(
                          leaveRequests: _leaveRequests,
                          onAddRequest: () {}, // To be implemented
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
                          onHire: (c) => _showEmployeeForm(employee: c),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildScreenHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.people_alt_rounded, color: primaryOrange, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('hr.header.module_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(tr('hr.header.module_subtitle'), style: TextStyle(color: context.mutedText, fontSize: 13)),
                ],
              ),
            ],
          ),
          if (!isMobile)
            ElevatedButton.icon(
              onPressed: () => _showEmployeeForm(),
              icon: const Icon(Icons.add, color: Colors.black, size: 20),
              label: Text(tr('hr.header.add_employee_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        isScrollable: true,
        indicator: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryOrange.withValues(alpha: 0.3))),
        labelColor: primaryOrange,
        unselectedLabelColor: Colors.white30,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: tr('hr.tabs.general')),
          Tab(text: tr('hr.tabs.employees')),
          Tab(text: tr('hr.tabs.attendance')),
          Tab(text: tr('hr.tabs.leaves')),
          Tab(text: tr('hr.tabs.payroll')),
          Tab(text: tr('hr.tabs.recruitment')),
        ],
      ),
    );
  }
}
