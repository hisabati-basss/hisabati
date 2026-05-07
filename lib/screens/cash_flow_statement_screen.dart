import 'package:flutter/material.dart';
import '../services/cash_flow_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/reporting_service.dart';

class CashFlowStatementScreen extends StatefulWidget {
  const CashFlowStatementScreen({super.key});

  @override
  State<CashFlowStatementScreen> createState() => _CashFlowStatementScreenState();
}

class _CashFlowStatementScreenState extends State<CashFlowStatementScreen> {
  final CashFlowService _cashFlowService = CashFlowService();
  
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  Map<String, List<CashFlowLine>> _data = {
    'operating': [],
    'investing': [],
    'financing': [],
  };
  
  double _openingCash = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _cashFlowService.getCashFlowStatement(_startDate, _endDate);
      setState(() {
        _openingCash = result['opening_cash'];
        _data['operating'] = result['operating'];
        _data['investing'] = result['investing'];
        _data['financing'] = result['financing'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading cash flow: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateRange(String type) {
    final now = DateTime.now();
    setState(() {
      if (type == 'monthly') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (type == 'quarterly') {
        int quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        _startDate = DateTime(now.year, quarterMonth, 1);
        _endDate = now;
      } else if (type == 'yearly') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
      }
    });
    _loadData();
  }

  double _sectionTotal(String section) {
    return _data[section]?.fold(0.0, (sum, line) => sum! + line.amount) ?? 0;
  }

  double get _netCashChange => _sectionTotal('operating') + _sectionTotal('investing') + _sectionTotal('financing');
  double get _closingCash => _openingCash + _netCashChange;

  final ReportingService _reportingService = ReportingService();
  List<Map<String, dynamic>> _predictions = [];

  Future<void> _loadPredictions() async {
    final preds = await _reportingService.getPredictedCashFlow(3);
    setState(() => _predictions = preds);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('قائمة التدفقات النقدية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph),
            onPressed: _loadPredictions,
            tooltip: 'توقع التدفقات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month),
            onSelected: _updateRange,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'monthly', child: Text('شهري')),
              const PopupMenuItem(value: 'quarterly', child: Text('ربع سنوي')),
              const PopupMenuItem(value: 'yearly', child: Text('سنوي')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('جاري تصدير PDF...'), backgroundColor: brandColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: brandColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF983F)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   const Text('Cash Flow Statement', style: TextStyle(color: Colors.white70, fontSize: 12)),
                   const Text('قائمة التدفقات النقدية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                   const SizedBox(height: 8),
                   Text('${_startDate.year}/${_startDate.month} — ${_endDate.year}/${_endDate.month}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                   const SizedBox(height: 16),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _headerStat('الرصيد الافتتاحي', _openingCash),
                      _headerStat('صافي التغيير', _netCashChange),
                      _headerStat('الرصيد الختامي', _closingCash),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Predictions Section (If available)
            if (_predictions.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        const Text("تنبؤات التدفق النقدي المستقبلي (AI)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._predictions.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("شهر ${p['month']}", style: const TextStyle(fontSize: 12)),
                          Text("${_formatNumber(p['predicted_revenue'])} ${tr('common.currency_symbol')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Operating Activities
            _buildSection('الأنشطة التشغيلية', 'Operating Activities', Icons.settings, _data['operating']!, isDark, brandColor),
            const SizedBox(height: 12),


            // Investing Activities
            _buildSection('الأنشطة الاستثمارية', 'Investing Activities', Icons.trending_up, _data['investing']!, isDark, brandColor),
            const SizedBox(height: 12),

            // Financing Activities
            _buildSection('الأنشطة التمويلية', 'Financing Activities', Icons.account_balance, _data['financing']!, isDark, brandColor),
            const SizedBox(height: 20),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                children: [
                  _summaryRow('صافي التشغيل', _sectionTotal('operating'), isDark),
                  _summaryRow('صافي الاستثمار', _sectionTotal('investing'), isDark),
                  _summaryRow('صافي التمويل', _sectionTotal('financing'), isDark),
                  const Divider(height: 24),
                  _summaryRow('صافي التغيير في النقد', _netCashChange, isDark, isBold: true),
                  const SizedBox(height: 8),
                  _summaryRow('النقد — بداية الفترة', _openingCash, isDark),
                  _summaryRow('النقد — نهاية الفترة', _closingCash, isDark, isBold: true, color: brandColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, double value) {
    return Column(
      children: [
        Text(_formatNumber(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSection(String titleAr, String titleEn, IconData icon, List<CashFlowLine> lines, bool isDark, Color brandColor) {
    final total = lines.fold(0.0, (sum, line) => sum + line.amount);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: brandColor, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(titleEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black26)),
                  ],
                ),
                const Spacer(),
                Text(_formatNumber(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: total >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.nameAr, style: const TextStyle(fontSize: 13)),
                      Text(line.nameEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2))),

                    ],
                  ),
                ),
                Text(
                  _formatNumber(line.amount),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: line.amount >= 0 ? Colors.green.shade400 : Colors.red.shade400),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, bool isDark, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white70 : Colors.black54)),
          Text(_formatNumber(value), style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? (value >= 0 ? Colors.green : Colors.red))),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }
}


