import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; 
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme_extension.dart';
import '../../services/email_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_admin_service.dart';
import '../../services/payroll_service.dart';
import '../../services/shift_service.dart';

class EmployeeForm extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final bool asCandidate;
  final List<Map<String, dynamic>> costCenters;
  final Function() onSuccess;

  const EmployeeForm({
    super.key,
    this.employee,
    this.asCandidate = false,
    required this.costCenters,
    required this.onSuccess,
  });

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final PayrollService _payrollService = PayrollService();
  final ShiftService _shiftService = ShiftService();
  
  late TextEditingController _nameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _idNumberController;
  late TextEditingController _passportNumberController;
  late TextEditingController _insuranceNumberController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _basicSalaryController;
  late TextEditingController _ibanController;
  late TextEditingController _departmentController;
  late TextEditingController _personalEmailController;
  
  DateTime? _idExpiry;
  DateTime? _passExpiry;
  DateTime? _hireDate;
  String? _selectedCC;
  String? _selectedShiftId;
  List<Map<String, dynamic>> _shifts = [];
  late String _selectedNationality;

  final Map<String, dynamic> _validationRules = {
    "hr.nationalities.saudi": {"idLen": 10, "phLen": 10, "phPrefix": "05", "idLabel": "hr.id_labels.saudi"},
    "hr.nationalities.egypt": {"idLen": 14, "phLen": 11, "phPrefix": ["010", "011", "012", "015"], "idLabel": "hr.id_labels.egypt"},
    "hr.nationalities.uae": {"idLen": 15, "phLen": 10, "phPrefix": "", "idLabel": "hr.id_labels.uae"},
    "hr.nationalities.jordan": {"idLen": 10, "phLen": 10, "phPrefix": "", "idLabel": "hr.id_labels.jordan"},
    "hr.nationalities.other": {"idLen": 0, "phLen": 0, "phPrefix": "", "idLabel": "hr.id_labels.other"},
  };

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp?['name']?.toString());
    _jobTitleController = TextEditingController(text: emp?['job_title']?.toString());
    _phoneController = TextEditingController(text: emp?['phone']?.toString());
    _emailController = TextEditingController(text: emp?['email']?.toString());
    _idNumberController = TextEditingController(text: emp?['id_number']?.toString());
    _passportNumberController = TextEditingController(text: emp?['passport_number']?.toString());
    _insuranceNumberController = TextEditingController(text: emp?['insurance_number']?.toString());
    _emergencyPhoneController = TextEditingController(text: emp?['emergency_phone']?.toString());
    _basicSalaryController = TextEditingController(text: emp?['basic_salary']?.toString());
    _ibanController = TextEditingController(text: emp?['iban']?.toString());
    _departmentController = TextEditingController(text: emp?['department']?.toString());
    _personalEmailController = TextEditingController(text: emp?['personal_email']?.toString());
    
    try { _idExpiry = emp?['id_expiry_date'] != null ? DateTime.parse(emp!['id_expiry_date'].toString()) : null; } catch (_) {}
    try { _passExpiry = emp?['passport_expiry_date'] != null ? DateTime.parse(emp!['passport_expiry_date'].toString()) : null; } catch (_) {}
    try { _hireDate = emp?['hiring_date'] != null ? DateTime.parse(emp!['hiring_date'].toString()) : DateTime.now(); } catch (_) { _hireDate = DateTime.now(); }
    final String rawNat = emp?['nationality']?.toString() ?? "hr.nationalities.saudi";
    if (rawNat == "السعودية") {
      _selectedNationality = "hr.nationalities.saudi";
    } else if (rawNat == "مصر") {
      _selectedNationality = "hr.nationalities.egypt";
    } else if (rawNat == "الإمارات") {
      _selectedNationality = "hr.nationalities.uae";
    } else if (rawNat == "الأردن") {
      _selectedNationality = "hr.nationalities.jordan";
    } else {
      _selectedNationality = rawNat;
    }
    
    if (!_validationRules.containsKey(_selectedNationality)) {
      _selectedNationality = "hr.nationalities.saudi";
    }
    
    _selectedShiftId = emp?['shift_id']?.toString();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    final shifts = await _shiftService.getShifts();
    if (mounted) setState(() => _shifts = shifts);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: context.sheetGlass,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      children: [
                        _buildPersonalTab(),
                        _buildJobTab(),
                        _buildFinancialTab(),
                      ],
                    ),
                  ),
                ),
                _buildActionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.employee == null 
              ? (widget.asCandidate ? tr('hr.form.new_candidate') : tr('hr.form.add_employee')) 
              : tr('hr.form.edit_employee'), 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54), 
            onPressed: () => Navigator.pop(context)
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      tabs: [
        Tab(text: tr('hr.form.tabs.personal'), icon: const Icon(Icons.person_pin, size: 20)),
        Tab(text: tr('hr.form.tabs.job'), icon: const Icon(Icons.work_history, size: 20)),
        Tab(text: tr('hr.form.tabs.financial'), icon: const Icon(Icons.account_balance_wallet, size: 20)),
      ],
      indicatorColor: primaryOrange,
      labelColor: primaryOrange,
      unselectedLabelColor: Colors.white30,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFormField(tr('hr.form.fields.name'), _nameController, Icons.person, required: true),
          
          _buildNationalityDropdown(),

          _buildFormField(
            tr('hr.form.fields.phone'), 
            _phoneController, 
            Icons.phone,
            required: true,
            isNumber: true,
            maxLength: _validationRules[_selectedNationality]["phLen"] > 0 ? _validationRules[_selectedNationality]["phLen"] : 15,
            validator: (v) {
              if (v == null || v.isEmpty) return tr('hr.form.validation.required');
              final rules = _validationRules[_selectedNationality];
              if (rules["phLen"] > 0 && v.length != rules["phLen"]) return tr('hr.form.validation.phone_length').replaceFirst('{}', rules['phLen'].toString());
              return null;
            }
          ),
          _buildFormField(
            tr('hr.form.fields.personal_email'), 
            _personalEmailController, 
            Icons.email_outlined, 
            required: true,
            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? tr('hr.form.validation.invalid_email') : null
          ),
          _buildFormField(tr('hr.form.fields.work_email'), _emailController, Icons.alternate_email, required: false, enabled: false),
          const Divider(color: Colors.white10, height: 32),
          _buildFormField(
            tr(_validationRules[_selectedNationality]["idLabel"]), 
            _idNumberController, 
            Icons.badge_outlined, 
            required: true, 
            isNumber: true,
            maxLength: _validationRules[_selectedNationality]["idLen"] > 0 ? _validationRules[_selectedNationality]["idLen"] : 20,
            onChanged: (v) {
              if (widget.employee == null && _validationRules[_selectedNationality]["idLen"] > 0 && v.length == _validationRules[_selectedNationality]["idLen"]) {
                _emailController.text = "$v@hbas-app.com";
              }
            }
          ),
          _buildDatePickerRow(tr('hr.form.fields.id_expiry'), _idExpiry, (d) => setState(() => _idExpiry = d)),
          _buildDatePickerRow(tr('hr.form.fields.passport_expiry'), _passExpiry, (d) => setState(() => _passExpiry = d)),
        ],
      ),
    );
  }

  Widget _buildJobTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFormField(tr('hr.form.fields.job_title'), _jobTitleController, Icons.work_outline),
          _buildFormField(tr('hr.form.fields.department'), _departmentController, Icons.corporate_fare_rounded),
          _buildDatePickerRow(tr('hr.form.fields.hire_date'), _hireDate, (d) => setState(() => _hireDate = d)),
          const Divider(color: Colors.white10, height: 32),
          _buildFormField(tr('hr.form.fields.insurance_number'), _insuranceNumberController, Icons.verified_user_outlined, required: false),
          _buildFormField(tr('hr.form.fields.emergency_phone'), _emergencyPhoneController, Icons.support_agent_rounded, required: false),
          const SizedBox(height: 16),
          _buildShiftDropdown(),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFormField(tr('hr.form.fields.basic_salary'), _basicSalaryController, Icons.account_balance_wallet_rounded, isNumber: true),
          _buildFormField(tr('hr.form.fields.iban'), _ibanController, Icons.credit_card_rounded, required: false),
          const SizedBox(height: 16),
          _buildCCDropdown(),
        ],
      ),
    );
  }

  Widget _buildNationalityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedNationality,
        dropdownColor: const Color(0xFF1E1E24),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: tr('hr.form.fields.nationality'),
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: const Icon(Icons.flag_outlined, color: primaryOrange, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: _validationRules.keys.map((nat) => DropdownMenuItem(value: nat, child: Text(tr(nat)))).toList(),
        onChanged: (v) => setState(() => _selectedNationality = v!),
      ),
    );
  }

  Widget _buildShiftDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedShiftId,
      decoration: InputDecoration(
        labelText: tr('hr.form.fields.shift'),
        prefixIcon: const Icon(Icons.timer_outlined, color: primaryOrange),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      items: _shifts.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (val) => setState(() => _selectedShiftId = val),
    );
  }

  Widget _buildCCDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCC,
      decoration: InputDecoration(
        labelText: tr('hr.form.fields.cost_center'),
        prefixIcon: const Icon(Icons.account_tree_outlined, color: primaryOrange),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      items: widget.costCenters.map((cc) => DropdownMenuItem(value: cc['code']?.toString(), child: Text(cc['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (val) => setState(() => _selectedCC = val),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _handleSave,
          child: Text(tr('hr.form.buttons.save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'nationality': _selectedNationality,
      'job_title': _jobTitleController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'id_number': _idNumberController.text,
      'id_expiry_date': _idExpiry?.toIso8601String(),
      'passport_number': _passportNumberController.text,
      'passport_expiry_date': _passExpiry?.toIso8601String(),
      'insurance_number': _insuranceNumberController.text,
      'emergency_phone': _emergencyPhoneController.text,
      'basic_salary': double.tryParse(_basicSalaryController.text) ?? 0,
      'iban': _ibanController.text,
      'department': _departmentController.text,
      'personal_email': _personalEmailController.text,
      'hiring_date': _hireDate?.toIso8601String(),
      'cost_center_id': _selectedCC,
      'shift_id': _selectedShiftId,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.employee == null) {
        // Cloud Provisioning
        final authRes = await SupabaseAdminService().provisionEmployeeAccess(
          fullName: _nameController.text,
          jobTitle: _jobTitleController.text,
          personalEmail: _personalEmailController.text,
          companyName: "حساباتي ERP",
        );
        
        String? generatedPassword;
        if (authRes != null) {
          data['email'] = authRes['virtual_email'];
          generatedPassword = authRes['password'];
        }
        
        data['id'] = const Uuid().v4();
        data['employee_id'] = "EMP-${DateTime.now().millisecondsSinceEpoch % 100000}";
        data['status'] = widget.asCandidate ? 'candidate' : 'active';
        await _payrollService.addEmployee(data);

        // --- Trigger Welcome Email ---
        if (authRes != null) {
          final emailService = EmailService();
          final success = await emailService.sendWelcomeEmail(
            targetEmail: _personalEmailController.text,
            employeeName: _nameController.text,
            companyName: "Hisabati ERP",
            virtualEmail: authRes['virtual_email']!,
            password: authRes['password']!,
          );
          
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("⚠️ تنبيه: فشل إرسال الإيميل الترحيبي - ${emailService.lastError ?? 'تأكد من إعدادات SMTP'}"),
              backgroundColor: Colors.orange.shade900,
              duration: const Duration(seconds: 8),
            ));
          }
        }
        
        // --- Show Credential Summary if new account was created ---
        if (generatedPassword != null && mounted) {
           _showCredentialDialog(data['email'] as String, generatedPassword);
        } else {
           widget.onSuccess();
           if (mounted) Navigator.pop(context);
        }
      } else {
        await _payrollService.updateEmployee(widget.employee!['id']?.toString() ?? '', data);
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.redAccent));
    }
  }

  void _showCredentialDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: primaryOrange.withValues(alpha: 0.3))
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("تم إنشاء الحساب بنجاح", 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("تم إرسال بيانات الدخول إلى بريد الموظف. يرجى حفظ البيانات التالية أيضاً:", 
                style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 20),
              _buildCredentialRow("البريد الوظيفي", email),
              const SizedBox(height: 12),
              _buildCredentialRow("كلمة المرور", password),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              widget.onSuccess();
              if (mounted) Navigator.pop(context); // Close Form
            },
            child: const Text("إغلاق", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, color: primaryOrange, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("تم نسخ $label بنجاح"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: primaryOrange,
                  duration: const Duration(seconds: 1),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool required = true, bool enabled = true, int? maxLength, String? Function(String?)? validator, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon: Icon(icon, color: primaryOrange, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        validator: validator ?? ((v) => (required && (v == null || v.isEmpty)) ? tr('hr.form.validation.required') : null),
        onChanged: onChanged,
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context, 
          initialDate: date ?? DateTime.now(), 
          firstDate: DateTime(1950), 
          lastDate: DateTime(2100)
        );
        if (d != null) onSelect(d);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: primaryOrange, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const Spacer(),
            Text(date != null ? DateFormat('yyyy-MM-dd').format(date) : tr('hr.form.fields.select_date'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
