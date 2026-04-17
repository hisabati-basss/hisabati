import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                        Text("إدارة الوحدات والعقود", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
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
              const SizedBox(height: 16),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: context.cardSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(context.cardRadius / 2),
                  border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
                ),
                child: TabBar(
                  indicatorColor: primaryOrange,
                  indicatorWeight: 3,
                  labelColor: primaryOrange,
                  unselectedLabelColor: context.mutedText,
                  labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "الوحدات السكنية", icon: Icon(Icons.home_rounded, size: 18)),
                    Tab(text: "العقود والتحصيل", icon: Icon(Icons.description_rounded, size: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildUnitsTab(isMobile),
                    _buildContractsTab(isMobile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnitsTab(bool isMobile) {
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: _units.length,
      itemBuilder: (ctx, idx) => _buildUnitCard(_units[idx]),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    bool isAvailable = unit['status'] == 'AVAILABLE';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(context.cardRadius / 2),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isAvailable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.apartment_rounded, color: isAvailable ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(unit['name'] ?? "وحدة غير مسمى", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(unit['address'] ?? "", style: TextStyle(color: context.mutedText, fontSize: 10), maxLines: 1),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${unit['rent_amount']} ر.س", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8C00))),
              Text(isAvailable ? "متاحة" : "مؤجرة", style: TextStyle(fontSize: 10, color: isAvailable ? Colors.green : Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab(bool isMobile) {
    if (_contracts.isEmpty) {
      return Center(child: Text("لا توجد عقود نشطة", style: TextStyle(color: context.mutedText)));
    }
    return ListView.builder(
      itemCount: _contracts.length,
      itemBuilder: (ctx, idx) => _buildContractListItem(_contracts[idx]),
    );
  }

  Widget _buildContractListItem(Map<String, dynamic> contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(context.cardRadius / 2),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history_edu_rounded, color: Color(0xFFFF8C00)),
        title: Text(contract['tenant_name'] ?? "مستأجر"),
        subtitle: Text("ينتهي في: ${contract['end_date']} | المبلغ السنوي: ${contract['annual_rent']} ر.س"),
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
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onPressed, bool isPrimary = false}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFFFF8C00) : context.cardSurface,
        foregroundColor: isPrimary ? Colors.black : context.textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }

  void _showUnitForm() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة وحدة سكنية جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسم الوحدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'قيمة الإيجار الشهري',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContractForm() {
    final tenantCtrl = TextEditingController();
    final rentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إنشاء عقد إيجار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenantCtrl,
              decoration: InputDecoration(
                labelText: 'اسم المستأجر',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الإيجار السنوي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
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
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('حفظ العقد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
