import 'package:flutter/material.dart';
import '../services/manufacturing_service.dart';
import '../theme/app_theme_extension.dart';
import 'bom_setup_screen.dart';

class ManufacturingScreen extends StatefulWidget {
  final bool isMobile;
  const ManufacturingScreen({super.key, this.isMobile = false});

  @override
  State<ManufacturingScreen> createState() => _ManufacturingScreenState();
}

class _ManufacturingScreenState extends State<ManufacturingScreen> {
  final ManufacturingService _mfgService = ManufacturingService();

  List<Map<String, dynamic>> _boms = [];
  List<Map<String, dynamic>> _orders = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final boms = await _mfgService.getBOMs();
    final orders = await _mfgService.getOrders();
    
    setState(() {
      _boms = boms;
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _createProductionOrder() async {
    String? selectedBomId;
    final qtyController = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
        title: Text("أمر تصنيع", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "اختر المواصفة (BOM)"),
              dropdownColor: context.cardSurface,
              items: _boms.map((b) => DropdownMenuItem(value: b['id']?.toString(), child: Text(b['name'] ?? 'N/A'))).toList(),
              onChanged: (val) => selectedBomId = val,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: context.bodySize),
              decoration: InputDecoration(
                isDense: true,
                labelText: "الكمية",
                labelStyle: TextStyle(fontSize: context.bodySize),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () async {
              if (selectedBomId == null) return;
              
              await _mfgService.createOrder(selectedBomId!, double.tryParse(qtyController.text) ?? 1.0);
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text("إصدار الأمر", style: TextStyle(color: Colors.black)),
          )
        ],
      )
    );
  }

  Future<void> _completeOrder(String orderId) async {
      try {
        final result = await _mfgService.completeManufacturingOrder(orderId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("تم إنهاء التصنيع بنجاح! التكلفة المقدرة: ${result['cost_per_unit']}"),
            backgroundColor: Colors.green,
          ));
          _loadData();
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text("خطأ أثناء التصنيع: ${e.toString()}"),
             backgroundColor: Colors.redAccent,
             duration: const Duration(seconds: 5),
           ));
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("صالة الإنتاج", style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BomSetupScreen())).then((_) => _loadData()),
            icon: Icon(Icons.settings, color: Colors.white, size: context.iconSize - 6),
            label: Text("المواصفات (BOM)", style: TextStyle(color: Colors.white, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius / 2)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _createProductionOrder,
            icon: Icon(Icons.add, color: Colors.black, size: context.iconSize - 6),
            label: Text("أمر جديد", style: TextStyle(color: Colors.black, fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius / 2)),
            ),
          ),
          SizedBox(width: context.sectionPadding / 2),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(context.sectionPadding),
        child: ListView.builder(
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            final bool isCompleted = order['status'] == 'completed';
            
            return Card(
              color: context.cardSurface,
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.cardRadius / 2),
                side: BorderSide(color: context.cardBorder.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: 4),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  child: Icon(isCompleted ? Icons.check_circle : Icons.precision_manufacturing, color: isCompleted ? Colors.green : Colors.orange, size: context.iconSize - 4),
                ),
                title: Text(order['bom_name'] ?? "N/A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                subtitle: Row(
                  children: [
                    Text("Qty: ${order['qty_to_produce']}", style: TextStyle(fontSize: context.bodySize - 2, color: context.mutedText)),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Text("Cost: ${order['total_cost']}", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: context.bodySize - 2)),
                    ],
                  ],
                ),
                trailing: isCompleted
                  ? Text("مكتمل", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: context.bodySize - 2))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(60, 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => _completeOrder(order['id']?.toString() ?? ''),
                      child: Text("إيداع", style: TextStyle(color: Colors.white, fontSize: context.bodySize - 2, fontWeight: FontWeight.bold)),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}
