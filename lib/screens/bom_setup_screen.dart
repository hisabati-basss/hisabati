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
  String _bomName = "";
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
        'raw_material_item_id': null,
        'quantity_required': 1.0,
        'waste_percentage': 0.0,
      });
    });
  }

  Future<void> _saveBOM() async {
    if (_selectedFinishedGoodId == null || _bomName.isEmpty || _bomLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('bom.error_incomplete'))));
      return;
    }

    double overhead = double.tryParse(_overheadController.text) ?? 0.0;

    final db = await _db.database;
    await db.insert('bom', {
      'id': 'BOM_${DateTime.now().millisecondsSinceEpoch}',
      'name': _bomName,
      'target_item_id': _selectedFinishedGoodId,
      'estimated_overhead': overhead,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });

    final bomId = 'BOM_${DateTime.now().millisecondsSinceEpoch}';
    for (var lineData in _bomLines) {
      if (lineData['raw_material_item_id'] == null) continue;
      await db.insert('bom_ingredients', {
        'id': '${bomId}_${lineData['raw_material_item_id']}',
        'bom_id': bomId,
        'item_id': lineData['raw_material_item_id'],
        'quantity': lineData['quantity_required'],
        'waste_percentage': lineData['waste_percentage'],
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('bom.save_success')), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.blue));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(tr('bom.title'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.sectionPadding),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: context.cardBorder),
          ),
          child: ListView(
            padding: EdgeInsets.all(context.cardPadding),
            children: [
              Text(tr('bom.finished_good'), style: TextStyle(color: context.mutedText, fontSize: context.subHeaderSize - 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: tr('bom.target_product'),
                        labelStyle: TextStyle(fontSize: context.bodySize),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      value: _selectedFinishedGoodId,
                      dropdownColor: context.cardSurface,
                      items: _items.map((e) => DropdownMenuItem<String>(
                        value: e['id']?.toString(),
                        child: Text(e['name']?.toString() ?? '', style: TextStyle(color: context.textColor, fontSize: context.bodySize - 1)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedFinishedGoodId = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: context.bodySize),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: tr('bom.bom_name'),
                        labelStyle: TextStyle(fontSize: context.bodySize),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => _bomName = val,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _overheadController,
                      style: TextStyle(fontSize: context.bodySize),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: tr('bom.overhead_per_unit'),
                        labelStyle: TextStyle(fontSize: context.bodySize),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('bom.raw_materials'), style: TextStyle(color: context.mutedText, fontSize: context.subHeaderSize - 2, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: _addBomLine, 
                    icon: Icon(Icons.add, size: context.iconSize - 4), 
                    label: Text(tr('bom.add_material'), style: TextStyle(fontSize: context.bodySize - 1, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              ...List.generate(_bomLines.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.cardBorder.withValues(alpha: 0.3)),
                        child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: tr('bom.material'),
                            labelStyle: TextStyle(fontSize: context.bodySize - 1),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                          ),
                          value: _bomLines[index]['raw_material_item_id'],
                          dropdownColor: context.cardSurface,
                          items: _items.map((e) => DropdownMenuItem<String>(
                            value: e['id']?.toString(),
                            child: Text(e['name']?.toString() ?? '', style: TextStyle(color: context.textColor, fontSize: context.bodySize - 1)),
                          )).toList(),
                          onChanged: (val) => setState(() => _bomLines[index]['raw_material_item_id'] = val),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: _bomLines[index]['quantity_required'].toString(),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: context.bodySize - 1),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: tr('bom.quantity'), labelStyle: TextStyle(fontSize: context.bodySize - 2), filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)
                          ),
                          onChanged: (val) => _bomLines[index]['quantity_required'] = double.tryParse(val) ?? 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: _bomLines[index]['waste_percentage'].toString(),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: context.bodySize - 1),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: tr('bom.waste_pct'), labelStyle: TextStyle(fontSize: context.bodySize - 2), filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none)
                          ),
                          onChanged: (val) => _bomLines[index]['waste_percentage'] = double.tryParse(val) ?? 0.0,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: context.iconSize - 4),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _bomLines.removeAt(index)),
                      )
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: _saveBOM,
                  child: Text(tr('bom.save_btn'), style: TextStyle(fontSize: context.bodySize, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
