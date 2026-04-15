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
  IndustryType _selectedIndustry = IndustryType.general;
  String _selectedCountry = "saudi";
  String _selectedCurrency = "sar";
  double _taxRate = 15.0;
  bool _isLoading = false;
  
  XFile? _logoFile;
  final ImagePicker _picker = ImagePicker();

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
                constraints: const BoxConstraints(maxWidth: 600),
                padding: EdgeInsets.all(context.cardPadding * 2),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(context.cardRadius * 2),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    _buildLabel(tr('onboarding.org_name_label')),
                    _buildTextField(_nameController, tr('onboarding.org_name_hint')),
                    const SizedBox(height: 16),

                    _buildLabel(tr('onboarding.activity_type_label')),
                    _buildIndustryGrid(),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.country_label')),
                              _buildDropdown<String>(
                                value: _selectedCountry,
                                items: ["egypt", "saudi", "kuwait", "uae", "jordan"],
                                formatText: (v) => tr('onboarding.countries.$v'),
                                onChanged: (v) => setState(() => _selectedCountry = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('onboarding.currency_label')),
                              _buildDropdown<String>(
                                value: _selectedCurrency,
                                items: ["egp", "sar", "aed", "kwd", "usd"],
                                formatText: (v) => tr('onboarding.currencies.$v'),
                                onChanged: (v) => setState(() => _selectedCurrency = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel(tr('onboarding.tax_rate_label')),
                    _buildDropdown<double>(
                      value: _taxRate,
                      items: [0.0, 5.0, 10.0, 15.0],
                      formatText: (v) => "$v%",
                      onChanged: (v) => setState(() => _taxRate = v!),
                    ),
                    const SizedBox(height: 32),

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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('onboarding.setup_title'), 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textColor)
              ),
              const SizedBox(height: 4),
              Text(
                tr('onboarding.setup_subtitle'), 
                style: TextStyle(color: context.mutedText, fontSize: 13)
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _pickLogo,
          child: Hero(
            tag: 'org_logo',
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.cardBorder, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)
                ]
              ),
              child: _logoFile == null 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: primaryOrange, size: 24),
                      const SizedBox(height: 4),
                      Text(tr('onboarding.logo_label'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: kIsWeb 
                      ? Image.network(_logoFile!.path, fit: BoxFit.cover)
                      : Image.file(File(_logoFile!.path), fit: BoxFit.cover),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndustryGrid() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: context.bgSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
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
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
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
    padding: const EdgeInsets.only(bottom: 8.0, left: 4),
    child: Text(text, style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField(TextEditingController controller, String hint) => Container(
    decoration: BoxDecoration(
      color: context.bgSurface.withValues(alpha: 0.5), 
      borderRadius: BorderRadius.circular(context.cardRadius), 
      border: Border.all(color: context.cardBorder)
    ),
    child: TextField(
      controller: controller,
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, 
        hintStyle: TextStyle(color: context.mutedText, fontSize: 14), 
        border: InputBorder.none, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
      ),
    ),
  );

  Widget _buildDropdown<T>({required T value, required List<T> items, required ValueChanged<T?> onChanged, String Function(T)? formatText}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.bgSurface.withValues(alpha: 0.5), 
      borderRadius: BorderRadius.circular(context.cardRadius), 
      border: Border.all(color: context.cardBorder)
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        dropdownColor: context.cardSurface,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryOrange),
        isExpanded: true,
        style: TextStyle(color: context.textColor, fontSize: 14),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(formatText != null ? formatText(e) : e.toString()))).toList(),
        onChanged: onChanged,
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
      
      // 1. Set Company & Industry Metadata
      await db.setCurrentCompany(companyId, _selectedIndustry.name);
      await db.setCompanySettings(
        taxRate: _taxRate, 
        currency: _selectedCurrency, 
        country: _selectedCountry,
        logoPath: _logoFile?.path,
      );

      // 2. Initialize Industry-Specific COA (Senior Level Logic)
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryOrange.withValues(alpha: 0.2) 
              : context.cardSurface,
          borderRadius: BorderRadius.circular(context.cardRadius),
          border: Border.all(
            color: isSelected ? primaryOrange : context.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: primaryOrange.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.cardRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForIndustry(industry),
                  color: isSelected ? primaryOrange : context.mutedText,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    tr('onboarding.industries.${industry.name}'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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
