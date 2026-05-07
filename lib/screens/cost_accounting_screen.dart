import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class CostAccountingScreen extends StatefulWidget {
  const CostAccountingScreen({super.key});

  @override
  State<CostAccountingScreen> createState() => _CostAccountingScreenState();
}

class _CostAccountingScreenState extends State<CostAccountingScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _costCenters = [];
  final _db = DatabaseHelper();
  late TabController _tabController;

  final List<Color> _chartColors = [
    const Color(0xFF007AFF), // iOS Blue
    const Color(0xFF34C759), // iOS Green
    const Color(0xFFFF9500), // iOS Orange
    const Color(0xFFFF2D55), // iOS Pink
    const Color(0xFFAF52DE), // iOS Purple
    const Color(0xFF5856D6), // iOS Indigo
    const Color(0xFF5AC8FA), // iOS Teal
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
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
      final db = await _db.database;
      final centers = await _fetchCenters(db);
      
      if (mounted) {
        setState(() {
          _costCenters = centers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Cost Center Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCenters(dynamic db) async {
    return await db.rawQuery('''
      SELECT cc.*, 
        COALESCE((SELECT SUM(jl.debit - jl.credit) 
                  FROM journal_entry_lines jl 
                  JOIN accounts a ON jl.account_id = a.id 
                  JOIN journal_entries je ON jl.entry_id = je.id
                  WHERE jl.cost_center_id = cc.id AND a.type = 'expense' 
                    AND je.is_deleted = 0 
                    AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
                    AND je.id NOT LIKE 'DEMO_%'), 0) as total_expenses,
        COALESCE((SELECT SUM(jl.credit - jl.debit) 
                  FROM journal_entry_lines jl 
                  JOIN accounts a ON jl.account_id = a.id 
                  JOIN journal_entries je ON jl.entry_id = je.id
                  WHERE jl.cost_center_id = cc.id AND a.type = 'revenue' 
                    AND je.is_deleted = 0 
                    AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
                    AND je.id NOT LIKE 'DEMO_%'), 0) as total_revenue
      FROM cost_centers cc
      WHERE cc.is_deleted = 0
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildPremiumHeader(isDark),
          _buildGlassTabSelector(isDark, brandColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: brandColor, strokeWidth: 2))
                : _costCenters.isEmpty
                    ? _buildEmptyState(isDark)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _buildCurrentTabContent(isDark, brandColor),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEditCostCenterDialog,
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مركز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderIcon(Icons.refresh_rounded, isDark, onTap: _loadData),
          Column(
            children: [
              Text(
                'محاسبة التكاليف',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40, height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          _buildHeaderIcon(Icons.more_horiz_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white60 : Colors.black54, size: 20),
      ),
    );
  }

  Widget _buildGlassTabSelector(bool isDark, Color brandColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), // Increased horizontal margin to make it more centered and compact
      height: 42, // Slightly shorter
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(21),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: brandColor,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(color: brandColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Make indicator cover the full tab width
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: const [
          Tab(text: 'مراكز التكلفة'),
          Tab(text: 'تحليل البيانات'),
          Tab(text: 'الربحية'),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent(bool isDark, Color brandColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _selectedTab == 0
          ? _buildCostCentersList(isDark)
          : _selectedTab == 1
              ? _buildCostAnalysis(isDark)
              : _buildProfitabilityView(isDark),
    );
  }

  Widget _buildCostCentersList(bool isDark) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _costCenters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8), // Smaller gap
      itemBuilder: (context, index) {
        final cc = _costCenters[index];
        final color = _chartColors[index % _chartColors.length];
        double revenue = (cc['total_revenue'] as num).toDouble();
        double expenses = (cc['total_expenses'] as num).toDouble();
        double profit = revenue - expenses;

        return _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Compact padding
          child: Row(
            children: [
              Container(
                width: 36, height: 36, // Smaller icon
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), // Smaller font
                    const SizedBox(height: 2),
                    Text('كود: ${cc['code'] ?? '---'}', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            profit.toStringAsFixed(0),
                            style: TextStyle(
                              color: profit >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(profit >= 0 ? 'صافي ربح' : 'عجز مالي', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54, size: 18),
                        onSelected: (val) async {
                          if (val == 'edit') {
                            _showAddEditCostCenterDialog(center: cc);
                          } else if (val == 'delete') {
                            final db = await _db.database;
                            await db.update('cost_centers', {'is_deleted': 1}, where: 'id = ?', whereArgs: [cc['id']]);
                            _loadData();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 16), SizedBox(width: 8), Text('تعديل', style: TextStyle(color: Colors.blue))])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCostAnalysis(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 180, // Slightly smaller chart
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: _costCenters.map((cc) {
                final index = _costCenters.indexOf(cc);
                final color = _chartColors[index % _chartColors.length];
                final double value = (cc['total_expenses'] as num).toDouble();
                return PieChartSectionData(
                  color: color,
                  value: value > 0 ? value : 1,
                  title: '${((value / _getTotalExpenses()) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  badgeWidget: _buildChartBadge(cc['name']?.toString() ?? '', color),
                  badgePositionPercentageOffset: 1.4,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2, // More compact aspect ratio
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _costCenters.length,
            itemBuilder: (context, index) {
              final cc = _costCenters[index];
              final color = _chartColors[index % _chartColors.length];
              return _buildGlassCard(
                isDark: isDark,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                          Text('${cc['total_expenses']}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  double _getTotalExpenses() {
    double total = _costCenters.fold<double>(0.0, (sum, cc) => sum + (cc['total_expenses'] as num).toDouble());
    return total > 0 ? total : 1;
  }

  Widget _buildProfitabilityView(bool isDark) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _costCenters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final cc = _costCenters[index];
        final color = _chartColors[index % _chartColors.length];
        double revenue = (cc['total_revenue'] as num).toDouble();
        double expenses = (cc['total_expenses'] as num).toDouble();
        double ratio = revenue > 0 ? (expenses / revenue) : 0;

        return _buildGlassCard(
          isDark: isDark,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('%${(ratio * 100).toStringAsFixed(1)} كفاءة', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(3))),
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    height: 6,
                    width: MediaQuery.of(context).size.width * (ratio > 1 ? 1 : ratio),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatPill('إيرادات', revenue.toString(), const Color(0xFF34C759), isDark),
                  const SizedBox(width: 12),
                  _buildStatPill('مصاريف', expenses.toString(), const Color(0xFFFF3B30), isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 20),
          Text('لا توجد بيانات متاحة حالياً', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddEditCostCenterDialog({Map<String, dynamic>? center}) {
    final nameCtrl = TextEditingController(text: center?['name']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: center?['code']?.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(center == null ? "إضافة مركز تكلفة" : "تعديل مركز تكلفة", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "اسم المركز",
                  prefixIcon: const Icon(Icons.account_tree),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: "الكود",
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                
                final db = await _db.database;
                final Map<String, dynamic> data = {
                  'name': nameCtrl.text,
                  'code': codeCtrl.text,
                  'updated_at': DateTime.now().toIso8601String(),
                };

                if (center == null) {
                  data['id'] = 'CC_${DateTime.now().millisecondsSinceEpoch}';
                  data['created_at'] = DateTime.now().toIso8601String();
                  data['is_deleted'] = 0;
                  await db.insert('cost_centers', data);
                } else {
                  await db.update('cost_centers', data, where: 'id = ?', whereArgs: [center['id']]);
                }
                
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(center == null ? "تمت إضافة المركز بنجاح" : "تم تعديل المركز بنجاح"), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(center == null ? "إضافة" : "حفظ التعديلات"),
            ),
          ],
        ),
      ),
    );
  }
}
