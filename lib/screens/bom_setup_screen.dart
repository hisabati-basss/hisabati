import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class BomSetupScreen extends StatefulWidget {
  const BomSetupScreen({super.key});

  @override
  State<BomSetupScreen> createState() => _BomSetupScreenState();
}

class _BomSetupScreenState extends State<BomSetupScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _bomLines = [];
  
  String? _selectedFinishedGoodId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _overheadController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _db.getProducts();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _addBomLine() {
    setState(() {
      _bomLines.add({
        'raw_material_item_id': _items.isNotEmpty ? _items.first['id']?.toString() : null,
        'quantity_required': 1.0,
        'waste_percentage': 0.0,
      });
    });
  }


  Future<void> _saveBOM() async {
    final String bomName = _nameController.text.trim();
    
    if (_selectedFinishedGoodId == null || bomName.isEmpty || _bomLines.isEmpty) {
      String missing = "";
      if (_selectedFinishedGoodId == null) missing += " (المنتج) ";
      if (bomName.isEmpty) missing += " (اسم التركيبة) ";
      if (_bomLines.isEmpty) missing += " (المكونات) ";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${tr('bom.error_incomplete')} $missing"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      double overhead = double.tryParse(_overheadController.text) ?? 0.0;
      final db = await _db.database;
      

      final String bomId = 'BOM_${DateTime.now().millisecondsSinceEpoch}';

      await db.transaction((txn) async {
        await txn.insert('bom', {
          'id': bomId,
          'name': bomName,
          'finished_good_item_id': _selectedFinishedGoodId,
          'estimated_overhead_cost': overhead,
          'sync_status': 0,
          'updated_at': DateTime.now().toIso8601String(),
        });

        for (int i = 0; i < _bomLines.length; i++) {
          var lineData = _bomLines[i];
          await txn.insert('bom_lines', {
            'id': '${bomId}_${i}',
            'bom_id': bomId,
            'raw_material_item_id': lineData['raw_material_item_id'],
            'quantity_required': lineData['quantity_required'],
            'waste_percentage': lineData['waste_percentage'],
            'updated_at': DateTime.now().toIso8601String(),
            'sync_status': 0,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('bom.save_success')), 
          backgroundColor: Colors.green
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("FATAL BOM ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"), 
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryOrange));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.locale.languageCode == 'ar';
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Container(
      height: sh * 0.75, // Take 75% of height for "small" feel
      margin: const EdgeInsets.all(16), // Floating effect
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: context.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tr('bom.title'),
                          style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(tr('bom.finished_good'), style: TextStyle(color: context.mutedText, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.architecture_rounded, color: primaryOrange, size: 20),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Header Inputs
                _buildGlassDropdown(
                  tr('bom.target_product'), 
                  _selectedFinishedGoodId, 
                  (val) => setState(() {
                    _selectedFinishedGoodId = val;
                  })
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassField(_overheadController, tr('bom.overhead_per_unit'), isNum: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassField(_nameController, tr('bom.bom_name')),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Raw Materials Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _addBomLine,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.add, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(tr('bom.add_material'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ]),
                      ),
                    ),
                    Text(tr('bom.raw_materials'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),

                // Ingredients List
                ...List.generate(_bomLines.length, (index) => _buildIngredientRow(index, isDark)),
                
                if (_bomLines.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        isAr ? "لم يتم إضافة مكونات بعد" : "No ingredients added yet", 
                        style: TextStyle(color: context.mutedText, fontSize: 11)
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveBOM,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  tr('bom.save_btn'), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ),
            ),
          ),
          const SizedBox(height: 8), // Extra bottom spacing
        ],
      ),
    );
  }

  Widget _buildGlassField(TextEditingController ctrl, String hint, {bool isNum = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(hint, style: TextStyle(color: context.mutedText, fontSize: 9)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown(String label, String? value, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 9)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: context.textColor, fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _items.map((e) => DropdownMenuItem<String>(
            value: e['id']?.toString(),
            child: Text(e['name']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIngredientRow(int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
            onPressed: () => setState(() => _bomLines.removeAt(index)),
          ),
          Expanded(
            child: _buildTinyField(
              tr('bom.waste_pct'), 
              _bomLines[index]['waste_percentage'].toString(),
              (val) => _bomLines[index]['waste_percentage'] = double.tryParse(val) ?? 0.0,
              isNum: true
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTinyField(
              tr('bom.quantity'), 
              _bomLines[index]['quantity_required'].toString(),
              (val) => _bomLines[index]['quantity_required'] = double.tryParse(val) ?? 1.0,
              isNum: true
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(tr('bom.material'), style: TextStyle(color: context.mutedText, fontSize: 8)),
                const SizedBox(height: 2),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _bomLines[index]['raw_material_item_id'],
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(color: context.textColor, fontSize: 11),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _items.map((e) => DropdownMenuItem<String>(
                    value: e['id']?.toString(),
                    child: Text(e['name']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                  )).toList(),
                  onChanged: (val) => setState(() {
                    _bomLines[index]['raw_material_item_id'] = val;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyField(String label, String initial, Function(String) onChanged, {bool isNum = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 8)),
        const SizedBox(height: 2),
        TextFormField(
          initialValue: initial,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
