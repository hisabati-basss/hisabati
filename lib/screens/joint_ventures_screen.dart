import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class JointVenturesScreen extends StatefulWidget {
  const JointVenturesScreen({super.key});

  @override
  State<JointVenturesScreen> createState() => _JointVenturesScreenState();
}

class _JointVenturesScreenState extends State<JointVenturesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _ventures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVentures();
  }

  Future<void> _loadVentures() async {
    setState(() => _isLoading = true);
    try {
      final data = await _db.getJointVentures();
      setState(() {
        _ventures = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("JointVentures Error: $e");
      setState(() => _isLoading = false);
    }
  }

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
        actions: [
          IconButton(onPressed: _loadVentures, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: brandColor))
          : _ventures.isEmpty
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
                final revenue = (v['total_revenue'] as num?)?.toDouble() ?? 0.0;
                final expenses = (v['total_expenses'] as num?)?.toDouble() ?? 0.0;
                final profit = revenue - expenses;
                final partners = v['partners'] as List<dynamic>? ?? [];

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
                                  Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(v['name_en'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text(v['status'] == 'active' ? 'نشط' : 'مكتمل', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      // Financial summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            _miniStat('رأس المال', (v['total_capital'] as num?)?.toDouble() ?? 0, Colors.blue, isDark),
                            _miniStat('المصروفات', expenses, Colors.red, isDark),
                            _miniStat('الإيرادات', revenue, Colors.green, isDark),
                            _miniStat('الربح/الخسارة', profit, profit >= 0 ? Colors.green : Colors.red, isDark),
                          ],
                        ),
                      ),

                      // Partners
                      if (partners.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                              const SizedBox(width: 8),
                              Text('الشركاء (${partners.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black45)),
                            ],
                          ),
                        ),
                        ...partners.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text(p['partner_name']?[0] ?? 'P', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 14))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p['partner_name'] ?? '', style: const TextStyle(fontSize: 13))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('${p['share_percentage']}%', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Text(_formatNum(profit * (p['share_percentage'] as num? ?? 0) / 100), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: profit >= 0 ? Colors.green : Colors.red)),
                            ],
                          ),
                        )),
                      ],
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
    final nameCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final capitalCtrl = TextEditingController();
    final List<Map<String, dynamic>> partners = [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Text('إضافة مشروع مشترك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: 'اسم المشروع (EN)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: capitalCtrl, decoration: InputDecoration(labelText: 'رأس المال الإجمالي', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الشركاء', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          partners.add({'name': '', 'share': 0.0});
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة شريك'),
                    )
                  ],
                ),
                ...partners.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: TextField(
                          onChanged: (v) => partners[idx]['name'] = v,
                          decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                        )),
                        const SizedBox(width: 8),
                        SizedBox(width: 80, child: TextField(
                          onChanged: (v) => partners[idx]['share'] = double.tryParse(v) ?? 0.0,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '%', border: OutlineInputBorder()),
                        )),
                        IconButton(onPressed: () => setStateDialog(() => partners.removeAt(idx)), icon: const Icon(Icons.delete, color: Colors.red))
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) return;
                      await _db.addJointVenture({
                        'name': nameCtrl.text,
                        'name_en': nameEnCtrl.text,
                        'total_capital': double.tryParse(capitalCtrl.text) ?? 0.0,
                        'status': 'active',
                      }, partners);
                      Navigator.pop(ctx);
                      _loadVentures();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: brandColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('حفظ المشروع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
