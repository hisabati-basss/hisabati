import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../../services/database_helper.dart';
import '../../../theme/app_theme_extension.dart';

class PerformanceTab extends StatefulWidget {
  final String employeeId;
  const PerformanceTab({super.key, required this.employeeId});

  @override
  State<PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends State<PerformanceTab> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final db = await _db.database;
    final res = await db.query(
      'performance_reviews',
      where: 'employee_id = ? AND is_deleted = 0',
      whereArgs: [widget.employeeId],
      orderBy: 'review_date ASC',
    );
    setState(() {
      _reviews = res;
      _isLoading = false;
    });
  }

  Future<void> _addReview() async {
    int rating = 5;
    String feedback = "";

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة تقييم أداء'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المدير',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => feedback = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final db = await _db.database;
                final nowStr = DateTime.now().toIso8601String();
                await db.insert('performance_reviews', {
                  'id': const Uuid().v4(),
                  'employee_id': widget.employeeId,
                  'review_date': nowStr,
                  'rating': rating,
                  'manager_feedback': feedback,
                  'created_at': nowStr,
                  'updated_at': nowStr,
                  'sync_status': 0,
                  'is_deleted': 0,
                });
                Navigator.pop(ctx);
                _loadReviews();
              },
              child: const Text('حفظ التقييم'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("رسم بياني لتطور الأداء", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addReview,
                icon: const Icon(Icons.add_chart, size: 18),
                label: const Text("تقييم جديد"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 24),
          const Text("سجل التقييمات السابقة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
             _buildEmptyState()
          else
            ..._reviews.map((r) => _buildReviewCard(r)).toList(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_reviews.length < 2) {
      return Container(
        height: 150,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("هناك حاجة لتقييمين على الأقل لرسم المخطط", style: TextStyle(color: Colors.white24, fontSize: 12))),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _reviews.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value['rating'] as int).toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.amber,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.amber.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    int rating = r['rating'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                )),
              ),
              Text(
                r['review_date'].toString().split('T').first,
                style: TextStyle(color: context.mutedText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(r['manager_feedback'] ?? 'بدون ملاحظات', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text("لا توجد تقييمات مسجلة لهذا الموظف", style: TextStyle(color: context.mutedText)),
      ),
    );
  }
}
