import 'package:flutter/material.dart';
import '../services/monitoring_service.dart';

class MonitoringControlScreen extends StatefulWidget {
  const MonitoringControlScreen({super.key});

  @override
  State<MonitoringControlScreen> createState() => _MonitoringControlScreenState();
}

class _MonitoringControlScreenState extends State<MonitoringControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MonitoringService _monitoringService = MonitoringService();
  String _searchQuery = '';
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _monitoringService.getMonitoringSummary();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Monitoring load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Real monitoring categories backed by Database checks
  final List<MonitoringSection> _sections = [
    MonitoringSection(
      title: 'الشيكات والتحصيل',
      titleEn: 'Cheques & Collections',
      icon: Icons.receipt_long,
      items: [
        MonitoringItem(id: 'cheque_due', nameAr: 'الشيكات المستحقة', nameEn: 'Due Cheques', icon: Icons.event, frequency: 'يومي'),
        MonitoringItem(id: 'bounced', nameAr: 'الشيكات المرتجعة', nameEn: 'Bounced Cheques', icon: Icons.error_outline, frequency: 'يومي'),
      ],
    ),
    MonitoringSection(
      title: 'الرواتب والموارد البشرية',
      titleEn: 'Payroll & HR',
      icon: Icons.people,
      items: [
        MonitoringItem(id: 'residency', nameAr: 'تجديد الإقامات والهويات', nameEn: 'Residency Renewal', icon: Icons.badge, frequency: 'أسبوعي'),
        MonitoringItem(id: 'leave_balance', nameAr: 'إجازات معلقة', nameEn: 'Pending Leaves', icon: Icons.event_busy, frequency: 'يومي'),
      ],
    ),
    MonitoringSection(
      title: 'المخزون والمستودعات',
      titleEn: 'Inventory & Warehouses',
      icon: Icons.inventory_2,
      items: [
        MonitoringItem(id: 'low_stock', nameAr: 'تنبيه نقص المخزون', nameEn: 'Low Stock Alert', icon: Icons.inventory, frequency: 'يومي'),
        MonitoringItem(id: 'material_expiry', nameAr: 'تواريخ انتهاء المواد', nameEn: 'Material Expiry', icon: Icons.calendar_today, frequency: 'يومي'),
      ],
    ),
    MonitoringSection(
      title: 'الصيانة والمعدات',
      titleEn: 'Maintenance & Equipment',
      icon: Icons.engineering,
      items: [
        MonitoringItem(id: 'maintenance', nameAr: 'الصيانة المعلقة المتأخرة', nameEn: 'Pending Maintenance', icon: Icons.build_circle, frequency: 'يومي'),
      ],
    ),
    MonitoringSection(
      title: 'المحاسبة والمالية',
      titleEn: 'Accounting & Finance',
      icon: Icons.account_balance,
      items: [
        MonitoringItem(id: 'invoice_audit_ref', nameAr: 'فواتير غير معتمدة (Draft)', nameEn: 'Unposted Invoices', icon: Icons.receipt, frequency: 'يومي'),
      ],
    ),
  ];



  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('الرقابة والتحكم والتذكير', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: brandColor,
          labelColor: brandColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabAlignment: TabAlignment.start,
          tabs: _sections.map((s) => Tab(
            icon: Icon(s.icon, size: 20),
            text: s.title,
          )).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: _MonitoringSearchDelegate(_sections, isDark));
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: brandColor))
        : TabBarView(
            controller: _tabController,
            children: _sections.map((section) {
              final filteredItems = _searchQuery.isEmpty
                  ? section.items
                  : section.items.where((item) =>
                      item.nameAr.contains(_searchQuery) ||
                      item.nameEn.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildMonitoringCard(item, isDark, brandColor);
                },
              );
            }).toList(),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSummaryDialog(context, isDark, brandColor),
        backgroundColor: brandColor,
        icon: const Icon(Icons.summarize, color: Colors.white),
        label: const Text('ملخص الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMonitoringCard(MonitoringItem item, bool isDark, Color brandColor) {
    final int issueCount = _stats[item.id] as int? ?? 0;
    final status = issueCount > 0 ? 'critical' : 'ok';
    final statusColor = status == 'ok' ? Colors.green : Colors.red;
    final statusText = status == 'ok' ? 'سليم ✓' : '$issueCount تنبيه ✗';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: brandColor, size: 24),
        ),
        title: Text(item.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.nameEn, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: isDark ? Colors.white30 : Colors.black26),
                const SizedBox(width: 4),
                Text(item.frequency, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black38)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        onTap: () => _showItemDetails(context, item, status, isDark, brandColor),
      ),
    );
  }

  void _showItemDetails(BuildContext context, MonitoringItem item, String status, bool isDark, Color brandColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(item.icon, color: brandColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(item.nameEn, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow('الحالة', status == 'ok' ? 'سليم' : status == 'warning' ? 'تحذير' : 'حرج', isDark),
              _detailRow('التكرار', item.frequency, isDark),
              _detailRow('آخر فحص', DateTime.now().toString().split(' ')[0], isDark),
              _detailRow('الفحص القادم', DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0], isDark),
              _detailRow('المسؤول', 'لم يُحدد', isDark),
              _detailRow('ملاحظات', 'لا توجد ملاحظات', isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('تم الفحص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildKPIRow() {
    int totalIssues = _stats.values.fold(0, (sum, val) => sum + (val as int? ?? 0));
    int totalAuditItems = _sections.fold(0, (sum, section) => sum + section.items.length);
    
    return Row(
      children: [
        Expanded(child: _buildKPI("إجمالي التنبيهات", totalIssues.toString(), Icons.notifications_active, Colors.redAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildKPI("بنود التدقيق", totalAuditItems.toString(), Icons.fact_check, Colors.blueAccent)),
      ],
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  void _showSummaryDialog(BuildContext context, bool isDark, Color brandColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ملخص الرقابة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildKPIRow(),
            const SizedBox(height: 16),
            ..._sections.map((s) {
              int sectionIssues = 0;
              for (var item in s.items) {
                sectionIssues += (_stats[item.id] as int? ?? 0);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.title, style: const TextStyle(fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (sectionIssues > 0 ? Colors.redAccent : brandColor).withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text('$sectionIssues', style: TextStyle(color: sectionIssues > 0 ? Colors.redAccent : brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: brandColor)),
          ),
        ],
      ),
    );
  }
}

class _MonitoringSearchDelegate extends SearchDelegate<String> {
  final List<MonitoringSection> sections;
  final bool isDark;

  _MonitoringSearchDelegate(this.sections, this.isDark);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () { query = ''; }),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final allItems = sections.expand((s) => s.items).toList();
    final filtered = query.isEmpty ? allItems : allItems.where((item) =>
      item.nameAr.contains(query) || item.nameEn.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return ListTile(
          leading: Icon(item.icon, color: const Color(0xFFFF6B00)),
          title: Text(item.nameAr),
          subtitle: Text(item.nameEn, style: const TextStyle(fontSize: 11)),
          onTap: () => close(context, item.id),
        );
      },
    );
  }
}

class MonitoringSection {
  final String title;
  final String titleEn;
  final IconData icon;
  final List<MonitoringItem> items;

  MonitoringSection({required this.title, required this.titleEn, required this.icon, required this.items});
}

class MonitoringItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final String frequency;

  MonitoringItem({required this.id, required this.nameAr, required this.nameEn, required this.icon, required this.frequency});
}
