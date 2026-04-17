import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'supplier_details_screen.dart';

class SuppliersDirectoryScreen extends StatefulWidget {
  const SuppliersDirectoryScreen({super.key});

  @override
  State<SuppliersDirectoryScreen> createState() => _SuppliersDirectoryScreenState();
}

class _SuppliersDirectoryScreenState extends State<SuppliersDirectoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper().database;
      final res = await db.query('suppliers');
      if (mounted) {
        setState(() {
          _suppliers = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading suppliers: $e")),
        );
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController contactController = TextEditingController();
    final TextEditingController taxIdController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(context.cardPadding * 1.5),
            decoration: BoxDecoration(
              color: context.obsidianGlass,
              borderRadius: BorderRadius.circular(context.cardRadius),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('suppliers.new_supplier'), style: TextStyle(color: context.textColor, fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close, color: context.mutedText), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    labelText: "اسم المورد *",
                    labelStyle: TextStyle(color: context.mutedText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.cardBorder), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryOrange), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  style: TextStyle(color: context.textColor),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "رقم التواصل",
                    labelStyle: TextStyle(color: context.mutedText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.cardBorder), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryOrange), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taxIdController,
                  style: TextStyle(color: context.textColor),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "الرقم الضريبي",
                    labelStyle: TextStyle(color: context.mutedText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.cardBorder), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: primaryOrange), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("اسم المورد مطلوب"), backgroundColor: Colors.red));
                        return;
                      }
                      final db = await DatabaseHelper().database;
                      await db.insert('suppliers', {
                        'id': 'SUP_${DateTime.now().millisecondsSinceEpoch}',
                        'name': nameController.text.trim(),
                        'contact_info': contactController.text.trim(),
                        'tax_id': taxIdController.text.trim(),
                        'balance': 0.0,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green));
                        _loadSuppliers();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("حفظ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryOrange));
    }

    return Padding(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('suppliers.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                    const SizedBox(height: 2),
                    Text(tr('suppliers.subtitle'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddSupplierDialog,
                icon: Icon(Icons.add, color: Colors.black, size: context.iconSize),
                label: Text(tr('suppliers.new_supplier'), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
                  elevation: 0,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _suppliers.isEmpty 
              ? Center(child: Text(tr('suppliers.empty_suppliers'), style: TextStyle(color: context.mutedText)))
              : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _suppliers.length,
              itemBuilder: (context, index) {
                final s = _suppliers[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => SupplierDetailsScreen(
                          supplierId: s['id'], 
                          supplierName: s['name'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(context.cardRadius),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(context.cardRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(context.cardPadding),
                        decoration: BoxDecoration(
                          color: context.cardSurface,
                          borderRadius: BorderRadius.circular(context.cardRadius),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: Icon(Icons.business, color: Colors.pink, size: context.iconSize),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(s['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize), maxLines: 1),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('suppliers.supplier_balance'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                                    Text("${s['balance'] ?? 0} ${tr('onboarding.currency_hint')}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 1, color: Colors.redAccent)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(tr('suppliers.contact_label'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                                    Text("${s['contact_info'] ?? '-'}", style: TextStyle(fontSize: context.bodySize - 1)),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
