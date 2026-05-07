import 'dart:ui';
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
  bool _isClientReport = true;

  @override
  void initState() {
    super.initState();
    _loadAgingReport();
  }

  Future<void> _loadAgingReport({bool forceRecalculate = false}) async {
    setState(() => _isLoading = true);
    try {
      if (forceRecalculate) {
        await _db.recalculatePartnerBalances();
      }
      final db = await _db.database;
      final table = _isClientReport ? 'clients' : 'suppliers';
      final res = await db.query(table, where: 'balance != 0', orderBy: 'balance DESC');
      if (mounted) setState(() { _reportData = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _reportData = []; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isAr = context.locale.languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Slim Custom Header
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
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isClientReport 
                            ? (isAr ? "أعمار ديون العملاء" : "Client Aging") 
                            : (isAr ? "أعمار ديون الموردين" : "Supplier Aging"),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.history_toggle_off, color: primaryOrange, size: 16),
                      ],
                    ),
                    Text(isAr ? "التقارير المالية" : "Financial Reports", style: TextStyle(color: context.mutedText, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          // High Density Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      _buildMiniTab(true, isAr ? "العملاء" : "Clients"),
                      _buildMiniTab(false, isAr ? "الموردين" : "Suppliers"),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _loadAgingReport(forceRecalculate: true),
                  constraints: const BoxConstraints(maxHeight: 24, maxWidth: 24),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.refresh, color: primaryOrange, size: 16),
                ),
              ],
            ),
          ),

          // Glass Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildGlassSummary(isDark, isAr),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryOrange))
              : _reportData.isEmpty 
                ? _buildEmptyState(context, isAr)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _reportData.length,
                    itemBuilder: (context, index) => _buildCompactAgingItem(isDark, _reportData[index], isAr),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTab(bool value, String label) {
    bool isSelected = _isClientReport == value;
    return GestureDetector(
      onTap: () {
        if (_isClientReport != value) {
          setState(() => _isClientReport = value);
          _loadAgingReport();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.mutedText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSummary(bool isDark, bool isAr) {
    double total = 0;
    for (var item in _reportData) { total += (item['balance'] as num?)?.toDouble() ?? 0; }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMiniKPI(
                  _isClientReport 
                    ? (isAr ? "إجمالي المستحقات" : "Total Receivable") 
                    : (isAr ? "إجمالي المطالبات" : "Total Payable"), 
                  total, 
                  primaryOrange,
                  isAr
                )
              ),
              Container(width: 1, height: 20, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
              Expanded(child: _buildMiniKPI(isAr ? "العدد" : "Count", _reportData.length.toDouble(), Colors.blue, isAr)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniKPI(String label, double value, Color color, bool isAr) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 9)),
        Text(
          "${value.toStringAsFixed(0)} ${isAr ? "ر.س" : "SAR"}", 
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildCompactAgingItem(bool isDark, Map<String, dynamic> item, bool isAr) {
    final balance = (item['balance'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: primaryOrange.withValues(alpha: 0.1),
            child: Text(
              (item['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('ID: ${item['id']}', style: TextStyle(color: context.mutedText, fontSize: 8)),
              ],
            ),
          ),
          Text(
            "${balance.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),
          ),
          const SizedBox(width: 4),
          Text(isAr ? "ر.س" : "SAR", style: TextStyle(color: context.mutedText, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 40, color: context.mutedText.withValues(alpha: 0.2)),
          Text(isAr ? "لا توجد بيانات" : "No Data", style: TextStyle(color: context.mutedText, fontSize: 12)),
        ],
      ),
    );
  }
}

