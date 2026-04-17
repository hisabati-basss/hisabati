import 'package:flutter/material.dart';

class InvoiceAuditScreen extends StatefulWidget {
  const InvoiceAuditScreen({super.key});

  @override
  State<InvoiceAuditScreen> createState() => _InvoiceAuditScreenState();
}

class _InvoiceAuditScreenState extends State<InvoiceAuditScreen> {
  int _selectedTab = 0;

  final List<AuditAlert> _alerts = [
    AuditAlert(type: 'duplicate', title: 'فاتورة مكررة محتملة', titleEn: 'Possible Duplicate Invoice', details: 'فاتورة #1052 و #1089 نفس المورد ونفس المبلغ', severity: 'high', icon: Icons.copy_all),
    AuditAlert(type: 'anomaly', title: 'قيمة غير منطقية', titleEn: 'Illogical Value', details: 'فاتورة #1103 بقيمة 500,000 ر.س — أعلى 300% من المتوسط', severity: 'high', icon: Icons.warning_amber),
    AuditAlert(type: 'post_edit', title: 'تعديل بعد الاعتماد', titleEn: 'Post-Approval Edit', details: 'فاتورة #980 تم تعديلها بعد 3 أيام من الاعتماد بواسطة مستخدم: أحمد', severity: 'critical', icon: Icons.edit_notifications),
    AuditAlert(type: 'missing', title: 'بيانات ناقصة', titleEn: 'Missing Data', details: '12 فاتورة بدون رقم ضريبي للمورد', severity: 'medium', icon: Icons.error_outline),
    AuditAlert(type: 'price', title: 'تغيير سعر مفاجئ', titleEn: 'Sudden Price Change', details: 'مادة "حديد تسليح" ارتفعت 45% في آخر طلبية', severity: 'medium', icon: Icons.trending_up),
    AuditAlert(type: 'overdue', title: 'فواتير متأخرة السداد', titleEn: 'Overdue Invoices', details: '8 فواتير تجاوزت 90 يوم بدون سداد — إجمالي 125,000 ر.س', severity: 'high', icon: Icons.timer_off),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);
    
    final tabs = ['التنبيهات', 'الفواتير المكررة', 'تقييم الموردين', 'سجل التدقيق'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('تدقيق الفواتير', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('جاري تشغيل فحص التدقيق الشامل...'),
                  backgroundColor: brandColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            tooltip: 'تشغيل الفحص الشامل',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards row
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _summaryCard('التنبيهات', '${_alerts.length}', Icons.notifications_active, Colors.red, isDark),
                _summaryCard('مكررة', '2', Icons.copy_all, Colors.orange, isDark),
                _summaryCard('متأخرة', '8', Icons.timer_off, Colors.purple, isDark),
                _summaryCard('نظيفة', '245', Icons.check_circle, Colors.green, isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                  onSelected: (selected) => setState(() => _selectedTab = index),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Alert list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return _buildAlertCard(alert, isDark, brandColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AuditAlert alert, bool isDark, Color brandColor) {
    final severityColor = alert.severity == 'critical' ? Colors.red : alert.severity == 'high' ? Colors.orange : Colors.yellow.shade700;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(alert.icon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(alert.titleEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black26)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  alert.severity == 'critical' ? 'حرج' : alert.severity == 'high' ? 'مرتفع' : 'متوسط',
                  style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(alert.details, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, height: 1.4)),
          const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAlertDetails(context, alert, isDark),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('عرض التفاصيل', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandColor,
                      side: BorderSide(color: brandColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _alerts.remove(alert));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ تم معالجة: ${alert.title}'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('تم المعالجة', style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  void _showAlertDetails(BuildContext context, AuditAlert alert, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(alert.icon, color: const Color(0xFFFF6B00), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(alert.titleEn, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('التفاصيل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 8),
            Text(alert.details, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black45, height: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('النوع: ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                Text(alert.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text('الخطورة: ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                Text(alert.severity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuditAlert {
  final String type;
  final String title;
  final String titleEn;
  final String details;
  final String severity;
  final IconData icon;

  AuditAlert({required this.type, required this.title, required this.titleEn, required this.details, required this.severity, required this.icon});
}
