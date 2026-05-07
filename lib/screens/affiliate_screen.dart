import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});
  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Map<String, dynamic>> _clients = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _db.getClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Clients Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final vatCtrl = TextEditingController();
    final commissionRateCtrl = TextEditingController(text: "0");
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
            side: const BorderSide(color: Colors.white10),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_add_rounded, color: primaryOrange),
              ),
              const SizedBox(width: 12),
              const Text("إضافة عميل جديد", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, "اسم العميل الكامل", Icons.person_outline),
                const SizedBox(height: 12),
                _buildField(phoneCtrl, "رقم الجوال", Icons.phone_android_outlined, isPhone: true),
                const SizedBox(height: 12),
                _buildField(emailCtrl, "البريد الإلكتروني", Icons.email_outlined),
                const SizedBox(height: 12),
                _buildField(vatCtrl, "الرقم الضريبي (إن وجد)", Icons.description_outlined),
                const SizedBox(height: 12),
                _buildField(commissionRateCtrl, "نسبة العمولة (%) - إذا كان شريكاً", Icons.percent_rounded, isPhone: true),
                const SizedBox(height: 12),
                _buildField(addressCtrl, "العنوان بالتفصيل", Icons.location_on_outlined),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("إلغاء", style: TextStyle(color: context.mutedText)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final db = await _db.database;
                await db.insert('clients', {
                  'id': 'CL_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'tax_id': vatCtrl.text.trim(),
                  'balance': (double.tryParse(commissionRateCtrl.text) ?? 0.0) / 100, // Re-purposing balance as commission rate for simple storage or using a dedicated column
                  'address': addressCtrl.text.trim(),
                  'updated_at': DateTime.now().toIso8601String(),
                  'sync_status': 0,
                  'is_deleted': 0,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تمت إضافة العميل بنجاح"), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              child: const Text("حفظ العميل", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: primaryOrange.withValues(alpha: 0.7), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _clients.where((c) => 
      c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c['phone'].toString().contains(_searchQuery)
    ).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : _buildClientsList(filteredClients),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.sectionPadding, 12, context.sectionPadding, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("دليل العملاء الذكي", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("إدارة قاعدة بيانات عملائك واحتياجاتهم", style: TextStyle(color: context.mutedText, fontSize: 11)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text("عميل جديد", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: "ابحث باسم العميل أو رقم الجوال...",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
            prefixIcon: Icon(Icons.search_rounded, color: primaryOrange, size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildClientsList(List<Map<String, dynamic>> clients) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text("لا يوجد عملاء مسجلين حالياً", style: TextStyle(color: context.mutedText, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: context.sectionPadding),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        final bool isDefault = client['id'] == 'CL_DEFAULT';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDefault ? [Colors.blue, Colors.blue.shade900] : [primaryOrange, Colors.orange.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    client['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 10, color: context.mutedText),
                          const SizedBox(width: 4),
                          Text(client['phone'] ?? 'بدون هاتف', style: TextStyle(color: context.mutedText, fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(Icons.location_on, size: 10, color: context.mutedText),
                          const SizedBox(width: 4),
                          Text(client['address'] ?? 'بدون عنوان', style: TextStyle(color: context.mutedText, fontSize: 11)),
                        ],
                      ),
                      if (client['tax_id'] != null && client['tax_id'].toString().isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 2),
                           child: Text("الرقم الضريبي: ${client['tax_id']}", style: const TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                         ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: context.mutedText, size: 20),
                    onPressed: () {
                      // Future: Edit/Delete actions
                    },
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
