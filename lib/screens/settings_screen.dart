import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'onboarding_modules_screen.dart';
import '../services/tax_engine.dart';
import '../services/currency_service.dart';
import '../services/email_service.dart';
import '../widgets/splash_screen_widget.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _twoFactorEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = false;

  String _selectedLanguage = "العربية";
  String _selectedCurrency = "sar";
  String _selectedCountry = "saudi";
  double _taxRate = 15.0;
  
  String? _logoPath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final contextData = await DatabaseHelper().getCurrentCompanyContext();
    setState(() {
      _selectedCurrency = contextData['currency'] ?? "sar";
      _selectedCountry = contextData['country'] ?? "saudi";
      _taxRate = contextData['tax_rate'] ?? 15.0;
      _logoPath = contextData['logo_path'];
      _nameController.text = contextData['name'] ?? "";
      _vatController.text = contextData['vat_number'] ?? "";
      _addressController.text = contextData['address'] ?? "";
      _taxController.text = _taxRate.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final double? parsedTax = double.tryParse(_taxController.text);
    if (parsedTax != null) _taxRate = parsedTax;
    
    await DatabaseHelper().setCompanySettings(
      taxRate: _taxRate, 
      currency: _selectedCurrency, 
      country: _selectedCountry,
      vatNumber: _vatController.text,
      address: _addressController.text,
      logoPath: _logoPath,
    );
    // Also update company name if changed
    if (_nameController.text.isNotEmpty) {
      await DatabaseHelper().setCurrentCompany(_nameController.text, "General");
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoPath = image.path);
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryOrange));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('settings_module.title'),
            style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1),
          ),
          const SizedBox(height: 4),
          Text(
            tr('settings_module.subtitle'),
            style: TextStyle(
              fontSize: context.headerSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingsGroup(context, tr('settings_module.group_company'), [
             Padding(
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                children: [
                   Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(context.cardRadius),
                              image: _logoPath != null ? DecorationImage(image: FileImage(File(_logoPath!)), fit: BoxFit.contain) : null,
                            ),
                            child: _logoPath == null ? Icon(Icons.add_a_photo_outlined, color: primaryOrange, size: context.iconSize + 4) : null,
                          ),
                        ),
                        if (_logoPath != null)
                          Positioned(
                            bottom: -5, right: -5,
                            child: IconButton(
                              onPressed: _pickLogo,
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 12, color: Colors.black87),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(tr('settings_module.logo_label'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                  const SizedBox(height: 16),
                  _buildTextField(tr('settings_module.company_name'), _nameController, Icons.business_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(tr('settings_module.vat_number'), _vatController, Icons.numbers, isNumeric: true),
                  const SizedBox(height: 12),
                  _buildTextField(tr('settings_module.address'), _addressController, Icons.location_on_outlined),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 12),

          _buildSettingsGroup(context, tr('settings_module.group_system'), [
            _buildSettingsItem(
              context,
              tr('settings_module.country'),
              Icons.public,
              trailing: DropdownButton<String>(
                value: _selectedCountry,
                dropdownColor: context.cardSurface,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: primaryOrange, size: context.iconSize),
                style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.bodySize),
                items: [
                  "egypt", "saudi", "kuwait", "uae", "jordan", "oman", "qatar", "bahrain", 
                  "iraq", "lebanon", "morocco", "tunisia", "algeria", "turkey", "usa", "uk"
                ].map((c) => DropdownMenuItem(value: c, child: Text(tr('onboarding.countries.$c')))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final taxConfig = TaxEngine.getConfigForCountry(v);
                  setState(() {
                    _selectedCountry = v;
                    // Standardized keys mapping
                    final String key = v.toLowerCase();
                    if (key == "saudi") _selectedCurrency = "sar";
                    else if (key == "uae") _selectedCurrency = "aed";
                    else if (key == "egypt") _selectedCurrency = "egp";
                    else if (key == "kuwait") _selectedCurrency = "kwd";
                    else if (key == "turkey") _selectedCurrency = "try";
                    else if (key == "usa") _selectedCurrency = "usd";
                    else if (key == "uk") _selectedCurrency = "gbp";
                    else if (key == "jordan") _selectedCurrency = "jod";
                    else if (key == "oman") _selectedCurrency = "omr";
                    else if (key == "qatar") _selectedCurrency = "qar";
                    else if (key == "bahrain") _selectedCurrency = "bhd";
                    
                    _taxRate = taxConfig.standardRate;
                    _taxController.text = _taxRate.toString();
                  });
                  _saveSettings();
                },
              ),
            ),
            _buildSettingsItem(
              context,
              tr('settings_module.currency'),
              Icons.payments_outlined,
              trailing: DropdownButton<String>(
                value: _selectedCurrency,
                dropdownColor: context.cardSurface,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: primaryOrange),
                style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
                items: CurrencyService.currencySymbols.keys.map((code) => 
                  DropdownMenuItem(value: code.toLowerCase(), child: Text(code))
                ).toList(),
                onChanged: (v) {
                  setState(() => _selectedCurrency = v!);
                  _saveSettings();
                },
              ),
            ),
            _buildSettingsItem(
              context,
              tr('settings_module.tax_rate'),
              Icons.percent_rounded,
              trailing: SizedBox(
                width: 60,
                child: TextField(
                  controller: _taxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    suffixText: "%",
                    suffixStyle: TextStyle(color: primaryOrange),
                  ),
                  onSubmitted: (v) => _saveSettings(),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsGroup(context, tr('settings_module.group_profile'), [
            _buildSettingsItem(
              context,
              tr('settings_module.change_password'),
              Icons.lock_outline,
              onTap: () => _showChangePasswordDialog(),
            ),
            _buildSettingsItem(
              context,
              tr('settings_module.two_factor'),
              Icons.security_outlined,
              trailing: Switch(
                value: _twoFactorEnabled,
                onChanged: (v) => setState(() => _twoFactorEnabled = v),
                activeColor: primaryOrange,
                padding: EdgeInsets.zero,
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsGroup(context, tr('settings_module.group_notifications'), [
            _buildSettingsItem(
              context,
              tr('settings_module.email_notif'),
              Icons.mail_outline,
              trailing: Switch(
                value: _emailNotifications,
                onChanged: (v) => setState(() => _emailNotifications = v),
                activeColor: primaryOrange,
                padding: EdgeInsets.zero,
              ),
            ),
            _buildSettingsItem(
              context,
              tr('settings_module.push_notif'),
              Icons.notifications_none,
              trailing: Switch(
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
                activeColor: primaryOrange,
                padding: EdgeInsets.zero,
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsGroup(context, tr('settings_module.group_general'), [
             _buildSettingsItem(
               context, 
               tr('settings_module.email_setup'), 
               Icons.mark_email_read_outlined,
               onTap: () => _showSmtpConfigDialog(),
             ),
             _buildSettingsItem(
               context, 
               tr('settings_module.onboarding_restart'), 
               Icons.refresh_rounded,
               onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => OnboardingModulesScreen(
                       onCompleted: () => Navigator.pop(context), 
                     ),
                   ),
                 );
               },
             ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsGroup(context, tr('settings_module.group_ui'), [
             ValueListenableBuilder<bool>(
               valueListenable: perfShowBlur,
               builder: (context, value, _) => _buildSettingsItem(
                 context,
                 tr('settings_module.glass_effect'),
                 Icons.blur_on_rounded,
                 trailing: Switch(
                   value: value,
                   onChanged: (v) => perfShowBlur.value = v,
                   activeColor: primaryOrange,
                   padding: EdgeInsets.zero,
                 ),
               ),
             ),
             ValueListenableBuilder<bool>(
               valueListenable: perfShowShadows,
               builder: (context, value, _) => _buildSettingsItem(
                 context,
                 tr('settings_module.shadows'),
                 Icons.wb_sunny_outlined,
                 trailing: Switch(
                   value: value,
                   onChanged: (v) => perfShowShadows.value = v,
                   activeColor: primaryOrange,
                   padding: EdgeInsets.zero,
                 ),
               ),
             ),
             ValueListenableBuilder<bool>(
               valueListenable: perfShowAnimations,
               builder: (context, value, _) => _buildSettingsItem(
                 context,
                 tr('settings_module.animations'),
                 Icons.auto_awesome_motion_rounded,
                 trailing: Switch(
                   value: value,
                   onChanged: (v) => perfShowAnimations.value = v,
                   activeColor: primaryOrange,
                   padding: EdgeInsets.zero,
                 ),
               ),
             ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsGroup(context, "حول حساباتي ERP", [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Center(
                     child: Image.asset('assets/image/logo icon.PNG', height: 60),
                   ),
                   const SizedBox(height: 16),
                   _buildAboutRow("الإصدار", "1.0.0"),
                   _buildAboutRow("المطور", "basss"),
                   _buildAboutRow("الرخصة", "تجارية"),
                   _buildAboutRow("الموقع", "www.hisabati.com"),
                   _buildAboutRow("الدعم الفني", "bassemsabri@outlook.sa"),
                   const SizedBox(height: 16),
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton.icon(
                       style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 12),
                         side: BorderSide(color: primaryOrange.withValues(alpha: 0.3)),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       icon: const Icon(Icons.sync, color: primaryOrange, size: 18),
                       label: const Text("التحقق من التحديثات", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
                       onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("التطبيق محدث إلى آخر إصدار (1.0.0)"), backgroundColor: Colors.green),
                         );
                       },
                     ),
                   ),
                 ],
               ),
             ),
          ]),

          const SizedBox(height: 24),
          _buildSettingsGroup(context, "إدارة البيانات", [
             ListTile(
               dense: true,
               leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
               title: const Text("إعادة ضبط المصنع", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
               subtitle: const Text("مسح كافة العمليات والفواتير والبيانات التجريبية للبدء من جديد", style: TextStyle(fontSize: 11, color: Colors.white38)),
               onTap: () => _showFactoryResetDialog(),
             ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Text(tr('settings_module.logout_confirm.title'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      tr('settings_module.logout_confirm.content'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(tr('settings_module.logout_confirm.cancel'), style: const TextStyle(color: Colors.white54)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(tr('settings_module.logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await AuthService().signOut();
                  widget.onLogout();
                }
              },
              icon: const Icon(Icons.logout, size: 20),
              label: Text(
                tr('settings_module.logout'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: (_) => _saveSettings(),
      style: TextStyle(color: context.textColor, fontSize: context.bodySize),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: context.mutedText, fontSize: context.bodySize),
        prefixIcon: Icon(icon, color: primaryOrange, size: context.iconSize),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.cardRadius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.cardRadius), borderSide: const BorderSide(color: primaryOrange, width: 1)),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.subHeaderSize,
              color: context.textColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardSurface,
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(context.cardRadius),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: primaryOrange, size: context.iconSize),
      title: Text(title, style: TextStyle(fontSize: context.bodySize)),
      trailing:
          trailing ??
          Icon(context.locale.languageCode == 'ar' ? Icons.chevron_left : Icons.chevron_right, color: Colors.white24, size: context.iconSize),
      onTap: onTap ?? () {},
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryOrange.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: primaryOrange),
            const SizedBox(width: 12),
            Text(tr('settings_module.change_password'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('settings_module.password_dialog.current_pass'),
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.lock, color: primaryOrange, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('settings_module.password_dialog.new_pass'),
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.lock_open, color: primaryOrange, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('settings_module.password_dialog.confirm_pass'),
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.check_circle_outline, color: primaryOrange, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('settings_module.password_dialog.cancel_btn'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (newPassCtrl.text.isEmpty || newPassCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('settings_module.password_dialog.error_min_length')), backgroundColor: Colors.redAccent),
                );
                return;
              }
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('settings_module.password_dialog.error_mismatch')), backgroundColor: Colors.redAccent),
                );
                return;
              }
              try {
                await AuthService().updatePasswordAndClearResetFlag(newPassCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('settings_module.password_dialog.success')), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: Text(tr('settings_module.password_dialog.change_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSmtpConfigDialog() async {
    final config = await EmailService().getSmtpConfig();
    final hostCtrl = TextEditingController(text: config['host']);
    final portCtrl = TextEditingController(text: config['port']);
    final emailCtrl = TextEditingController(text: config['email']);
    final passCtrl = TextEditingController(text: config['password']);
    final nameCtrl = TextEditingController(text: config['sender_name']);
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: primaryOrange.withValues(alpha: 0.3))),
          title: Row(
            children: [
              const Icon(Icons.email_outlined, color: primaryOrange),
              const SizedBox(width: 12),
              const Text("إعدادات البريد (SMTP)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("استخدم 'كلمة مرور التطبيق' من جوجل لإرسال الإيميلات بنجاح.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                _buildDialogField("اسم المرسل (باسم شركتك)", nameCtrl, Icons.business_outlined),
                const SizedBox(height: 12),
                _buildDialogField("خادم SMTP (Host)", hostCtrl, Icons.dns_outlined),
                const SizedBox(height: 12),
                _buildDialogField("المنفذ (Port)", portCtrl, Icons.numbers, isNumeric: true),
                const SizedBox(height: 12),
                _buildDialogField("البريد الإلكتروني", emailCtrl, Icons.email),
                const SizedBox(height: 12),
                _buildDialogField("كلمة مرور التطبيق", passCtrl, Icons.vpn_key_outlined, isPass: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E24),
                    title: const Text("إعادة ضبط الإعدادات", style: TextStyle(color: Colors.white)),
                    content: const Text("هل أنت متأكد من رغبتك في حذف كافة الإعدادات والعودة للوضع الافتراضي؟"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text("إلغاء")),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, true), 
                        child: const Text("نعم، إعادة ضبط", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await EmailService().resetSmtpConfig();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت إعادة ضبط إعدادات البريد بنجاح")));
                  }
                }
              },
              child: const Text("إعادة ضبط", style: TextStyle(color: Colors.redAccent)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: testing ? null : () async {
                setDialogState(() => testing = true);
                final res = await EmailService().testSmtpConnection(
                  host: hostCtrl.text,
                  port: portCtrl.text,
                  email: emailCtrl.text,
                  password: passCtrl.text,
                );
                
                if (res['success']) {
                  await EmailService().saveSmtpConfig(
                    hostCtrl.text, 
                    portCtrl.text, 
                    emailCtrl.text, 
                    passCtrl.text,
                    senderName: nameCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحقق وحفظ الإعدادات بنجاح!"), backgroundColor: Colors.green));
                  }
                } else {
                  setDialogState(() => testing = false);
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (errorCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A20),
                        title: const Text("فشل في إعداد البريد", style: TextStyle(color: Colors.redAccent)),
                        content: Text(res['error'], style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errorCtx),
                            child: const Text("حسناً", style: TextStyle(color: primaryOrange)),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: testing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                : const Text("حفظ واختبار", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, IconData icon, {bool isNumeric = false, bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: primaryOrange, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _showFactoryResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text("تنبيه خطر: مسح البيانات", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "سيؤدي هذا الإجراء إلى مسح كافة الفواتير، العمليات المالية، الموظفين، والمستندات المسجلة نهائياً. \n\nهل أنت متأكد من رغبتك في البدء ببيانات جديدة تماماً؟",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await DatabaseHelper().factoryReset();
                // 🚀 Restart the app flow to onboarding
                if (mounted) {
                   Navigator.of(context).pushAndRemoveUntil(
                     MaterialPageRoute(builder: (context) => const SplashScreenWidget()), 
                     (route) => false
                   );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء المسح: $e"), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text("نعم، امسح كل شيء", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
