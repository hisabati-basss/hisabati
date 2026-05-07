import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/manufacturing_service.dart';
import '../theme/app_theme_extension.dart';
import 'bom_setup_screen.dart';
import 'manufacturing_dashboard_tab.dart';

class ManufacturingScreen extends StatefulWidget {
  final bool isMobile;
  const ManufacturingScreen({super.key, this.isMobile = false});

  @override
  State<ManufacturingScreen> createState() => _ManufacturingScreenState();
}

class _ManufacturingScreenState extends State<ManufacturingScreen> with SingleTickerProviderStateMixin {
  final ManufacturingService _mfgService = ManufacturingService();
  late TabController _tabController;

  List<Map<String, dynamic>> _boms = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final boms = await _mfgService.getBOMs();
    final orders = await _mfgService.getOrders();
    final stats = await _mfgService.getStats();
    setState(() {
      _boms = boms;
      _orders = orders;
      _stats = stats;
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
        title: Text(tr('manufacturing.new_order'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: tr('manufacturing.select_bom')),
              dropdownColor: context.cardSurface,
              items: _boms.map((b) => DropdownMenuItem(value: b['id']?.toString(), child: Text(b['name'] ?? 'N/A'))).toList(),
              onChanged: (val) => selectedBomId = val,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('manufacturing.quantity'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            onPressed: () async {
              if (selectedBomId == null) return;
              await _mfgService.createOrder(selectedBomId!, double.tryParse(qtyController.text) ?? 1.0);
              Navigator.pop(ctx);
              _loadData();
            },
            child: Text(tr('manufacturing.issue_order'), style: const TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Future<void> _startOrder(Map<String, dynamic> order) async {
    final String orderId = order['id'].toString();
    final String bomId = order['bom_id'].toString();
    final double qty = (order['qty_to_produce'] as num).toDouble();

    // Check availability first
    final availability = await _mfgService.checkMaterialAvailability(bomId, qty);
    final bool hasShortage = availability.any((a) => !a['is_sufficient']);

    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardSurface,
          title: Text(tr('manufacturing.availability_check')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...availability.map((a) => ListTile(
                dense: true,
                title: Text(a['item_name']),
                subtitle: Text("${tr('manufacturing.required')}: ${a['required']} | ${tr('manufacturing.available')}: ${a['available']}"),
                trailing: Icon(
                  a['is_sufficient'] ? Icons.check_circle : Icons.error,
                  color: a['is_sufficient'] ? Colors.green : Colors.red,
                ),
              )),
              if (hasShortage)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(tr('manufacturing.shortage_warning'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            if (!hasShortage)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _mfgService.startOrder(orderId);
                    Navigator.pop(ctx);
                    _loadData();
                    _tabController.animateTo(1); // Move to In Progress
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(tr('manufacturing.start_now')),
              ),
          ],
        ),
      );
    }
  }

  Future<void> _finalizeOrder(Map<String, dynamic> order) async {
    final String orderId = order['id'].toString();
    final qtyController = TextEditingController(text: order['qty_to_produce'].toString());
    final overheadController = TextEditingController(text: "0");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        title: Text(tr('manufacturing.complete_order')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr('manufacturing.actual_qty')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: overheadController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr('manufacturing.actual_overhead')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _mfgService.finalizeOrder(
                  orderId,
                  double.tryParse(qtyController.text) ?? 0.0,
                  double.tryParse(overheadController.text) ?? 0.0,
                );
                Navigator.pop(ctx);
                _loadData();
                _tabController.animateTo(2); // Move to Completed
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(tr('manufacturing.deposit_finished')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(tr('manufacturing.production_hall'), style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryOrange,
          unselectedLabelColor: context.mutedText,
          indicatorColor: primaryOrange,
          tabs: [
            Tab(text: tr('manufacturing.tab_planned')),
            Tab(text: tr('manufacturing.tab_in_progress')),
            Tab(text: tr('manufacturing.tab_completed')),
            Tab(text: tr('manufacturing.tab_stats')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.architecture_rounded, color: primaryOrange),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const BomSetupScreen(),
            ).then((_) => _loadData()),
          ),
          ElevatedButton.icon(
            onPressed: _createProductionOrder,
            icon: const Icon(Icons.add, color: Colors.black, size: 18),
            label: Text(tr('manufacturing.new_order_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('planned'),
          _buildOrderList('in_progress'),
          _buildOrderList('completed'),
          ManufacturingDashboardTab(stats: _stats),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _orders.where((o) => o['status'] == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: context.mutedText.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(tr('common.no_data'), style: TextStyle(color: context.mutedText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return Card(
          color: context.cardSurface,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            title: Text(order['bom_name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${tr('manufacturing.qty_target')}: ${order['qty_to_produce']}"),
                if (status == 'completed') 
                  Text("${tr('manufacturing.total_cost')}: ${order['total_cost']}", style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: _buildActionBtn(status, order),
          ),
        );
      },
    );
  }

  Widget? _buildActionBtn(String status, Map<String, dynamic> order) {
    if (status == 'planned') {
      return ElevatedButton(
        onPressed: () => _startOrder(order),
        style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black),
        child: Text(tr('manufacturing.start_now')),
      );
    }
    if (status == 'in_progress') {
      return ElevatedButton(
        onPressed: () => _finalizeOrder(order),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: Text(tr('manufacturing.deposit_finished')),
      );
    }
    if (status == 'completed') {
      final qcStatus = order['qc_status'] ?? 'pending';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: qcStatus == 'passed' ? Colors.green.withValues(alpha: 0.1) : (qcStatus == 'failed' ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tr('manufacturing.qc_$qcStatus'),
              style: TextStyle(
                color: qcStatus == 'passed' ? Colors.green : (qcStatus == 'failed' ? Colors.red : Colors.orange),
                fontSize: 10,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          if (qcStatus == 'pending')
            TextButton(
              onPressed: () => _showQCDialog(order),
              child: Text(tr('manufacturing.inspect'), style: const TextStyle(fontSize: 12)),
            ),
        ],
      );
    }
    return null;
  }

  Future<void> _showQCDialog(Map<String, dynamic> order) async {
    final notesController = TextEditingController();
    String? selectedStatus = 'passed';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        title: Text(tr('manufacturing.quality_inspection')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(labelText: tr('manufacturing.inspection_result')),
              items: [
                DropdownMenuItem(value: 'passed', child: Text(tr('manufacturing.qc_passed'))),
                DropdownMenuItem(value: 'failed', child: Text(tr('manufacturing.qc_failed'))),
              ],
              onChanged: (val) => selectedStatus = val,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: tr('manufacturing.qc_notes'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatus == null) return;
              await _mfgService.submitQC(order['id'].toString(), selectedStatus!, notesController.text);
              Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: Text(tr('common.save'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
