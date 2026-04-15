import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/reporting_service.dart';
import 'trial_balance_screen.dart';
import '../services/export_service.dart';
import '../services/pdf_service.dart';
import '../utils/tafqeet.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportingService _reportingService = ReportingService();
  final DatabaseHelper _db = DatabaseHelper();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedCostCenterId;
  List<Map<String, dynamic>> _costCenters = [];
  
  Map<String, double> _pnl = {'revenue': 0, 'expenses': 0, 'net_profit': 0};
  List<Map<String, dynamic>> _ccPerformance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final ccs = await _db.getCostCenters();
    setState(() => _costCenters = ccs);
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    
    final startStr = _startDate.toIso8601String().split('T')[0];
    final endStr = _endDate.toIso8601String().split('T')[0];
    
    final stats = await _reportingService.getPNLReport(startStr, endStr, costCenterId: _selectedCostCenterId);
    final performance = await _reportingService.getCostCenterPerformance(startStr, endStr);
    
    if (mounted) {
      setState(() {
        _pnl = stats;
        _ccPerformance = performance;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePdfExport() async {
    final List<Map<String, dynamic>> records = [
      {'label': tr('financial_reports.revenue_stat'), 'value': _pnl['revenue']},
      {'label': tr('financial_reports.expenses_stat'), 'value': _pnl['expenses']},
      {'label': tr('financial_reports.profit_stat'), 'value': _pnl['net_profit']},
    ];
    
    for (var cc in _ccPerformance) {
      records.add({'label': tr('financial_reports.center_net', args: [cc['name'] as String]), 'value': cc['profit']});
    }

    await _reportingService.generateFinancialPDF(
      title: tr('financial_reports.export_pdf_title'),
      period: tr('financial_reports.export_period', args: [_startDate.toIso8601String().split('T')[0], _endDate.toIso8601String().split('T')[0]]),
      records: records,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100 + context.headerSize), // 📉 Reduced from 140
        child: Container(
          padding: EdgeInsets.fromLTRB(context.cardPadding, 8, context.cardPadding, 0), // 📉 Reduced from 20/10/20/0
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('financial_reports.title'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
                      Text(tr('financial_reports.subtitle'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _handlePdfExport,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.picture_as_pdf_outlined, color: primaryOrange, size: context.iconSize - 6),
                        tooltip: tr('common.report'),
                      ),
                      const SizedBox(width: 4),
                      _buildCostCenterFilter(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4), // 📉 Reduced from 8
              TabBar(
                controller: _tabController,
                indicatorColor: primaryOrange,
                labelColor: primaryOrange,
                unselectedLabelColor: context.mutedText,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontSize: context.bodySize - 2, fontWeight: FontWeight.bold), // 📉 Reduced
                labelPadding: const EdgeInsets.symmetric(horizontal: 12), // 📉 Reduced
                tabs: [
                  Tab(text: tr('financial_reports.tab_profit'), height: 28),
                  Tab(text: tr('financial_reports.tab_centers'), height: 28),
                  Tab(text: tr('financial_reports.tab_balance'), height: 28),
                  Tab(text: "أعمار الديون", height: 28),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPNLTab(isMobile),
              _buildCostCentersTab(isMobile),
              _buildBalanceSheetTab(isMobile),
              _buildAgingTab(isMobile),
            ],
          ),
    );
  }

  Widget _buildCostCenterFilter() {
    return Container(
      height: 28, // 📉 Forced height
      padding: const EdgeInsets.symmetric(horizontal: 4), // 📉 Reduced
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4), // 📉 Sharper
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.15)),
      ),
      child: DropdownButton<String?>(
        value: _selectedCostCenterId,
        underline: const SizedBox(),
        isDense: true, // 📉 Compact
        dropdownColor: context.cardSurface,
        icon: Icon(Icons.keyboard_arrow_down, size: context.iconSize - 8),
        hint: Text(tr('financial_reports.tab_centers'), style: TextStyle(fontSize: context.bodySize - 3)),
        items: [
          DropdownMenuItem(value: null, child: Text(tr('common.all'), style: TextStyle(fontSize: context.bodySize - 3))),
          ..._costCenters.map((cc) => DropdownMenuItem(
            value: cc['id'] as String,
            child: Text(cc['name'] as String, style: TextStyle(fontSize: context.bodySize - 3)),
          )),
        ],
        onChanged: (val) {
          setState(() => _selectedCostCenterId = val);
          _refreshData();
        },
      ),
    );
  }

  Widget _buildPNLTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 20
      child: Column(
        children: [
          _buildModernStatsGrid(isMobile),
          const SizedBox(height: 16), // 📉 Reduced from 32
          _buildExpenseChart(isMobile),
          const SizedBox(height: 16), // 📉 Reduced from 32
          _buildDateRangePicker(),
        ],
      ),
    );
  }

  Widget _buildCostCentersTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('financial_reports.cost_centers_performance'), style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)),
          const SizedBox(height: 12), // 📉 Reduced from 20
          ..._ccPerformance.map((cc) => _buildCCRow(cc)).toList(),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetTab(bool isMobile) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _db.getFinancialPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryOrange));
        final fp = snapshot.data!;
        final totalAssets = (fp['total_assets'] as num?)?.toDouble() ?? 0;
        final totalLiabilities = (fp['total_liabilities'] as num?)?.toDouble() ?? 0;
        final totalRevenue = (fp['total_revenue'] as num?)?.toDouble() ?? 0;
        final totalExpenses = (fp['total_expenses'] as num?)?.toDouble() ?? 0;
        final equity = (fp['equity'] as num?)?.toDouble() ?? 0;
        final netProfit = totalRevenue - totalExpenses;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(context.sectionPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top KPIs
            Row(children: [
              Expanded(child: _buildBalanceKPI("إجمالي الأصول", totalAssets, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildBalanceKPI("إجمالي الخصوم", totalLiabilities, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildBalanceKPI("حقوق الملكية", equity, primaryOrange)),
              const SizedBox(width: 8),
              Expanded(child: _buildBalanceKPI("صافي الربح", netProfit, netProfit >= 0 ? Colors.green : Colors.red)),
            ]),
            const SizedBox(height: 16),
            
            // Balance Sheet Details
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildAccountSection("الأصول", fp['asset_accounts'] as List? ?? [], Colors.blue, totalAssets, "assets")),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [
                _buildAccountSection("الخصوم", fp['liability_accounts'] as List? ?? [], Colors.red, totalLiabilities, "liabilities"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryOrange.withValues(alpha: 0.2))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("حقوق الملكية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
                    Text("${equity.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 2, color: primaryOrange)),
                  ]),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            
            // Income Statement
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("قائمة الدخل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
              _buildCsvExportButton("income_statement", [
                ...fp['revenue_accounts'] as List? ?? [],
                ...fp['expense_accounts'] as List? ?? [],
              ]),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildAccountSection("الإيرادات", fp['revenue_accounts'] as List? ?? [], Colors.green, totalRevenue, "revenue")),
              const SizedBox(width: 12),
              Expanded(child: _buildAccountSection("المصروفات", fp['expense_accounts'] as List? ?? [], Colors.red, totalExpenses, "expenses")),
            ]),
            const SizedBox(height: 12),
            
            // Export
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrialBalanceScreen())),
                icon: Icon(Icons.list_alt, color: primaryOrange, size: 16),
                label: Text("ميزان المراجعة", style: TextStyle(color: primaryOrange, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: primaryOrange.withValues(alpha: 0.3))),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: _handlePdfExport,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.black87, size: 16),
                label: const Text("تصدير PDF", style: TextStyle(color: Colors.black87, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              )),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildBalanceKPI(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.mutedText, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        FittedBox(child: Text("${value.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color))),
      ]),
    );
  }

  Widget _buildAccountSection(String title, List accounts, Color color, double total, String exportKey) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: context.bodySize)),
          Row(children: [
            Text("${total.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: context.bodySize)),
            const SizedBox(width: 4),
            _buildCsvExportButton(exportKey, accounts),
          ]),
        ]),
        if (accounts.isNotEmpty) const Divider(height: 12),
        ...accounts.map((acc) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text("${acc['code']} ${acc['name']}", style: TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text("${((acc['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildCsvExportButton(String name, List data) {
    return IconButton(
      onPressed: () {
        ExportService.exportFinancialReport(name, data.map((e) => Map<String, dynamic>.from(e)).toList());
      },
      icon: Icon(Icons.file_download_outlined, size: 14, color: context.mutedText),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: "تصدير CSV",
    );
  }

  Widget _buildModernStatsGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 3,
      crossAxisSpacing: 8, // 📉 Reduced from 16
      mainAxisSpacing: 8, // 📉 Reduced from 16
      childAspectRatio: isMobile ? 3.0 : 2.5, // 📉 Adjusted for density
      children: [
        _buildGlassStatCard(tr('financial_reports.revenue_stat'), _pnl['revenue']!, Colors.green, Icons.trending_up),
        _buildGlassStatCard(tr('financial_reports.expenses_stat'), _pnl['expenses']!, Colors.redAccent, Icons.trending_down),
        _buildGlassStatCard(tr('financial_reports.profit_stat'), _pnl['net_profit']!, primaryOrange, Icons.account_balance_wallet_outlined),
      ],
    );
  }

  Widget _buildGlassStatCard(String label, double value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.4), // 📉 Lighter
        borderRadius: BorderRadius.circular(context.cardRadius / 2), // 📉 Sharper
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // 📉 Reduced from 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 4)), // 📉 Reduced
                Icon(icon, color: color.withValues(alpha: 0.5), size: context.iconSize - 6), // 📉 Reduced from 18
              ],
            ),
            const Spacer(),
            Text("${value.toStringAsFixed(0)}", style: TextStyle(fontSize: context.bodySize + 2, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Reduced from headerSize
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(bool isMobile) {
    return Container(
      height: 120, // 📉 Reduced from 160
      padding: const EdgeInsets.all(12), // 📉 Reduced from cardPadding
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4), // 📉 Reduced from 24
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1, // 📉 Balanced
            child: PieChart(
              PieChartData(
                sectionsSpace: 0.5, // 📉 Reduced
                centerSpaceRadius: 15, // 📉 Reduced from 20
                sections: _ccPerformance.map((cc) {
                  final expense = cc['expenses'] ?? 0.0;
                  return PieChartSectionData(
                    color: _getColor(cc['id']),
                    value: expense > 0 ? expense : 0.001,
                    radius: 25, // 📉 Reduced from 40
                    title: "",
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _ccPerformance.map((cc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.5), // 📉 Reduced
                child: Row(
                  children: [
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: _getColor(cc['id']), shape: BoxShape.circle)), // 📉 Reduced
                    const SizedBox(width: 4),
                    Expanded(child: Text(cc['name'], style: TextStyle(fontSize: context.bodySize - 4, color: context.textColor), overflow: TextOverflow.ellipsis)), // 📉 Reduced
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCCRow(Map<String, dynamic> cc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4), // 📉 Reduced from 8
      padding: const EdgeInsets.all(8), // 📉 Reduced from cardPadding
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4), // 📉 Reduced from 20
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cc['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)), // 📉 Reduced
              Text("Rev: ${cc['revenue']?.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 4)), // 📉 Reduced/Shortened
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${cc['profit']?.toStringAsFixed(0)}", style: TextStyle(color: (cc['profit'] ?? 0) >= 0 ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: context.bodySize)), // 📉 Reduced
              Text("Exp: ${cc['expenses']?.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 4)), // 📉 Reduced/Shortened
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = picked.end;
          });
          _refreshData();
        }
      },
      icon: Icon(Icons.date_range, size: context.iconSize - 8), // 📉 Reduced
      label: Text(tr('financial_reports.filter_period'), style: TextStyle(fontSize: context.bodySize - 3)),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryOrange,
        side: const BorderSide(color: primaryOrange, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 📉 Tightened
        minimumSize: const Size(60, 24), // 📉 Small button
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // 📉 Sharper
      ),
    );
  }

  Widget _buildAgingTab(bool isMobile) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportingService.getAgingReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryOrange));
        final agingData = snapshot.data!;
        if (agingData.isEmpty) {
          return Center(child: Text("لا توجد مديونيات متأخرة حالياً", style: TextStyle(color: context.mutedText)));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("تقرير أعمار الديون (AR Aging)", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...agingData.map((clientData) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(clientData['client'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${clientData['total']} ${tr('ceo.currency.sar')}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryOrange)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAgingBucket("1-30", clientData['0-30']),
                        _buildAgingBucket("31-60", clientData['31-60']),
                        _buildAgingBucket("61-90", clientData['61-90']),
                        _buildAgingBucket("90+", clientData['90+'], isRisk: true),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgingBucket(String label, double value, {bool isRisk = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.mutedText)),
        const SizedBox(height: 4),
        Text("${value.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isRisk && value > 0 ? Colors.red : context.textColor)),
      ],
    );
  }

  Color _getColor(String id) {
    if (id == 'CC_MGMT') return Colors.blue;
    if (id == 'CC_SALES') return Colors.teal;
    if (id == 'CC_OPS') return primaryOrange;
    return Colors.purple;
  }
}
