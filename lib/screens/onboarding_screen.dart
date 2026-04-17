import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/industry_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
  bool _isLoading = false;
  
  XFile? _logoFile;
  final ImagePicker _picker = ImagePicker();

  static const Map<String, String> _countryPrefixes = {
    "saudi": "+966", "egypt": "+20", "uae": "+971", "kuwait": "+965",
    "jordan": "+962", "oman": "+968", "qatar": "+974", "bahrain": "+973",
    "iraq": "+964", "lebanon": "+961", "morocco": "+212", "tunisia": "+216",
    "algeria": "+213", "turkey": "+90", "usa": "+1", "uk": "+44",
  };

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoFile = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSurface,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.sectionPadding),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 750),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(context.cardRadius * 1.5),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: context.bgSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.cardBorder),
                            ),
                            child: _logoFile != null 
                              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_logoFile!.path), fit: BoxFit.cover))
                              : Icon(Icons.add_a_photo_outlined, color: context.mutedText, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.org_name_label')),
                              _buildTextField(_nameController, tr('onboarding.org_name_hint'), icon: Icons.business_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.phone_label')),
                              _buildTextField(
                                _phoneController, 
                                "5xxxxxxx", 
                                icon: Icons.phone_outlined,
                                prefix: _countryPrefixes[_selectedCountry] ?? "+",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.email_label')),
                              _buildTextField(_emailController, "info@company.com", icon: Icons.email_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    _buildLabel(tr('onboarding.activity_type_label')),
                    _buildIndustryGrid(),
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.cr_label')),
                              _buildTextField(_crController, "1010xxxxxx"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.vat_label')),
                              _buildTextField(_vatController, "300xxxxxxxx"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.tax_rate_label')),
                              _buildDropdown<double>(
                                value: _taxRate,
                                items: [0.0, 5.0, 10.0, 15.0],
                                formatText: (v) => "$v%",
                                onChanged: (v) => setState(() => _taxRate = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    _buildLabel(tr('onboarding.address_label')),
                    _buildTextField(_addressController, "City, Street, Building", icon: Icons.location_on_outlined),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildLabel(tr('onboarding.country_label')),
                                _buildDropdown<String>(
                                  value: _selectedCountry,
                                  items: [
                                    "egypt", "saudi", "kuwait", "uae", "jordan", "oman", "qatar", "bahrain", 
                                    "iraq", "lebanon", "morocco", "tunisia", "algeria", "turkey", "usa", "uk"
                                  ],
                                  formatText: (v) => tr('onboarding.countries.$v'),
                                  onChanged: (v) => setState(() => _selectedCountry = v!),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildLabel(tr('onboarding.currency_label')),
                                _buildDropdown<String>(
                                  value: _selectedCurrency,
                                  items: ["egp", "sar", "aed", "kwd", "omr", "qar", "bhd", "usd", "eur", "gbp", "jod", "try"],
                                  formatText: (v) => tr('onboarding.currencies.$v'),
                                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('onboarding.setup_title'), 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)
        ),
        Text(
          tr('onboarding.setup_subtitle'), 
          style: TextStyle(color: context.mutedText, fontSize: 10)
        ),
      ],
    );
  }

  Widget _buildIndustryGrid() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: context.bgSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 11,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
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

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(context.cardRadius),
        boxShadow: [
          BoxShadow(
            color: sunsetEnd.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAndContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              tr('onboarding.save_and_continue'), 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
            ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4.0, left: 4),
    child: Text(text, style: TextStyle(color: context.textColor, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, String? prefix}) => Container(
    decoration: BoxDecoration(
      color: context.bgSurface.withValues(alpha: 0.4), 
      borderRadius: BorderRadius.circular(context.cardRadius), 
      border: Border.all(color: context.cardBorder)
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(context.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: TextField(
          controller: controller,
          style: TextStyle(color: context.textColor, fontSize: 12),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18, color: context.mutedText) : null,
            prefixText: prefix != null ? "$prefix " : null,
            prefixStyle: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
            hintText: hint, 
            hintStyle: TextStyle(color: context.mutedText, fontSize: 13), 
            border: InputBorder.none, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          ),
        ),
      ),
    ),
  );

  Widget _buildDropdown<T>({required T value, required List<T> items, required ValueChanged<T?> onChanged, String Function(T)? formatText}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.bgSurface.withValues(alpha: 0.4), 
      borderRadius: BorderRadius.circular(context.cardRadius), 
      border: Border.all(color: context.cardBorder)
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(context.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            dropdownColor: context.bgSurface.withValues(alpha: 0.95),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryOrange, size: 16),
            isExpanded: true,
            style: TextStyle(color: context.textColor, fontSize: 12),
            items: items.map((e) => DropdownMenuItem(
              value: e, 
              child: Text(
                formatText != null ? formatText(e) : e.toString(),
                style: TextStyle(color: context.textColor, fontSize: 12),
              )
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('onboarding.validation_error')),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseHelper();
      final companyId = "COMP_${DateTime.now().millisecondsSinceEpoch}";
      
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

      await db.seedIndustryAccounts(_selectedIndustry);
      
      widget.onComplete();
    } catch (e) {
      String errorMsg = tr('onboarding.save_error');
      if (e.toString().contains('TRANSACTIONS_EXIST')) {
        errorMsg = "لا يمكن تغيير القطاع لوجود حركات مالية مسجلة";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$errorMsg: $e"),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      setState(() => _isLoading = false);
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
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? primaryOrange : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndustry(industry),
              size: 14,
              color: isSelected ? primaryOrange : context.mutedText,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                tr('onboarding.industries.${industry.name}'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 6,
                  height: 0.9,
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
