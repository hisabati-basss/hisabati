import 'package:flutter/material.dart';
import 'package:hisabati_app/services/database_helper.dart';

class CostAccountingScreen extends StatefulWidget {
  const CostAccountingScreen({super.key});

  @override
  State<CostAccountingScreen> createState() => _CostAccountingScreenState();
}

class _CostAccountingScreenState extends State<CostAccountingScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _costCenters = [];

  final List<Color> _colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.cyan, Colors.teal, Colors.pink];

  @override
  void initState() {
    super.initState();
    _loadCostCenters();
  }

  Future<void> _loadCostCenters() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper().database;
      final results = await db.query('cost_centers', where: 'is_deleted = 0');
      if (mounted) {
        setState(() {
          _costCenters = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _costCenters = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);
    final tabs = ['مراكز التكلفة', 'تحليل التكاليف', 'الربحية'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('محاسبة التكاليف', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCostCenters, tooltip: 'تحديث'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandColor))
          : Column(
              children: [
                // Tab selector
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tabs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tabs[index], style: TextStyle(
                          color: _selectedTab == index ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                        selected: _selectedTab == index,
                        selectedColor: brandColor,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        onSelected: (_) => setState(() => _selectedTab = index),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Content
                Expanded(
                  child: _costCenters.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_tree_outlined, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 12),
                              Text('لا توجد مراكز تكلفة', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('أضف مراكز تكلفة من شاشة المشاريع', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black12, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _costCenters.length,
                          itemBuilder: (context, index) {
                            final cc = _costCenters[index];
                            final color = _colors[index % _colors.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border(left: BorderSide(color: color, width: 4)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.account_tree, color: color, size: 20),
                                ),
                                title: Text(cc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Text(cc['code']?.toString() ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
