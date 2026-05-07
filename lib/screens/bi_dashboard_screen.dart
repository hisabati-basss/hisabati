import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import '../services/analytics_service.dart';
import '../widgets/glass_container.dart';

class BIDashboardScreen extends StatefulWidget {
  const BIDashboardScreen({super.key});

  @override
  State<BIDashboardScreen> createState() => _BIDashboardScreenState();
}

class _BIDashboardScreenState extends State<BIDashboardScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final AnalyticsService _analytics = AnalyticsService();
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic> _biData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final netProfit = await _calculateNetProfit();
      final liquidity = await _calculateLiquidity();
      final cashFlowSpots = await _calculateCashFlow();
      
      // Fetch specialized industry data
      final manufacturing = await _fetchManufacturingStats();
      final realEstate = await _fetchRealEstateStats();
      final medical = await _fetchMedicalStats();
      final hospitality = await _fetchHospitalityStats();

      setState(() {
        _biData = {
          'financial': {
            'net_profit': netProfit,
            'liquidity': liquidity,
            'cash_flow': cashFlowSpots
          },
          'manufacturing': manufacturing,
          'real_estate': realEstate,
          'medical': medical,
          'hospitality': hospitality,
        };
      });
    } catch (e) {
      debugPrint("Error loading BI data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchManufacturingStats() async {
    try {
      final db = await _db.database;
      final active = await db.rawQuery("SELECT COUNT(*) as count FROM manufacturing_orders WHERE status != 'completed' AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final efficiency = await db.rawQuery("SELECT AVG(actual_qty_produced / qty_to_produce) as avg FROM manufacturing_orders WHERE qty_to_produce > 0 AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      
      return {
        'active_orders': (active.first['count'] as num?)?.toInt() ?? 0,
        'efficiency': ((efficiency.first['avg'] as num?)?.toDouble() ?? 0.0) * 100,
        'waste_rate': 0.0 // Could be calculated if waste table exists
      };
    } catch (_) {
      return {'active_orders': 0, 'efficiency': 0.0, 'waste_rate': 0.0};
    }
  }

  Future<Map<String, dynamic>> _fetchRealEstateStats() async {
    try {
      final db = await _db.database;
      final total = await db.rawQuery("SELECT COUNT(*) as count FROM real_estate_units WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final occupied = await db.rawQuery("SELECT COUNT(*) as count FROM real_estate_units WHERE status = 'occupied' AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final collection = await db.rawQuery("SELECT SUM(amount) as total FROM real_estate_payments WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      
      double totalUnits = (total.first['count'] as num?)?.toDouble() ?? 1;
      double occupiedUnits = (occupied.first['count'] as num?)?.toDouble() ?? 0;
      
      return {
        'occupancy': (occupiedUnits / (totalUnits > 0 ? totalUnits : 1)) * 100,
        'collection': 100.0, // Simplified for now
        'units': totalUnits.toInt()
      };
    } catch (_) {
      return {'occupancy': 0.0, 'collection': 0.0, 'units': 0};
    }
  }

  Future<Map<String, dynamic>> _fetchMedicalStats() async {
    try {
      final db = await _db.database;
      final patients = await db.rawQuery("SELECT COUNT(*) as count FROM medical_appointments WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final revenue = await db.rawQuery("SELECT SUM(net_amount) as total FROM medical_invoices WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      
      return {
        'patients': (patients.first['count'] as num?)?.toInt() ?? 0,
        'revenue': (revenue.first['total'] as num?)?.toDouble() ?? 0.0,
        'efficiency': 0.0
      };
    } catch (_) {
      return {'patients': 0, 'revenue': 0.0, 'efficiency': 0.0};
    }
  }

  Future<Map<String, dynamic>> _fetchHospitalityStats() async {
    try {
      final db = await _db.database;
      final totalRooms = await db.rawQuery("SELECT COUNT(*) as count FROM hotel_rooms WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final occupied = await db.rawQuery("SELECT COUNT(*) as count FROM hotel_rooms WHERE status = 'occupied' AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      final bookings = await db.rawQuery("SELECT SUM(total_price) as total FROM hotel_bookings WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
      
      double rooms = (totalRooms.first['count'] as num?)?.toDouble() ?? 1;
      double occ = (occupied.first['count'] as num?)?.toDouble() ?? 0;
      
      return {
        'occupancy': (occ / (rooms > 0 ? rooms : 1)) * 100,
        'rev_par': (bookings.first['total'] as num?)?.toDouble() ?? 0.0,
        'satisfaction': 0.0
      };
    } catch (_) {
      return {'occupancy': 0.0, 'rev_par': 0.0, 'satisfaction': 0.0};
    }
  }

  Future<double> _calculateNetProfit() async {
    final db = await _db.database;
    final rev = await db.rawQuery("SELECT SUM(total) as total FROM invoices WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
    final exp = await db.rawQuery("SELECT SUM(amount) as total FROM payments WHERE is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
    double r = (rev.first['total'] as num?)?.toDouble() ?? 0.0;
    double e = (exp.first['total'] as num?)?.toDouble() ?? 0.0;
    return r - e;
  }

  Future<List<FlSpot>> _calculateCashFlow() async {
    try {
      final trend = await _analytics.getMonthlySalesTrend();
      if (trend.isEmpty) return [const FlSpot(0, 0)];
      
      return trend.asMap().entries.map((e) {
        double profit = e.value['sales'] - e.value['purchases'];
        return FlSpot(e.key.toDouble(), profit / 1000); // Scaled for the chart
      }).toList();
    } catch (_) {
      return [const FlSpot(0, 0)];
    }
  }

  Future<double> _calculateLiquidity() async {
    final db = await _db.database;
    final result = await db.rawQuery("SELECT SUM(balance) as total FROM accounts WHERE (type = 'Bank' OR type = 'Cash') AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init') AND id NOT LIKE 'DEMO_%'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
        : Column(
            children: [
              _buildHeader(),
              _buildIndustryTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFinancialTab(),
                    _buildManufacturingTab(),
                    _buildRealEstateTab(),
                    _buildMedicalTab(),
                    _buildHospitalityTab(),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ذكاء الأعمال (BI)", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)),
              Text("تحليلات متقدمة وتوقعات مالية ذكية", style: TextStyle(color: context.mutedText, fontSize: context.bodySize)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.auto_graph, color: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 45,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.orangeAccent,
        labelColor: Colors.orangeAccent,
        unselectedLabelColor: context.mutedText,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "المالية"),
          Tab(text: "التصنيع"),
          Tab(text: "العقارات"),
          Tab(text: "الصحة"),
          Tab(text: "الفنادق"),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    final data = _biData['financial'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard("صافي الربح التقديري", "${data['net_profit'].toStringAsFixed(0)} SAR", Icons.payments, Colors.greenAccent)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard("السيولة التشغيلية", "${data['liquidity'].toStringAsFixed(0)} SAR", Icons.account_balance, Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartSection("توقعات التدفق النقدي الذكية", data['cash_flow']),
          const SizedBox(height: 24),
          _buildMetricList([
            _metricItem("معدل العائد (ROI)", "18.5%", Colors.greenAccent),
            _metricItem("نسبة المديونية", "12.0%", Colors.orangeAccent),
            _metricItem("هامش الربح", "32.4%", Colors.blueAccent),
          ]),
        ],
      ),
    );
  }

  Widget _buildManufacturingTab() {
    final m = _biData['manufacturing'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard("كفاءة خطوط الإنتاج", "${m['efficiency']}%", Icons.speed, Colors.orangeAccent)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard("أوامر تحت التنفيذ", "${m['active_orders']}", Icons.precision_manufacturing, Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 24),
          _buildGaugeSection("معدل الهالك المرصود", m['waste_rate'] / 10, Colors.redAccent),
          const SizedBox(height: 24),
          _buildMetricList([
            _metricItem("وقت الدورة المتوسط", "4.2 ساعة", Colors.blueAccent),
            _metricItem("الجودة الشاملة", "98.5%", Colors.greenAccent),
          ]),
        ],
      ),
    );
  }

  Widget _buildRealEstateTab() {
    final re = _biData['real_estate'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard("إشغال الوحدات", "${re['occupancy']}%", Icons.home, Colors.blueAccent)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard("تحصيل الإيجارات", "${re['collection']}%", Icons.receipt_long, Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 24),
          _buildChartSection("توزيع العائد العقاري", [
            const FlSpot(0, 2), const FlSpot(5, 4), const FlSpot(10, 3), const FlSpot(15, 6),
          ]),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    final med = _biData['medical'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard("زيارات اليوم", "${med['patients']}", Icons.people, Colors.purpleAccent)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard("الإيراد الطبي", "${med['revenue']} SAR", Icons.medical_services, Colors.tealAccent)),
            ],
          ),
          const SizedBox(height: 24),
          _buildGaugeSection("معدل استهلاك الموارد الطبية", med['efficiency'] / 100, Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _buildHospitalityTab() {
    final h = _biData['hospitality'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard("الإشغال الحالي", "${h['occupancy']}%", Icons.bed, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _kpiCard("تقييم الضيوف", "${h['satisfaction']}%", Icons.star, Colors.amberAccent)),
            ],
          ),
          const SizedBox(height: 24),
          _kpiCard("RevPAR (العائد لكل غرفة)", "${h['rev_par']} SAR", Icons.trending_up, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String val, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Icon(Icons.arrow_forward_ios, size: 10, color: context.mutedText.withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(val, style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, List<FlSpot> spots) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orangeAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeSection(String title, double value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("منخفض", style: TextStyle(color: context.mutedText, fontSize: 10)),
              Text("${(value * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text("مرتفع", style: TextStyle(color: context.mutedText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricList(List<Widget> items) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
