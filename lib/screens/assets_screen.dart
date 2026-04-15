import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import 'manual_journal_screen.dart';
import '../services/depreciation_service.dart';
import '../services/asset_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DepreciationService _depService = DepreciationService();
  final AssetService _assetService = AssetService();
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _costCenters = [];
  bool _isLoading = true;
  bool _isProcessingDep = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadAssets();
  }

  Future<void> _loadMetadata() async {
    final cc = await DatabaseHelper().getCostCenters();
    setState(() => _costCenters = cc);
  }

  Future<void> _loadAssets([String query = '']) async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;
    
    await Future.delayed(const Duration(milliseconds: 300));

    final String sqlQuery = '''
      SELECT a.*, e.name as employee_name, cc.name as cost_center_name
      FROM assets a
      LEFT JOIN employees e ON a.assigned_to = e.id
      LEFT JOIN cost_centers cc ON a.cost_center_id = cc.id
      WHERE a.name LIKE ? OR a.barcode LIKE ? OR a.serial_number LIKE ?
      ORDER BY a.name ASC
    ''';
    
    try {
      final results = await db.rawQuery(sqlQuery, ['%$query%', '%$query%', '%$query%']);
      
      if (results.isEmpty && query.isEmpty) {
        await _seedDummyData(db);
        final newResults = await db.rawQuery(sqlQuery, ['%%', '%%', '%%']);
        setState(() => _assets = newResults);
      } else {
        setState(() => _assets = results);
      }
    } catch (e) {
      print("Database error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('assets_module.error_load', args: [e.toString()]))));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _seedDummyData(Database db) async {
    // 1. Seed Cost Centers
    await db.insert('cost_centers', {'id': 'CC_OPS', 'name': 'قسم العمليات والتشغيل'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('cost_centers', {'id': 'CC_MGMT', 'name': 'الإدارة العامة'}, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 2. Seed Employees
    await db.insert('employees', {'id': 'EMP01', 'name': 'أحمد سعيد', 'job_title': 'مهندس موقع', 'basic_salary': 5000, 'hiring_date': '2025-01-01'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    // 3. Seed Assets
    await db.insert('assets', {
      'id': 'AST_001', 'name': 'جهاز قياس ليزر Bosch', 'barcode': 'BSCH-10023', 'serial_number': 'S-99120', 'location': 'المستودع الرئيسي', 'cost_price': 1500, 'status': 'available', 'purchase_date': '2026-03-01', 'cost_center_id': 'CC_OPS'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('assets', {
      'id': 'AST_002', 'name': 'لابتوب Dell XPS 15', 'barcode': 'DELL-404', 'serial_number': 'S-11223', 'location': 'الفرع الهندسي', 'cost_price': 8500, 'status': 'in_use', 'assigned_to': 'EMP01', 'purchase_date': '2025-10-15', 'cost_center_id': 'CC_MGMT'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return Colors.greenAccent;
      case 'in_use': return Colors.blueAccent;
      case 'maintenance': return Colors.orangeAccent;
      case 'scrap': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available': return tr('assets_module.status_available');
      case 'in_use': return tr('assets_module.status_in_use');
      case 'maintenance': return tr('assets_module.status_maintenance');
      case 'scrap': return tr('assets_module.status_scrap');
      default: return tr('assets_module.status_unknown');
    }
  }

  Future<void> _handleRunDepreciation() async {
    setState(() => _isProcessingDep = true);
    try {
      final result = await _depService.processAllDepreciations();
      if (mounted) {
        _showDepreciationSummary(result);
        _loadAssets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في معالجة الإهلاك: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessingDep = false);
    }
  }

  void _showDepreciationSummary(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 24
        title: Text(tr('assets_module.dep_success_title'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)), // 📉 Reduced from default
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(Icons.account_balance_wallet, tr('assets_module.total_dep_amount'), "${(result['total_amount'] as double).toStringAsFixed(2)} ${tr('ceo.currency.sar')}"),
            _buildSummaryRow(Icons.category, tr('assets_module.assets_affected'), tr('hr.employees_processed') + ": ${result['assets_processed']}"),
            _buildSummaryRow(Icons.article, tr('assets_module.entries_created'), "${result['entries_created']} " + tr('assets_module.entries_cost_centers')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('hr.success'))),
        ],
      )
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // 📉 Reduced from 8
      child: Row(
        children: [
          Icon(icon, size: context.iconSize - 6, color: primaryOrange), // 📉 Reduced
          const SizedBox(width: 6), // 📉 Reduced from 8
          Text(label, style: TextStyle(fontSize: context.bodySize - 2)), // 📉 Reduced
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)), // 📉 Reduced
        ],
      ),
    );
  }

  void _showAssetDetails(Map<String, dynamic> asset) async {
    final String assetId = asset['id'];
    final tco = await _assetService.getAssetTCO(assetId);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: context.bgSurface.withOpacity(0.95),
          borderRadius: BorderRadius.vertical(top: Radius.circular(context.cardRadius + 8)), // 📉 Adjusted from 40
          border: Border.all(color: context.cardBorder),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 32
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(asset['name'], style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold))), // 📉 Reduced from 24
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, size: context.iconSize)), // 📉 Reduced size
                  ],
                ),
                const SizedBox(height: 12), // 📉 Reduced from 24
                _buildTCODashboard(tco, asset),
                const SizedBox(height: 24), // 📉 Reduced from 48
                Text(tr('assets_module.accounting_tracking'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 18
                const SizedBox(height: 16),
                _buildDetailRow(tr('assets_module.cost_center'), asset['cost_center_name'] ?? tr('hr.select_center')),
                _buildDetailRow(tr('assets_module.purchase_date'), asset['purchase_date']),
                _buildDetailRow(tr('assets_module.useful_life'), tr('assets_module.months', args: [ (asset['useful_life_months'] ?? 60).toString()])),
                _buildDetailRow(tr('assets_module.dep_method'), tr('assets_module.dep_method_val')),
                _buildDetailRow(tr('assets_module.last_dep_date'), asset['last_depreciation_date'] ?? tr('assets_module.not_started')),
                const SizedBox(height: 24), // 📉 Reduced from 48
                if (asset['status'] != 'scrap')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.all(context.cardPadding + 4), // 📉 Reduced from 20
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 16
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                      ),
                      onPressed: () => _handleDisposal(assetId, asset['name']),
                      icon: Icon(Icons.no_crash, size: context.iconSize), // 📉 Reduced size
                      label: Text(tr('assets_module.disposal_btn'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)), // 📉 Reduced size
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTCODashboard(Map<String, double> tco, Map<String, dynamic> asset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("إجمالي تكلفة الملكية (TCO Analytics)", style: TextStyle(fontSize: context.bodySize, fontWeight: FontWeight.bold, color: primaryOrange)), // 📉 Reduced from 16
        const SizedBox(height: 12), // 📉 Reduced from 16
        Row(
          children: [
            _buildStatCard(tr('assets_module.purchase_price'), tco['purchase_price']!, Colors.white70),
            const SizedBox(width: 8), // 📉 Reduced from 12
            _buildStatCard(tr('assets_module.maintenance_cost'), tco['maintenance']!, Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 8), // 📉 Reduced from 12
        Row(
          children: [
            _buildStatCard(tr('assets_module.acc_depreciation'), tco['depreciation']!, Colors.redAccent),
            const SizedBox(width: 8), // 📉 Reduced from 12
            _buildStatCard(tr('assets_module.book_value'), tco['nbv']!, Colors.greenAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 20
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: context.bodySize - 2)), // 📉 Reduced from 10
            const SizedBox(height: 2), // 📉 Reduced from 4
            Text("${value.toStringAsFixed(0)} ${tr('ceo.currency.sar')}", style: TextStyle(color: color, fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced from 18
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.mutedText)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _handleDisposal(String assetId, String name) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 24
        title: Text("تخريد الأصل: $name", style: TextStyle(color: Colors.redAccent, fontSize: context.subHeaderSize)), // 📉 Reduced size
        content: Text("سيقوم النظام بإنشاء قيود محاسبية لإغلاق حساب الأصل وإهلاك كامل القيمة الدفترية المتبقية. هل تريد المتابعة؟", style: TextStyle(fontSize: context.bodySize)), // 📉 Added size
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _assetService.disposeAsset(assetId: assetId, reason: "تكهين إداري", proceeds: 0);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(ctx); // Close sheet
              _loadAssets();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تنفيذ عملية التخريد وإصدار القيود المحاسبية بنجاح.")));
            },
            child: const Text("تأكيد التخريد", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopDashboard(),
          const SizedBox(height: 12), // 📉 Reduced from 24
          _buildActionBar(),
          const SizedBox(height: 12), // 📉 Reduced from 24
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : _assets.isEmpty
                ? Center(child: Text(tr('assets_module.no_assets_found'), style: TextStyle(color: context.mutedText)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380, // 📉 Reduced from 450
                      childAspectRatio: 1.8, // 📉 Adjusted for density
                      crossAxisSpacing: 8, // 📉 Reduced from 16
                      mainAxisSpacing: 8, // 📉 Reduced from 16
                    ),
                    itemCount: _assets.length,
                    itemBuilder: (context, index) => _buildAssetCard(_assets[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDashboard() {
    double totalValue = _assets.fold(0, (sum, a) => sum + (a['cost_price'] as num).toDouble());
    int count = _assets.length;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: 8), // 📉 Reduced from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryOrange.withOpacity(0.08), Colors.white.withOpacity(0.01)]), // 📉 Lighter
        borderRadius: BorderRadius.circular(context.cardRadius / 2), // 📉 Sharper
        border: Border.all(color: primaryOrange.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          _buildStatHeader(tr('assets_module.title'), count.toString(), Icons.handyman), // 📉 Shortened
          const VerticalDivider(width: 16, color: Colors.white10), // 📉 Reduced from 24
          _buildStatHeader(tr('assets_module.total_value'), "${totalValue.toStringAsFixed(0)}", Icons.account_balance), // 📉 Shortened
          const Spacer(),
          _isProcessingDep 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: primaryOrange, strokeWidth: 1.5))
            : IconButton.filled(
                onPressed: _handleRunDepreciation,
                style: IconButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black, minimumSize: const Size(28, 28), padding: EdgeInsets.zero),
                icon: Icon(Icons.bolt, size: context.iconSize - 4),
              ),
        ],
      ),
    );
  }

  Widget _buildStatHeader(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: context.iconSize - 8, color: primaryOrange), // 📉 Reduced
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)), // 📉 Reduced
          ],
        ),
        const SizedBox(height: 1), // 📉 Reduced
        Text(value, style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)), // 📉 Reduced from headerSize
      ],
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: context.bodySize),
            onChanged: (val) => _loadAssets(val),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('assets_module.search_hint'),
              prefixIcon: Icon(Icons.search, size: context.iconSize),
              filled: true,
              fillColor: context.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.cardRadius), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8), // 📉 Reduced from 12
          decoration: BoxDecoration(color: context.cardSurface, borderRadius: BorderRadius.circular(context.cardRadius)),
          child: Icon(Icons.filter_list, size: context.iconSize),
        )
      ],
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final statusColor = _getStatusColor(asset['status']);
    
    return Container(
      padding: const EdgeInsets.all(6), // 📉 Reduced from cardPadding
      decoration: BoxDecoration(
        color: context.cardSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(context.cardRadius / 2), // 📉 Reduced from 24
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: statusColor.withOpacity(0.08), radius: 12, child: Icon(Icons.handyman, color: statusColor, size: context.iconSize - 6)), // 📉 Reduced from 16
                const SizedBox(width: 6), // 📉 Reduced from 8
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1), maxLines: 1), // 📉 Reduced
                      Text("SN: ${asset['serial_number'] ?? '-'}", style: TextStyle(fontSize: context.bodySize - 4, color: context.mutedText)), // 📉 Shortened/Reduced
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 📉 Reduced
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                  child: Text(_getStatusText(asset['status']), style: TextStyle(color: statusColor, fontSize: context.bodySize - 4, fontWeight: FontWeight.bold)),
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
                    Text("${asset['cost_price']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
                  ],
                ),
                Icon(Icons.chevron_right, size: context.iconSize - 6, color: primaryOrange.withOpacity(0.5)), // 📉 Simplified
              ],
            ),
          ],
        ),
      ),
    );
  }
}
