import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme_extension.dart';
import '../services/subscription_service.dart';
import '../services/module_config_service.dart';
import '../core/config/module_definitions.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool _showCustomEditor = false;
  final Set<String> _selectedCustomModules = {};

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            primaryOrange.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCirc,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showCustomEditor
                    ? _buildCustomModuleSelector(context)
                    : _buildPricingTiers(context, isMobile),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange.withValues(alpha: 0.2), primaryOrange.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
          ),
          child: Text(
            "باقات ذكية",
            style: TextStyle(
              color: primaryOrange,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "اختر الخطة المثالية لعملك",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Text(
            "نوفر لك مرونة كاملة في اختيار ما يناسب تطلعاتك ونمو مؤسستك",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.mutedText.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingTiers(BuildContext context, bool isMobile) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final tiers = [
      _TierData(
        title: "الأساسية",
        subtitle: "Starter",
        price: "0",
        priceSuffix: "مجاناً للأبد",
        features: ["مستخدم واحد فقط", "المحاسبة الأساسية", "100 فاتورة/شهر"],
        tier: SubscriptionTier.starter,
        color: Colors.blueGrey,
      ),
      _TierData(
        title: "المتقدمة",
        subtitle: "Advanced",
        price: "29",
        priceSuffix: "لكل شهر",
        features: ["حتى 2 مستخدمين", "كل البرامج الرئيسية", "ذكاء اصطناعي أساسي"],
        tier: SubscriptionTier.advanced,
        color: Colors.blue,
      ),
      _TierData(
        title: "المتطورة",
        subtitle: "Pro",
        price: "79",
        priceSuffix: "لكل شهر / مستخدم",
        features: ["حتى 4 مستخدمين", "كافة البرامج والتجارة", "ذكاء اصطناعي متطور"],
        tier: SubscriptionTier.developed,
        isFeatured: true,
        color: primaryOrange,
      ),
      _TierData(
        title: "المؤسسات",
        subtitle: "Enterprise",
        price: "Custom",
        priceSuffix: "حسب اختيارك",
        features: ["مستخدمين غير محدود", "وصول كامل لكل البرامج", "ربط API خارجي"],
        tier: SubscriptionTier.enterprise,
        color: Colors.purple,
        buttonText: "صمم خطتك",
      ),
    ];

    if (isMobile) {
      return Column(
        children: tiers.map((t) => _buildPriceCard(context, t)).toList(),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: tiers.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            return Row(
              children: [
                _buildPriceCard(context, t, isUnified: true),
                if (idx < tiers.length - 1)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, _TierData data, {bool isUnified = false}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isUnified ? 210 : 200, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isFeatured 
            ? primaryOrange.withValues(alpha: 0.05) 
            : Colors.transparent,
        borderRadius: isUnified 
            ? BorderRadius.zero 
            : BorderRadius.circular(20),
        border: !isUnified && data.isFeatured 
            ? Border.all(color: primaryOrange.withValues(alpha: 0.3)) 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.isFeatured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "الأكثر طلباً",
                style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(height: 20),
          Text(
            data.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            data.subtitle,
            style: TextStyle(fontSize: 10, color: context.mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (data.price != "Custom") ...[
                const Text("\$", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  data.price,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ] else
                const Text(
                  "مخصصة",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
            ],
          ),
          Text(
            data.priceSuffix,
            style: TextStyle(fontSize: 10, color: context.mutedText),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          ...data.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: data.color, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f,
                    style: TextStyle(fontSize: 10, color: context.textColor.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          )),
          const Spacer(), // Use spacer to push button down
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                if (data.tier == SubscriptionTier.enterprise) {
                  setState(() => _showCustomEditor = true);
                } else {
                  _handleSubscribe(data.tier, data.title);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: data.isFeatured ? primaryOrange : (isDark ? Colors.white10 : Colors.black87),
                foregroundColor: data.isFeatured ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                data.buttonText ?? "اشترك الآن",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomModuleSelector(BuildContext context) {
    final modules = AppModules.allModules;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 950), // Wider to fit 10
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _showCustomEditor = false),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "تخصيص النظام",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      "${_selectedCustomModules.length} موديول مختار",
                      style: TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Reduced from 10 to 6 for better readability
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                padding: const EdgeInsets.all(16),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final mod = modules[index];
                  final isSelected = _selectedCustomModules.contains(mod.id);
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCustomModules.remove(mod.id);
                        } else {
                          _selectedCustomModules.add(mod.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? mod.color.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? mod.color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: mod.color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(mod.icon, color: isSelected ? mod.color : context.mutedText, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            mod.localizedName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? context.textColor : context.mutedText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("التكلفة الشهرية المقدرة", style: TextStyle(fontSize: 10, color: context.mutedText)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${_calculateCustomPrice()}",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryOrange),
                            ),
                            const SizedBox(width: 4),
                            Text("/ شهر", style: TextStyle(fontSize: 12, color: context.mutedText)),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _selectedCustomModules.isEmpty 
                          ? null 
                          : () => _handleSubscribe(SubscriptionTier.enterprise, "مخصص"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: primaryOrange.withValues(alpha: 0.4),
                      ),
                      child: const Text("تفعيل النظام المخصص", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCustomPrice() {
    // Basic logic: $10 base + $5 per module
    if (_selectedCustomModules.isEmpty) return 0;
    return 20 + (_selectedCustomModules.length * 5);
  }

  void _handleSubscribe(SubscriptionTier tier, String title) async {
    // If enterprise, we might want to save the selected modules
    if (tier == SubscriptionTier.enterprise && _selectedCustomModules.isNotEmpty) {
      await ModuleConfigService().saveModules(_selectedCustomModules.toList());
      // Automatically hide locked modules so they only see what they bought
      await ModuleConfigService().toggleShowLockedModules(false);
    }
    
    await SubscriptionService().setTier(tier);
    ModuleConfigService().notifyListeners();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تفعيل باقة $title بنجاح!'),
          backgroundColor: primaryOrange,
          behavior: SnackBarBehavior.floating,
        )
      );
      setState(() => _showCustomEditor = false);
    }
  }
}

class _TierData {
  final String title;
  final String subtitle;
  final String price;
  final String priceSuffix;
  final List<String> features;
  final SubscriptionTier tier;
  final bool isFeatured;
  final Color color;
  final String? buttonText;

  _TierData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceSuffix,
    required this.features,
    required this.tier,
    this.isFeatured = false,
    required this.color,
    this.buttonText,
  });
}
