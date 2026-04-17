import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class AgingReportScreen extends StatefulWidget {
  const AgingReportScreen({super.key});

  @override
  State<AgingReportScreen> createState() => _AgingReportScreenState();
}

class _AgingReportScreenState extends State<AgingReportScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = true;
  bool _isClientReport = true; // Toggle between Clients and Suppliers

  @override
  void initState() {
    super.initState();
    _loadAgingReport();
  }

  Future<void> _loadAgingReport({bool forceRecalculate = false}) async {
    setState(() => _isLoading = true);
    try {
      if (forceRecalculate) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(tr('aging.recalculate_msg')), duration: const Duration(seconds: 2))
           );
        }
        await _db.recalculatePartnerBalances();
      }
      
      final db = await _db.database;
      final table = _isClientReport ? 'clients' : 'suppliers';
      final res = await db.query(table, where: 'balance != 0', orderBy: 'balance DESC');
      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading aging report: $e");
      if (mounted) {
        setState(() {
          _reportData = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSurface,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: context.textColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isClientReport ? tr('aging.clients') : tr('aging.suppliers'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadAgingReport(forceRecalculate: true),
            icon: const Icon(Icons.refresh, color: primaryOrange),
            tooltip: tr('aging.recalculate'),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                _buildToggleButton(true, tr('sidebar.clients_short')),
                _buildToggleButton(false, tr('sidebar.suppliers_short')),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
                child: _buildAgingSummary(context),
              ),
              Expanded(
                child: _reportData.isEmpty 
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: EdgeInsets.all(context.sectionPadding),
                      itemCount: _reportData.length,
                      itemBuilder: (context, index) => _buildAgingItem(context, _reportData[index]),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildToggleButton(bool value, String label) {
    bool isSelected = _isClientReport == value;
    return GestureDetector(
      onTap: () {
        if (_isClientReport != value) {
          setState(() => _isClientReport = value);
          _loadAgingReport();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.mutedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 80, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            tr('common.no_data'),
            style: TextStyle(color: context.mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingSummary(BuildContext context) {
    double total = 0;
    for (var item in _reportData) {
      total += (item['balance'] as num?)?.toDouble() ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            _isClientReport ? tr('aging.total_receivable') : tr('aging.total_payable'), 
            '${total.toStringAsFixed(0)} ${tr('common.currency_symbol')}', 
            primaryOrange
          ),
          Container(width: 1, height: 40, color: context.cardBorder),
          _buildSummaryItem(tr('common.count'), '${_reportData.length}', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAgingItem(BuildContext context, Map<String, dynamic> item) {
    final balance = (item['balance'] as num?)?.toDouble() ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryOrange.withValues(alpha: 0.1),
          child: Text(
            (item['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item['name'] ?? tr('common.unknown'), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${item['id']}', style: TextStyle(color: context.mutedText, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${balance.toStringAsFixed(2)} ${tr('common.currency_symbol')}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
            ),
          ],
        ),
        onTap: () => _showDetails(context, item),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 12),
            _buildDetailRow(tr('sidebar.balance'), '${item['balance']} ${tr('common.currency_symbol')}', Colors.red),
            _buildDetailRow(tr('common.status'), tr('common.active'), Colors.green),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tr('common.close'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 14)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

