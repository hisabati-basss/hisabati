import 'package:flutter/material.dart';

class JointVenturesScreen extends StatefulWidget {
  const JointVenturesScreen({super.key});

  @override
  State<JointVenturesScreen> createState() => _JointVenturesScreenState();
}

class _JointVenturesScreenState extends State<JointVenturesScreen> {
  final List<JointVenture> _ventures = [
    JointVenture(
      name: 'مشروع برج الخليج',
      nameEn: 'Gulf Tower Project',
      partners: [
        Partner(name: 'شركة حساباتي', share: 60),
        Partner(name: 'مجموعة الراشد', share: 25),
        Partner(name: 'مؤسسة الخليج', share: 15),
      ],
      totalCapital: 5000000,
      totalExpenses: 2300000,
      totalRevenue: 1800000,
      status: 'active',
    ),
    JointVenture(
      name: 'مشروع المجمع التجاري',
      nameEn: 'Commercial Complex Project',
      partners: [
        Partner(name: 'شركة حساباتي', share: 50),
        Partner(name: 'شركة البناء الحديث', share: 50),
      ],
      totalCapital: 3000000,
      totalExpenses: 1500000,
      totalRevenue: 2200000,
      status: 'active',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('المشاريع المشتركة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _ventures.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handshake, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                Text('لا توجد مشاريع مشتركة', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26)),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ventures.length,
              itemBuilder: (context, index) {
                final v = _ventures[index];
                final profit = v.totalRevenue - v.totalExpenses;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [brandColor.withValues(alpha: 0.1), Colors.transparent]),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.handshake, color: brandColor, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(v.nameEn, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Text('نشط', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      // Financial summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            _miniStat('رأس المال', v.totalCapital, Colors.blue, isDark),
                            _miniStat('المصروفات', v.totalExpenses, Colors.red, isDark),
                            _miniStat('الإيرادات', v.totalRevenue, Colors.green, isDark),
                            _miniStat('الربح/الخسارة', profit, profit >= 0 ? Colors.green : Colors.red, isDark),
                          ],
                        ),
                      ),

                      // Partners
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(width: 8),
                            Text('الشركاء (${v.partners.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45)),
                          ],
                        ),
                      ),
                      ...v.partners.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text(p.name[0], style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 14))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${p.share}%', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Text(_formatNum(profit * p.share / 100), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: profit >= 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVentureDialog(context, isDark, brandColor),
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مشروع جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(_formatNum(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : Colors.black26)),
        ],
      ),
    );
  }

  String _formatNum(double v) {
    final prefix = v < 0 ? '-' : '';
    final abs = v.abs();
    if (abs >= 1000000) return '$prefix${(abs / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '$prefix${(abs / 1000).toStringAsFixed(0)}K';
    return '$prefix${abs.toStringAsFixed(0)}';
  }

  void _showAddVentureDialog(BuildContext context, bool isDark, Color brandColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('إضافة مشروع مشترك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'رأس المال الإجمالي', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'عدد الشركاء', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: brandColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('إضافة المشروع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JointVenture {
  final String name, nameEn, status;
  final List<Partner> partners;
  final double totalCapital, totalExpenses, totalRevenue;
  JointVenture({required this.name, required this.nameEn, required this.partners, required this.totalCapital, required this.totalExpenses, required this.totalRevenue, required this.status});
}

class Partner {
  final String name;
  final double share;
  Partner({required this.name, required this.share});
}
