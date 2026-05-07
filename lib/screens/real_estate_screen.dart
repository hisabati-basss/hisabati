import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final units = await _db.getRealEstateUnits();
      final contracts = await _db.getRealEstateContracts();

      if (mounted) {
        setState(() {
          _units = units;
          _contracts = contracts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Real Estate Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF8C00);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("نظام إدارة العقارات السكنية v1.0", style: TextStyle(color: context.mutedText, fontSize: 10, letterSpacing: 1.0)),
                        const SizedBox(height: 2),
                        Text("إدارة الوحدات والعقود", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildActionButton(Icons.add_home_work_rounded, "وحدة جديدة", onPressed: _showUnitForm, isPrimary: true),
                        _buildActionButton(Icons.history_edu_rounded, "عقد جديد", onPressed: _showContractForm),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tabs (Glassy)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: context.mutedText,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "الوحدات السكنية", icon: Icon(Icons.home_rounded, size: 18)),
                        Tab(text: "العقود والتحصيل", icon: Icon(Icons.description_rounded, size: 18)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildUnitsTab(isMobile, isDark),
                    _buildContractsTab(isMobile, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnitsTab(bool isMobile, bool isDark) {
    if (_units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text("لا توجد وحدات مسجلة حالياً", style: TextStyle(color: context.mutedText)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: _units.length,
      itemBuilder: (ctx, idx) => _buildUnitCard(_units[idx], isDark),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit, bool isDark) {
    bool isAvailable = unit['status'] == 'AVAILABLE';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isAvailable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.apartment_rounded, color: isAvailable ? Colors.green : Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unit['name'] ?? "وحدة غير مسمى", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      unit['address'] ?? "", 
                      style: TextStyle(color: context.mutedText, fontSize: 10), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${unit['rent_amount']} ر.س", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8C00), fontSize: 13)
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAvailable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAvailable ? "متاحة" : "مؤجرة", 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isAvailable ? Colors.green : Colors.orange)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractsTab(bool isMobile, bool isDark) {
    if (_contracts.isEmpty) {
      return Center(child: Text("لا توجد عقود نشطة", style: TextStyle(color: context.mutedText)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _contracts.length,
      itemBuilder: (ctx, idx) => _buildContractListItem(_contracts[idx], isDark),
    );
  }

  Widget _buildContractListItem(Map<String, dynamic> contract, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFF8C00).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.history_edu_rounded, color: Color(0xFFFF8C00), size: 20),
              ),
              title: Text(contract['tenant_name'] ?? "مستأجر", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(
                "ينتهي: ${contract['end_date']} | ${contract['annual_rent']} ر.س",
                style: TextStyle(color: context.mutedText, fontSize: 11),
              ),
              trailing: _buildActionButton(Icons.payments_rounded, "تحصيل", onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('سيتم تسجيل تحصيل إيجار ${contract['tenant_name'] ?? "المستأجر"} — قادم في التحديث القادم'),
                    backgroundColor: const Color(0xFFFF8C00),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }, isPrimary: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onPressed, bool isPrimary = false}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFFFF8C00) : Colors.white.withValues(alpha: 0.05),
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }

  void _showUnitForm() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إضافة وحدة سكنية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 24),
                        _input(nameCtrl, 'اسم الوحدة'),
                        const SizedBox(height: 12),
                        _input(addressCtrl, 'العنوان الكامل'),
                        const SizedBox(height: 12),
                        _input(rentCtrl, 'قيمة الإيجار الشهري', isNum: true),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: context.mutedText)))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (nameCtrl.text.isEmpty) return;
                                  try {
                                    await _db.addRealEstateUnit({
                                      'name': nameCtrl.text,
                                      'address': addressCtrl.text,
                                      'rent_amount': double.tryParse(rentCtrl.text) ?? 0,
                                      'status': 'AVAILABLE',
                                    });
                                    Navigator.pop(ctx);
                                    _loadData();
                                  } catch (e) {
                                    debugPrint("Save Error: $e");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C00),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('حفظ الوحدة', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _input(TextEditingController c, String h, {bool isNum = false}) => TextField(
    controller: c,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    textAlign: TextAlign.right,
    decoration: InputDecoration(
      hintText: h,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  void _showContractForm() {
    final tenantCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إنشاء عقد جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 24),
                        _input(tenantCtrl, 'اسم المستأجر'),
                        const SizedBox(height: 12),
                        _input(rentCtrl, 'الإيجار السنوي الإجمالي', isNum: true),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: context.mutedText)))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (tenantCtrl.text.isEmpty) return;
                                  try {
                                    final now = DateTime.now();
                                    await _db.addRealEstateContract({
                                      'tenant_name': tenantCtrl.text,
                                      'annual_rent': double.tryParse(rentCtrl.text) ?? 0,
                                      'start_date': now.toIso8601String().split('T')[0],
                                      'end_date': DateTime(now.year + 1, now.month, now.day).toIso8601String().split('T')[0],
                                    });
                                    Navigator.pop(ctx);
                                    _loadData();
                                  } catch (e) {
                                     debugPrint("Save Error: $e");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C00),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('حفظ العقد', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
