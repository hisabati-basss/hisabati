import 'dart:ui';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import 'currency_center_screen.dart';
import 'recurring_transactions_screen.dart';
import 'bank_reconciliation_screen.dart';
import 'admin/permissions_matrix_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _selectedTab = 0; // 0 = Users, 1 = Branches
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _branches = [];
  final DatabaseHelper _db = DatabaseHelper();

  // Internal state for toggling permissions
  final Map<String, bool> _permissions = {
    tr('users.permissions.add_entries'): true,
    tr('users.permissions.edit_invoices'): false,
    tr('users.permissions.export_reports'): true,
    tr('users.permissions.manage_hr'): false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var users = await _db.getSystemUsers();
      var branches = await _db.getCostCenters();

      // Seeding if empty
      if (users.isEmpty) {
        await _db.saveSystemUser({
          'id': 'ADMIN_01',
          'username': 'admin',
          'name': 'المدير العام',
          'email': 'admin@hisabati.com',
          'role': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        });
        users = await _db.getSystemUsers();
      }

      if (branches.isEmpty) {
        await _db.saveCostCenter({'id': 'BR_01', 'code': '101', 'name': 'المركز الرئيسي (الرياض)'});
        await _db.saveCostCenter({'id': 'BR_02', 'code': '102', 'name': 'فرع دبي'});
        branches = await _db.getCostCenters();
      }

      setState(() {
        _users = users;
        _branches = branches;
      });
    } catch (e) {
      debugPrint("Error loading users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryOrange));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 2), 
          child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('users.central_system'),
                      style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      tr('users.title'),
                      style: TextStyle(
                        fontSize: context.headerSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildTabs(context, isMobile),
              ],
            ),
          ),
        ),
        // Space eliminated

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _selectedTab == 0
                ? SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildUsersTab(context, isMobile))
                : _selectedTab == 1
                    ? SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildBranchesTab(context, isMobile))
                    : _selectedTab == 2
                        ? const CurrencyCenterScreen()
                        : _selectedTab == 3
                            ? const RecurringTransactionsScreen()
                            : const BankReconciliationScreen(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(2), 
      decoration: BoxDecoration(
        color: context.obsidianGlass,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.glassBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(
              context,
              tr('users.tabs.users'),
              0,
              Icons.people,
              isMobile,
            ),
            _buildTabButton(context, tr('users.tabs.branches'), 1, Icons.domain, isMobile),
            _buildTabButton(context, tr('currency.title'), 2, Icons.currency_exchange, isMobile),
            _buildTabButton(context, tr('recurring.title'), 3, Icons.auto_mode, isMobile),
          _buildTabButton(context, tr('bank_reconciliation.title'), 4, Icons.account_balance, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String title,
    int index,
    IconData icon,
    bool isMobile,
  ) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, 
          vertical: 5, 
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(100), 
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18, 
              color: isSelected ? Colors.black87 : context.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black87 : context.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, bool isMobile) {
    return Column(
      key: const ValueKey("users"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('users.managers_label'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            GestureDetector(
              onTap: _showAddUserDialog,
              child: _buildCapsuleButton(
                context,
                icon: Icons.person_add,
                label: tr('users.add_user_btn'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.sheetGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _users.isEmpty 
              ? [const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("لا يوجد مستخدمين بعد")))]
              : _users.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildUserItem(context, u, isMobile),
                )).toList(),
          ),
        ),
        const SizedBox(height: 6), 
        Text(
          'تخصيص الصلاحيات المتقدمة',
          style: TextStyle(
            fontSize: context.subHeaderSize, // 📉 Reduced from 18
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6), 
        Container(
          padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16/24
          decoration: BoxDecoration(
            color: const Color(0xFF9A66FF).withValues(alpha: 0.04), // Purple tint
            borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
            border: Border.all(color: const Color(0xFF9A66FF).withValues(alpha: 0.1)),
          ),
          child: Text(
            'يتم الآن تخصيص الصلاحيات بشكل مستقل لكل مستخدم. انقر على أيقونة 🔑 بجانب اسم المستخدم لفتح مصفوفة الصلاحيات الخاصة به وإدارة وصوله للوحدات.',
            style: TextStyle(color: context.mutedText, height: 1.5, fontSize: context.bodySize - 2),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionToggle(
    BuildContext context,
    String feature,
    bool isGranted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // 📉 Reduced
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                size: context.iconSize - 10, // 📉 Reduced
                color: isGranted ? const Color(0xFF9800E5) : context.mutedText.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                feature,
                style: TextStyle(
                  color: isGranted ? context.textColor : context.mutedText,
                  fontSize: context.bodySize - 3, // 📉 Reduced
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _permissions[feature] = !isGranted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, // 📉 Reduced
              height: 12, // 📉 Reduced
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFF9800E5) : context.cardBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4), // 📉 Sharper
              ),
              alignment: isGranted ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 9, // 📉 Reduced
                height: 9, // 📉 Reduced
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesTab(BuildContext context, bool isMobile) {
    return Column(
      key: const ValueKey("branches"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('users.branch_management'),
              style: TextStyle(
                fontSize: context.subHeaderSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: _showAddBranchDialog,
              child: _buildCapsuleButton(
                context,
                icon: Icons.add,
                label: tr('users.new_branch_btn'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_branches.isEmpty 
          ? [const Center(child: Text("لا توجد فروع مسجلة"))]
          : _branches.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildBranchCard(
                context,
                b,
                isMobile,
              ),
            )).toList()),
      ],
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'employee';
    String? selectedBranch;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Icon(Icons.person_add, color: primaryOrange, size: 24),
            const SizedBox(width: 8),
            const Text('إضافة مستخدم جديد'),
          ]),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('البيانات الأساسية', style: TextStyle(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل *',
                      hintText: 'مثال: أحمد محمد علي',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال',
                      hintText: '05xxxxxxxx',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'user@company.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Text('بيانات الدخول', style: TextStyle(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم *',
                      hintText: 'مثال: ahmed.m',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور *',
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Text('الوظيفة والفرع', style: TextStyle(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'الوظيفة *',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('مدير عام (صلاحيات كاملة)')),
                      DropdownMenuItem(value: 'branch_manager', child: Text('مدير فرع')),
                      DropdownMenuItem(value: 'accountant', child: Text('محاسب')),
                      DropdownMenuItem(value: 'chief_accountant', child: Text('رئيس حسابات')),
                      DropdownMenuItem(value: 'cashier', child: Text('كاشير')),
                      DropdownMenuItem(value: 'sales', child: Text('مندوب مبيعات')),
                      DropdownMenuItem(value: 'sales_manager', child: Text('مدير مبيعات')),
                      DropdownMenuItem(value: 'purchasing', child: Text('مسؤول مشتريات')),
                      DropdownMenuItem(value: 'warehouse', child: Text('أمين مستودع')),
                      DropdownMenuItem(value: 'hr', child: Text('موارد بشرية')),
                      DropdownMenuItem(value: 'auditor', child: Text('مراجع/مدقق')),
                      DropdownMenuItem(value: 'data_entry', child: Text('مدخل بيانات')),
                      DropdownMenuItem(value: 'viewer', child: Text('مشاهد فقط (بدون تعديل)')),
                      DropdownMenuItem(value: 'employee', child: Text('موظف عادي')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRole = v ?? 'employee'),
                  ),
                  const SizedBox(height: 12),
                  if (_branches.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedBranch,
                      decoration: const InputDecoration(
                        labelText: 'الفرع',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('-- جميع الفروع --')),
                        ..._branches.map((b) => DropdownMenuItem(
                          value: b['id']?.toString(),
                          child: Text(b['name']?.toString() ?? ''),
                        )),
                      ],
                      onChanged: (v) => setDialogState(() => selectedBranch = v),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                // Validation
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ الاسم الكامل مطلوب'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (usernameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ اسم المستخدم مطلوب'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (passwordCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ كلمة المرور مطلوبة'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  await _db.saveSystemUser({
                    'id': 'U_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameCtrl.text.trim(),
                    'username': usernameCtrl.text.trim(),
                    'password_hash': sha256.convert(utf8.encode(passwordCtrl.text.trim())).toString(),
                    'email': emailCtrl.text.trim(),
                    'role': selectedRole,
                    'is_active': 1,
                  });
                  if (mounted) Navigator.pop(c);
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ تمت إضافة "${nameCtrl.text.trim()}" بنجاح كـ ${_getRoleLabel(selectedRole)}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (mounted) {
                    final errorMsg = e.toString().contains('UNIQUE') 
                        ? '❌ اسم المستخدم "${usernameCtrl.text.trim()}" مستخدم بالفعل. اختر اسماً آخر.'
                        : '❌ خطأ في الحفظ: $e';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: isSaving 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                  : const Text('حفظ المستخدم', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    const labels = {
      'admin': 'مدير عام',
      'branch_manager': 'مدير فرع',
      'accountant': 'محاسب',
      'chief_accountant': 'رئيس حسابات',
      'cashier': 'كاشير',
      'sales': 'مندوب مبيعات',
      'sales_manager': 'مدير مبيعات',
      'purchasing': 'مسؤول مشتريات',
      'warehouse': 'أمين مستودع',
      'hr': 'موارد بشرية',
      'auditor': 'مراجع',
      'data_entry': 'مدخل بيانات',
      'viewer': 'مشاهد',
      'employee': 'موظف',
    };
    return labels[role] ?? role;
  }

  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Icon(Icons.domain_add, color: primaryOrange, size: 24),
            const SizedBox(width: 8),
            const Text('إضافة فرع جديد'),
          ]),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفرع *',
                    hintText: 'مثال: فرع الرياض - حي العليا',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز الفرع *',
                    hintText: 'مثال: 101 أو RUH',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    hintText: 'مثال: شارع الملك فهد، الرياض',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ اسم الفرع مطلوب'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (codeCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ رمز الفرع مطلوب'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  await _db.saveCostCenter({
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim(),
                  });
                  if (mounted) Navigator.pop(c);
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ تم إضافة فرع "${nameCtrl.text.trim()}" بنجاح'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('❌ خطأ في الحفظ: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                  : const Text('حفظ الفرع', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, Map<String, dynamic> user, bool isMobile) {
    String name = user['name'] ?? 'بدون اسم';
    String role = _getRoleLabel(user['role'] ?? 'employee');
    String email = user['email'] ?? '';
    bool isActive = (user['is_active'] ?? 1) == 1;
    String status = isActive ? tr('common.active') : tr('common.locked');
    Color statusColor = isActive ? const Color(0xFF00F260) : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: context.textColor, size: context.iconSize - 6),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textColor),
                ),
                Text(
                  email,
                  style: TextStyle(color: context.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.badgeSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role,
                style: TextStyle(color: context.mutedText, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.key, color: Colors.orangeAccent, size: 18),
                tooltip: 'تخصيص الصلاحيات',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PermissionsMatrixScreen(
                      userId: user['id'].toString(),
                      userName: user['name'] ?? '',
                    )),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                tooltip: 'تعديل',
                onPressed: () => _showEditUserDialog(user),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                tooltip: 'حذف',
                onPressed: () => _deleteUser(user['id'] ?? ''),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المستخدم؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      await _db.deleteSystemUser(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم حذف المستخدم بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  void _showPermissionMatrixDialog(Map<String, dynamic> user) {
    // World-class Permission Matrix
    final List<String> modules = ['dashboard', 'invoices', 'purchases', 'hr', 'accounting', 'reports', 'inventory'];
    Map<String, Map<String, bool>> currentPerms = {};
    
    if (user['permissions'] != null && user['permissions'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(user['permissions']);
        decoded.forEach((k, v) {
          if (v is Map) currentPerms[k] = Map<String, bool>.from(v);
        });
      } catch (_) {}
    }

    // Ensure all modules exist
    for (var m in modules) {
      currentPerms[m] ??= {'view': false, 'create': false, 'edit': false, 'delete': false, 'approve': false};
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              Expanded(child: Text('صلاحيات: ${user['name']}', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.purple.withValues(alpha: 0.1),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('رؤية', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                        Expanded(child: Text('إضافة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                        Expanded(child: Text('تعديل', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                        Expanded(child: Text('حذف', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                        Expanded(child: Text('اعتماد', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...modules.map((m) {
                    final perms = currentPerms[m]!;
                    return Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(tr('hub.tiles.$m'))),
                          Expanded(child: Checkbox(value: perms['view'], onChanged: (v) => setDialogState(() => perms['view'] = v ?? false))),
                          Expanded(child: Checkbox(value: perms['create'], onChanged: (v) => setDialogState(() => perms['create'] = v ?? false))),
                          Expanded(child: Checkbox(value: perms['edit'], onChanged: (v) => setDialogState(() => perms['edit'] = v ?? false))),
                          Expanded(child: Checkbox(value: perms['delete'], onChanged: (v) => setDialogState(() => perms['delete'] = v ?? false))),
                          Expanded(child: Checkbox(value: perms['approve'], onChanged: (v) => setDialogState(() => perms['approve'] = v ?? false))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final jsonStr = jsonEncode(currentPerms);
                await _db.updateSystemUser(user['id'], {'permissions': jsonStr});
                if (mounted) Navigator.pop(c);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ تم تحديث الصلاحيات بنجاح'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              child: const Text('حفظ الصلاحيات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, Map<String, dynamic> branch, bool isMobile) {
    String name = branch['name'] ?? 'فرع جديد';
    String code = branch['code'] ?? '---';
    String status = tr('common.online');
    Color statusColor = Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.sheetGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_city,
                  color: primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 10, color: context.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        "الرمز: $code",
                        style: TextStyle(
                          color: context.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 16),
                onPressed: () => _showEditBranchDialog(branch),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                onPressed: () => _deleteBranch(branch['id'] ?? ''),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? 'viewer';
    String? selectedBranchId = user['branch_id']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تعديل بيانات المستخدم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('مدير نظام')),
                    DropdownMenuItem(value: 'manager', child: Text('مدير')),
                    DropdownMenuItem(value: 'accountant', child: Text('محاسب')),
                    DropdownMenuItem(value: 'hrManager', child: Text('مدير HR')),
                    DropdownMenuItem(value: 'employee', child: Text('موظف')),
                    DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
                  ],
                  onChanged: (v) => setState(() => selectedRole = v!),
                  decoration: const InputDecoration(labelText: 'الدور (Role)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: selectedBranchId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل / غير محدد')),
                    ..._branches.map((b) => DropdownMenuItem(
                      value: b['id'].toString(),
                      child: Text(b['name'] ?? ''),
                    )),
                  ],
                  onChanged: (v) => setState(() => selectedBranchId = v),
                  decoration: const InputDecoration(labelText: 'الفرع'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                await _db.updateSystemUser(user['id'], {
                  'name': nameController.text,
                  'email': emailController.text,
                  'role': selectedRole,
                  'branch_id': selectedBranchId,
                });
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBranchDialog(Map<String, dynamic> branch) {
    final nameController = TextEditingController(text: branch['name'] ?? '');
    final codeController = TextEditingController(text: branch['code'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات الفرع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الفرع'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'رمز الفرع'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await _db.updateCostCenter(branch['id'], {
                'name': nameController.text,
                'code': codeController.text,
              });
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBranch(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الفرع؟ لن يتم حذف العمليات المرتبطة به ولكن سيتم إخفاءه من القوائم.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      await _db.deleteCostCenter(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم حذف الفرع بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  Widget _buildCapsuleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 100
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 📉 Reduced blur
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? primaryOrange : primaryOrange.withValues(alpha: 0.05),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(100), 
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16, 
                color: isPrimary ? Colors.black87 : context.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.black87 : context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
