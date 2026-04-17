import 'package:flutter/material.dart';
import '../../../services/custody_service.dart';
import '../../../theme/app_theme_extension.dart';

class CustodyTab extends StatefulWidget {
  final String employeeId;
  const CustodyTab({super.key, required this.employeeId});

  @override
  State<CustodyTab> createState() => _CustodyTabState();
}

class _CustodyTabState extends State<CustodyTab> {
  final CustodyService _custodyService = CustodyService();
  List<Map<String, dynamic>> _financialCustodies = [];
  List<Map<String, dynamic>> _assetCustodies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustodies();
  }

  Future<void> _loadCustodies() async {
    final fin = await _custodyService.getFinancialCustodies(employeeId: widget.employeeId);
    final asset = await _custodyService.getAssetCustodies(employeeId: widget.employeeId);
    setState(() {
      _financialCustodies = fin;
      _assetCustodies = asset;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("العهد المالية (النقدية)", Icons.account_balance_wallet_outlined),
          const SizedBox(height: 12),
          if (_financialCustodies.isEmpty)
             _buildEmptyState("لا توجد عهد مالية مسجلة")
          else
            ..._financialCustodies.map((c) => _buildFinancialCard(c)),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader("العهد العينية (الأصول)", Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          if (_assetCustodies.isEmpty)
             _buildEmptyState("لا توجد عهد أصول مسجلة")
          else
            ..._assetCustodies.map((a) => _buildAssetCard(a)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
      ),
      child: Center(child: Text(msg, style: TextStyle(color: context.mutedText, fontSize: 13))),
    );
  }

  Widget _buildFinancialCard(Map<String, dynamic> c) {
    final bool isCleared = c['status'] == CustodyService.FIN_CLEARED;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['reason'] ?? 'عهدة عامة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("التاريخ: ${c['issue_date'].toString().split('T').first}", style: TextStyle(color: context.mutedText, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${c['amount']} ر.س", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCleared ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c['status'], 
                  style: TextStyle(color: isCleared ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.laptop_mac, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['name'] ?? 'أصل', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("S/N: ${a['serial_number'] ?? 'N/A'}", style: TextStyle(color: context.mutedText, fontSize: 12)),
              ],
            ),
          ),
          Text("بحوزته", style: TextStyle(color: context.mutedText, fontSize: 12)),
        ],
      ),
    );
  }
}
