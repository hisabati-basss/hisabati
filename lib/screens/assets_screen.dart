import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';
import '../services/depreciation_service.dart';
import '../services/asset_service.dart';

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
  bool _isLoading = true;
  bool _isProcessingDep = false;

  @override
  void initState() {
    super.initState();
    _initAssets();
  }

  Future<void> _initAssets() async {
    await _ensureAssetSchema();
    await _loadAssets();
  }

  Future<void> _ensureAssetSchema() async {
    try {
      final db = await DatabaseHelper().database;
      final tableInfo = await db.rawQuery('PRAGMA table_info(assets)');
      final columns = tableInfo.map((c) => c['name'].toString()).toList();
      
      if (!columns.contains('purchase_date')) {
        await db.execute('ALTER TABLE assets ADD COLUMN purchase_date TEXT');
      }
      if (!columns.contains('useful_life')) {
        await db.execute('ALTER TABLE assets ADD COLUMN useful_life INTEGER DEFAULT 60');
      }
      if (!columns.contains('salvage_value')) {
        await db.execute('ALTER TABLE assets ADD COLUMN salvage_value REAL DEFAULT 0.0');
      }
      if (!columns.contains('last_depreciation_date')) {
        await db.execute('ALTER TABLE assets ADD COLUMN last_depreciation_date TEXT');
      }
      if (!columns.contains('accumulated_depreciation')) {
        await db.execute('ALTER TABLE assets ADD COLUMN accumulated_depreciation REAL DEFAULT 0.0');
      }
    } catch (e) {
      debugPrint("Asset Schema Migration Error: $e");
    }
  }

  Future<void> _loadAssets([String query = '']) async {
    if (mounted) setState(() => _isLoading = true);
    final db = await DatabaseHelper().database;
    
    final String sqlQuery = '''
      SELECT a.*, e.name as employee_name, cc.name as cost_center_name
      FROM assets a
      LEFT JOIN employees e ON a.assigned_to = e.id
      LEFT JOIN cost_centers cc ON a.cost_center_id = cc.id
      WHERE (a.name LIKE ? OR a.barcode LIKE ? OR a.serial_number LIKE ?)
      AND a.is_deleted = 0
      ORDER BY a.name ASC
    ''';
    
    try {
      final results = await db.rawQuery(sqlQuery, ['%$query%', '%$query%', '%$query%']);
      if (mounted) setState(() => _assets = results);
    } catch (e) {
      debugPrint("Database error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Slim Glass Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              tr('assets_module.title'),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.inventory_rounded, color: primaryOrange, size: 16),
                        ],
                      ),
                      Text(
                        "${_assets.length} ${tr('assets_module.assets_count')}",
                        style: TextStyle(color: context.mutedText, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Refresh/Depreciation Action
                GestureDetector(
                  onTap: () async {
                    if (_isProcessingDep) return;
                    setState(() => _isProcessingDep = true);
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 16),
                          Text(tr('common.loading')),
                        ],
                      ),
                      duration: const Duration(seconds: 1),
                    ));

                    try {
                      final results = await _depService.processAllDepreciations();
                      await _loadAssets();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("${tr('assets_module.dep_success_title')}: ${results['assets_processed']} ${tr('assets_module.assets_affected')}"),
                          backgroundColor: Colors.green,
                        ));
                      }
                    } catch (e) {
                      debugPrint("Depreciation error: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("${tr('common.error')}: $e"),
                          backgroundColor: Colors.redAccent,
                        ));
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessingDep = false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isProcessingDep ? Icons.hourglass_empty : Icons.bolt, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(tr('assets_module.dep_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Glass Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 11),
                          onChanged: _loadAssets,
                          decoration: InputDecoration(
                            hintText: tr('assets_module.search_hint'),
                            hintStyle: TextStyle(color: context.mutedText, fontSize: 11),
                            isDense: true,
                            prefixIcon: Icon(Icons.search, size: 14, color: context.mutedText),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_assets.fold(0.0, (sum, a) => sum + ((a['cost_price'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(0)} ${tr('ceo.currency.sar')}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryOrange),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Assets Grid
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 90,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) => _buildAssetGlassCard(_assets[index], isDark),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetGlassCard(Map<String, dynamic> asset, bool isDark) {
    final statusColor = _getStatusColor(asset['status']?.toString() ?? 'available');
    final name = asset['name']?.toString() ?? 'صنف غير معروف';
    final price = (asset['cost_price'] as num?)?.toDouble() ?? 0.0;
    final sn = asset['serial_number']?.toString() ?? '-';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text("SN: $sn", style: TextStyle(color: context.mutedText, fontSize: 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "${price.toStringAsFixed(0)} ${tr('ceo.currency.sar')}", 
                    style: TextStyle(color: context.mutedText, fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                  Icon(Icons.arrow_forward_ios, size: 10, color: context.mutedText.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
