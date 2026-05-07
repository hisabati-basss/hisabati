import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/industry_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _slugController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _crController = TextEditingController();
  final _vatController = TextEditingController();
  final _addressController = TextEditingController();

  IndustryType _selectedIndustry = IndustryType.general;
  String _selectedCountry = "saudi";
  String _selectedCurrency = "sar";
  double _taxRate = 15.0;
  
  XFile? _logoFile;
  final ImagePicker _picker = ImagePicker();

  // Validation Errors
  final Map<String, String?> _errors = {};

  late AnimationController _animController;

  static const Map<String, String> _countryPrefixes = {
    "saudi": "+966", "egypt": "+20", "uae": "+971", "kuwait": "+965",
    "jordan": "+962", "oman": "+968", "qatar": "+974", "bahrain": "+973",
    "iraq": "+964", "lebanon": "+961", "morocco": "+212", "tunisia": "+216",
    "algeria": "+213", "turkey": "+90", "usa": "+1", "uk": "+44",
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _slugController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _crController.dispose();
    _vatController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoFile = image);
    }
  }

  // --- Validations ---
  bool _validateStep1() {
    _errors.clear();
    final name = _nameController.text.trim();
    final slug = _slugController.text.trim();

    if (name.isEmpty || name.length < 3) {
      _errors['name'] = 'اسم المنشأة يجب أن يكون 3 أحرف على الأقل';
    }
    if (slug.isNotEmpty && !RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(slug)) {
      _errors['slug'] = 'رمز الشركة يجب أن يحتوي على أحرف إنجليزية وأرقام وشرطات فقط';
    }
    setState(() {});
    return _errors.isEmpty;
  }

  bool _validateStep2() {
    _errors.clear();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    if (phone.isEmpty) {
      _errors['phone'] = 'رقم الهاتف مطلوب';
    } else {
      final phoneClean = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
      if (phoneClean.length < 8 || phoneClean.length > 15 || !RegExp(r'^[0-9]+$').hasMatch(phoneClean)) {
        _errors['phone'] = 'رقم الهاتف غير صالح (8-15 رقم)';
      }
    }

    if (email.isEmpty) {
      _errors['email'] = 'البريد الإلكتروني مطلوب';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _errors['email'] = 'البريد الإلكتروني غير صالح';
    }

    if (address.isEmpty) {
      _errors['address'] = 'العنوان التفصيلي مطلوب';
    }

    setState(() {});
    return _errors.isEmpty;
  }

  bool _validateStep3() {
    _errors.clear();
    final cr = _crController.text.trim();
    final vat = _vatController.text.trim();

    if (cr.isNotEmpty && (!RegExp(r'^[0-9]+$').hasMatch(cr) || cr.length < 5)) {
      _errors['cr'] = 'رقم السجل التجاري يجب أن يكون أرقاماً فقط (5 أرقام على الأقل)';
    }

    if (vat.isNotEmpty && (!RegExp(r'^[0-9]+$').hasMatch(vat) || vat.length < 5)) {
      _errors['vat'] = 'الرقم الضريبي يجب أن يكون أرقاماً فقط (5 أرقام على الأقل)';
    }

    setState(() {});
    return _errors.isEmpty;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _animController.reset();
        _animController.forward();
      });
    } else {
      _saveAndContinue();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animController.reset();
        _animController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSurface,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.sectionPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, spreadRadius: -10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStepper(),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _animController,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)),
                    child: _buildCurrentStep(),
                  ),
                ),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.domain_add, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('onboarding.setup_title'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textColor)),
            const SizedBox(height: 4),
            Text('خطوات بسيطة لإعداد بيئة العمل الخاصة بك بنجاح', style: TextStyle(color: context.mutedText, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper() {
    final steps = ['الملف الشخصي', 'معلومات الاتصال', 'البيانات القانونية'];
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive || isDone ? context.primaryGradient : null,
                  color: isActive || isDone ? null : context.cardSurface,
                  border: isActive || isDone ? null : Border.all(color: context.cardBorder, width: 2),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.white : context.mutedText)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(steps[i], style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? context.textColor : context.mutedText), overflow: TextOverflow.ellipsis)),
              if (i < 2) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: isDone ? primaryOrange : context.cardBorder)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox();
    }
  }

  // --- Step 1: Profile ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Column(
              children: [
                _buildLabel('الشعار (اختياري)'),
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.bgSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder, width: 2),
                    ),
                    child: _logoFile != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_logoFile!.path), fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: context.mutedText, size: 28),
                            const SizedBox(height: 4),
                            Text('رفع', style: TextStyle(fontSize: 10, color: context.mutedText)),
                          ],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Name & Slug
            Expanded(
              child: Column(
                children: [
                  _buildFieldRow(
                    label: 'اسم المنشأة *',
                    controller: _nameController,
                    hint: 'مثال: شركة التقنية الحديثة',
                    icon: Icons.business,
                    error: _errors['name'],
                  ),
                  const SizedBox(height: 16),
                  _buildFieldRow(
                    label: 'الرابط المخصص (Slug) *',
                    controller: _slugController,
                    hint: 'مثال: modern-tech',
                    icon: Icons.link,
                    error: _errors['slug'],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildLabel('مجال العمل الأساسي *'),
        const SizedBox(height: 8),
        _buildIndustryGrid(),
      ],
    );
  }

  // --- Step 2: Contact ---
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildLabel('الدولة *'),
                    _buildDropdown<String>(
                      value: _selectedCountry,
                      items: [
                        "egypt", "saudi", "kuwait", "uae", "jordan", "oman", "qatar", "bahrain", 
                        "iraq", "lebanon", "morocco", "tunisia", "algeria", "turkey", "usa", "uk"
                      ],
                      formatText: (v) => tr('onboarding.countries.$v'),
                      onChanged: (v) {
                        setState(() {
                          _selectedCountry = v!;
                          // Auto set currency
                          if (v == 'egypt') _selectedCurrency = 'egp';
                          if (v == 'saudi') _selectedCurrency = 'sar';
                          if (v == 'uae') _selectedCurrency = 'aed';
                          if (v == 'kuwait') _selectedCurrency = 'kwd';
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFieldRow(
                label: 'رقم الهاتف *',
                controller: _phoneController,
                hint: '5xxxxxxx',
                icon: Icons.phone,
                prefix: _countryPrefixes[_selectedCountry] ?? "+",
                error: _errors['phone'],
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\+\-\s]'))],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildFieldRow(
          label: 'البريد الإلكتروني *',
          controller: _emailController,
          hint: 'info@company.com',
          icon: Icons.email,
          error: _errors['email'],
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _buildFieldRow(
          label: 'العنوان التفصيلي *',
          controller: _addressController,
          hint: 'المدينة، الحي، الشارع، المبنى',
          icon: Icons.location_on,
          error: _errors['address'],
        ),
      ],
    );
  }

  // --- Step 3: Legal ---
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFieldRow(
                label: 'رقم السجل التجاري',
                controller: _crController,
                hint: '1010xxxxxx',
                icon: Icons.verified,
                error: _errors['cr'],
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFieldRow(
                label: 'الرقم الضريبي',
                controller: _vatController,
                hint: '300xxxxxxxx',
                icon: Icons.request_quote,
                error: _errors['vat'],
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildLabel('العملة الأساسية *'),
                    _buildDropdown<String>(
                      value: _selectedCurrency,
                      items: ["egp", "sar", "aed", "kwd", "omr", "qar", "bhd", "usd", "eur", "gbp", "jod", "try"],
                      formatText: (v) => tr('onboarding.currencies.$v'),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('نسبة ضريبة القيمة المضافة *'),
                  _buildDropdown<double>(
                    value: _taxRate,
                    items: [0.0, 5.0, 10.0, 14.0, 15.0],
                    formatText: (v) => "$v%",
                    onChanged: (v) => setState(() => _taxRate = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Footer ---
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.cardBorder))),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('السابق', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: context.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: sunsetEnd.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextStep,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Icon(_currentStep == 2 ? Icons.rocket_launch : Icons.arrow_forward, size: 18),
              label: Text(_currentStep == 2 ? 'تأسيس المنشأة الآن' : 'التالي', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildFieldRow({required String label, required TextEditingController controller, required String hint, required IconData icon, String? prefix, String? error, TextInputType? keyboard, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isError: error != null),
        Container(
          decoration: BoxDecoration(
            color: context.bgSurface.withValues(alpha: 0.4), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: error != null ? Colors.redAccent : context.cardBorder)
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: controller,
                keyboardType: keyboard,
                inputFormatters: formatters,
                style: TextStyle(color: context.textColor, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 18, color: error != null ? Colors.redAccent : context.mutedText),
                  prefixText: prefix != null ? "$prefix " : null,
                  prefixStyle: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: hint, 
                  hintStyle: TextStyle(color: context.mutedText.withOpacity(0.5), fontSize: 13), 
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool isError = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6.0, left: 4, right: 4),
    child: Text(text, style: TextStyle(color: isError ? Colors.redAccent : context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _buildDropdown<T>({required T value, required List<T> items, required ValueChanged<T?> onChanged, String Function(T)? formatText}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    decoration: BoxDecoration(
      color: context.bgSurface.withValues(alpha: 0.4), 
      borderRadius: BorderRadius.circular(12), 
      border: Border.all(color: context.cardBorder)
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            dropdownColor: context.bgSurface.withValues(alpha: 0.95),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryOrange, size: 20),
            isExpanded: true,
            style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold),
            items: items.map((e) => DropdownMenuItem(
              value: e, 
              child: Text(
                formatText != null ? formatText(e) : e.toString(),
                style: TextStyle(color: context.textColor, fontSize: 14),
              )
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  Widget _buildIndustryGrid() {
    return Container(
      height: 140, // Increased height for better visibility
      decoration: BoxDecoration(
        color: context.bgSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100, // Make them wider
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: IndustryType.values.length,
            itemBuilder: (context, index) {
              final industry = IndustryType.values[index];
              final isSelected = _selectedIndustry == industry;
              return _IndustryCard(
                industry: industry,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedIndustry = industry),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseHelper();
      final companyId = "COMP_${DateTime.now().millisecondsSinceEpoch}";
      final slug = _slugController.text.trim().isEmpty ? "comp_${companyId.split('_').last}" : _slugController.text.trim();
      
      await db.setCurrentCompany(companyId, _selectedIndustry.name);
      await db.setCompanySettings(
        companyName: _nameController.text.trim(),
        taxRate: _taxRate, 
        currency: _selectedCurrency, 
        country: _selectedCountry,
        logoPath: _logoFile?.path,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        crNumber: _crController.text.trim(),
        vatNumber: _vatController.text.trim(),
        address: _addressController.text.trim(),
      );

      // 1. Save company to local SQLite
      final database = await db.database;
      await database.insert('companies', {
        'id': companyId,
        'slug': slug,
        'name': _nameController.text.trim(),
        'industry_type': _selectedIndustry.name,
        'currency': _selectedCurrency,
        'country': _selectedCountry,
        'tax_rate': _taxRate,
        'sync_status': 0,
        'updated_at': DateTime.now().toIso8601String(),
        'device_id': 'local',
        'is_deleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Link current user to this company
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId != null) {
        await database.rawUpdate(
          'UPDATE system_users SET company_id = ?, updated_at = ? WHERE id = ?',
          [companyId, DateTime.now().toIso8601String(), currentUserId]
        );
      }

      await db.seedIndustryAccounts(_selectedIndustry, force: true);
      
      widget.onComplete();
    } catch (e) {
      String errorMsg = tr('onboarding.save_error');
      if (e.toString().contains('TRANSACTIONS_EXIST')) {
        errorMsg = "لا يمكن تغيير القطاع لوجود حركات مالية مسجلة";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$errorMsg: $e"),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _IndustryCard extends StatelessWidget {
  final IndustryType industry;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndustryCard({
    required this.industry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withValues(alpha: 0.15) : context.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryOrange : context.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? [BoxShadow(color: primaryOrange.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndustry(industry),
              size: 24,
              color: isSelected ? primaryOrange : context.mutedText,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                tr('onboarding.industries.${industry.name}'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? context.textColor : context.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndustry(IndustryType type) {
    switch (type) {
      case IndustryType.general: return Icons.store_rounded;
      case IndustryType.realEstate: return Icons.home_work_rounded;
      case IndustryType.propertyMgmt: return Icons.apartment_rounded;
      case IndustryType.education: return Icons.school_rounded;
      case IndustryType.trainingCenter: return Icons.model_training_rounded;
      case IndustryType.hospital: return Icons.local_hospital_rounded;
      case IndustryType.clinic: return Icons.medical_services_rounded;
      case IndustryType.pharmacy: return Icons.medication_rounded;
      case IndustryType.agriculture: return Icons.agriculture_rounded;
      case IndustryType.livestock: return Icons.pets_rounded;
      case IndustryType.fruitsVegetables: return Icons.shopping_basket_rounded;
      case IndustryType.farm: return Icons.nature_people_rounded;
      case IndustryType.foodTrading: return Icons.fastfood_rounded;
      case IndustryType.wholesale: return Icons.inventory_2_rounded;
      case IndustryType.restaurant: return Icons.restaurant_rounded;
      case IndustryType.bakery: return Icons.bakery_dining_rounded;
      case IndustryType.perfume: return Icons.face_retouching_natural_rounded;
      case IndustryType.foodFactory: return Icons.factory_rounded;
      case IndustryType.manufacturing: return Icons.precision_manufacturing_rounded;
      case IndustryType.corporate: return Icons.business_center_rounded;
      case IndustryType.construction: return Icons.construction_rounded;
      case IndustryType.retail: return Icons.shopping_bag_rounded;
      case IndustryType.ecommerce: return Icons.language_rounded;
      case IndustryType.warehouse: return Icons.warehouse_rounded;
      case IndustryType.logistics: return Icons.local_shipping_rounded;
      case IndustryType.carRental: return Icons.car_rental_rounded;
      case IndustryType.hospitality: return Icons.hotel_rounded;
    }
  }
}
