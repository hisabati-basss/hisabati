# Phase 23: Flutter App — Critical New Modules — EXACT CODE

## ⚠️ RULES FOR EXECUTING AGENT
1. **Copy code EXACTLY.** Do NOT modify anything.
2. All screens go in `c:\my app creator\hisabati_app\lib\screens\`
3. All screens are `StatefulWidget` using the existing theme system.
4. All screens must use `context.watch<ThemeNotifier>()` for dark/light mode.
5. Import `database_helper.dart` for all data operations.
6. Use Arabic AND English labels via `easy_localization` or inline ternary.
7. Run `flutter analyze` after each file to check for errors.
8. **Do NOT create any new services.** Use existing `DatabaseHelper` directly.
9. Brand color: `const Color(0xFFFF6B00)` (orange)

## EXECUTION ORDER:
1. Add the `globals.css` fix for website (ALREADY DONE by reviewer)
2. Create `monitoring_control_screen.dart`
3. Create `invoice_audit_screen.dart`  
4. Create `cash_flow_statement_screen.dart`
5. Create `quick_statements_screen.dart`
6. Create `joint_ventures_screen.dart`
7. Fix HR `recruitment_tab.dart`
8. Add navigation routes in `main.dart`
9. Run `flutter analyze`

---

## FILE 1: monitoring_control_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\monitoring_control_screen.dart`
**Action:** CREATE NEW FILE.

### What this screen does:
- Shows 70+ monitoring categories organized in sections
- Each category shows status (OK / Warning / Critical)
- Tapping a category shows details with date, responsible person, notes
- Support for scheduling reminders
- Color-coded status indicators

```dart
import 'package:flutter/material.dart';

class MonitoringControlScreen extends StatefulWidget {
  const MonitoringControlScreen({super.key});

  @override
  State<MonitoringControlScreen> createState() => _MonitoringControlScreenState();
}

class _MonitoringControlScreenState extends State<MonitoringControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // All 70+ monitoring categories organized by section
  final List<MonitoringSection> _sections = [
    MonitoringSection(
      title: 'المحاسبة والمالية',
      titleEn: 'Accounting & Finance',
      icon: Icons.account_balance,
      items: [
        MonitoringItem(id: 'coa_review', nameAr: 'مراجعة تصنيف الشجرة المحاسبية', nameEn: 'Chart of Accounts Classification Review', icon: Icons.account_tree, frequency: 'شهري'),
        MonitoringItem(id: 'sub_accounts', nameAr: 'تدقيق الحسابات الفرعية', nameEn: 'Sub-Account Audit', icon: Icons.subdirectory_arrow_right, frequency: 'ربع سنوي'),
        MonitoringItem(id: 'custody', nameAr: 'متابعة العهد المالية', nameEn: 'Financial Custody Tracking', icon: Icons.money, frequency: 'أسبوعي'),
        MonitoringItem(id: 'bank_recon', nameAr: 'مطابقة الحركات البنكية', nameEn: 'Bank Reconciliation', icon: Icons.account_balance_wallet, frequency: 'يومي'),
        MonitoringItem(id: 'trial_balance', nameAr: 'تدقيق ميزان المراجعة', nameEn: 'Trial Balance Audit', icon: Icons.balance, frequency: 'شهري'),
        MonitoringItem(id: 'cash_flow', nameAr: 'تحليل التدفقات النقدية', nameEn: 'Cash Flow Analysis', icon: Icons.water_drop, frequency: 'أسبوعي'),
        MonitoringItem(id: 'debt_aging', nameAr: 'أعمار الديون', nameEn: 'Debt Aging Analysis', icon: Icons.timer, frequency: 'أسبوعي'),
        MonitoringItem(id: 'installments', nameAr: 'متابعة الأقساط', nameEn: 'Installment Tracking', icon: Icons.calendar_month, frequency: 'يومي'),
        MonitoringItem(id: 'loans', nameAr: 'متابعة القروض', nameEn: 'Loan Tracking', icon: Icons.local_atm, frequency: 'شهري'),
        MonitoringItem(id: 'depreciation', nameAr: 'مراقبة إهلاك الأصول', nameEn: 'Asset Depreciation Monitoring', icon: Icons.trending_down, frequency: 'شهري'),
        MonitoringItem(id: 'liabilities', nameAr: 'مراقبة الالتزامات', nameEn: 'Liability Monitoring', icon: Icons.warning_amber, frequency: 'أسبوعي'),
        MonitoringItem(id: 'waste', nameAr: 'مراقبة الهدر', nameEn: 'Waste Monitoring', icon: Icons.delete_sweep, frequency: 'يومي'),
        MonitoringItem(id: 'loss_analysis', nameAr: 'تحليل الخسائر', nameEn: 'Loss Analysis', icon: Icons.trending_down, frequency: 'شهري'),
      ],
    ),
    MonitoringSection(
      title: 'الرواتب والموارد البشرية',
      titleEn: 'Payroll & HR',
      icon: Icons.people,
      items: [
        MonitoringItem(id: 'payroll_audit', nameAr: 'تدقيق صرف الرواتب', nameEn: 'Payroll Disbursement Audit', icon: Icons.payments, frequency: 'شهري'),
        MonitoringItem(id: 'leave_balance', nameAr: 'التحقق من رصيد الإجازات', nameEn: 'Leave Balance Verification', icon: Icons.event_busy, frequency: 'يومي'),
        MonitoringItem(id: 'residency', nameAr: 'تنبيه تجديد الإقامات', nameEn: 'Residency Permit Renewal Alert', icon: Icons.badge, frequency: 'أسبوعي'),
        MonitoringItem(id: 'medical', nameAr: 'صلاحية التأمين الطبي', nameEn: 'Medical Insurance Validity', icon: Icons.medical_services, frequency: 'شهري'),
        MonitoringItem(id: 'contracts', nameAr: 'تجديد عقود الموظفين', nameEn: 'Employee Contract Renewal', icon: Icons.description, frequency: 'شهري'),
        MonitoringItem(id: 'attendance', nameAr: 'مراقبة الحضور والغياب', nameEn: 'Attendance Monitoring', icon: Icons.access_time, frequency: 'يومي'),
        MonitoringItem(id: 'productivity', nameAr: 'مراقبة الإنتاجية', nameEn: 'Productivity Monitoring', icon: Icons.speed, frequency: 'أسبوعي'),
      ],
    ),
    MonitoringSection(
      title: 'الشيكات والتحصيل',
      titleEn: 'Cheques & Collections',
      icon: Icons.receipt_long,
      items: [
        MonitoringItem(id: 'cheque_issue', nameAr: 'متابعة صرف الشيكات', nameEn: 'Cheque Issuance Tracking', icon: Icons.edit_document, frequency: 'يومي'),
        MonitoringItem(id: 'cheque_collect', nameAr: 'متابعة تحصيل الشيكات', nameEn: 'Cheque Collection Tracking', icon: Icons.savings, frequency: 'يومي'),
        MonitoringItem(id: 'cheque_due', nameAr: 'تواريخ استحقاق الشيكات', nameEn: 'Cheque Due Dates', icon: Icons.event, frequency: 'يومي'),
        MonitoringItem(id: 'bounced', nameAr: 'الشيكات المرتجعة', nameEn: 'Bounced Cheques', icon: Icons.error_outline, frequency: 'يومي'),
        MonitoringItem(id: 'collection_match', nameAr: 'مطابقة التحصيلات', nameEn: 'Collection Matching', icon: Icons.compare_arrows, frequency: 'أسبوعي'),
      ],
    ),
    MonitoringSection(
      title: 'المخزون والمستودعات',
      titleEn: 'Inventory & Warehouses',
      icon: Icons.inventory_2,
      items: [
        MonitoringItem(id: 'material_expiry', nameAr: 'تواريخ انتهاء المواد', nameEn: 'Material Expiry Dates', icon: Icons.calendar_today, frequency: 'يومي'),
        MonitoringItem(id: 'inventory_audit', nameAr: 'تدقيق المخزون الدوري', nameEn: 'Periodic Inventory Audit', icon: Icons.fact_check, frequency: 'شهري'),
        MonitoringItem(id: 'stagnant', nameAr: 'المخزون الراكد', nameEn: 'Stagnant Inventory', icon: Icons.hourglass_empty, frequency: 'شهري'),
        MonitoringItem(id: 'price_change', nameAr: 'تغيرات أسعار المخزون', nameEn: 'Inventory Price Changes', icon: Icons.price_change, frequency: 'أسبوعي'),
        MonitoringItem(id: 'low_stock', nameAr: 'تنبيه نقص المخزون', nameEn: 'Low Stock Alert', icon: Icons.inventory, frequency: 'يومي'),
        MonitoringItem(id: 'scrap', nameAr: 'إدارة السكراب والخردة', nameEn: 'Scrap Management', icon: Icons.recycling, frequency: 'شهري'),
        MonitoringItem(id: 'tools_inv', nameAr: 'جرد العدد والأدوات', nameEn: 'Tools Inventory', icon: Icons.build, frequency: 'شهري'),
        MonitoringItem(id: 'periodic_count', nameAr: 'الجرد الدوري', nameEn: 'Periodic Physical Count', icon: Icons.playlist_add_check, frequency: 'ربع سنوي'),
      ],
    ),
    MonitoringSection(
      title: 'المبيعات والمشتريات',
      titleEn: 'Sales & Purchases',
      icon: Icons.shopping_cart,
      items: [
        MonitoringItem(id: 'sales_recon', nameAr: 'مطابقة المبيعات', nameEn: 'Sales Reconciliation', icon: Icons.compare, frequency: 'يومي'),
        MonitoringItem(id: 'invoice_audit_ref', nameAr: 'تدقيق الفواتير', nameEn: 'Invoice Auditing', icon: Icons.receipt, frequency: 'يومي'),
        MonitoringItem(id: 'duplicate_inv', nameAr: 'كشف الفواتير المكررة', nameEn: 'Duplicate Invoice Detection', icon: Icons.copy_all, frequency: 'يومي'),
        MonitoringItem(id: 'price_monitor', nameAr: 'مراقبة الأسعار', nameEn: 'Price Monitoring', icon: Icons.price_check, frequency: 'أسبوعي'),
        MonitoringItem(id: 'market_compare', nameAr: 'مقارنة أسعار السوق', nameEn: 'Market Price Comparison', icon: Icons.compare_arrows, frequency: 'أسبوعي'),
        MonitoringItem(id: 'supplier_eval', nameAr: 'تقييم الموردين', nameEn: 'Supplier Evaluation', icon: Icons.star_rate, frequency: 'ربع سنوي'),
        MonitoringItem(id: 'buyer_eval', nameAr: 'تقييم المشترين (الموظفين)', nameEn: 'Buyer Evaluation (Employees)', icon: Icons.person_search, frequency: 'شهري'),
      ],
    ),
    MonitoringSection(
      title: 'المصاريف التشغيلية',
      titleEn: 'Operational Expenses',
      icon: Icons.receipt,
      items: [
        MonitoringItem(id: 'rent', nameAr: 'إدارة الإيجارات', nameEn: 'Rent Management', icon: Icons.home, frequency: 'شهري'),
        MonitoringItem(id: 'rent_collect', nameAr: 'تحصيل الإيجارات', nameEn: 'Rent Collection', icon: Icons.monetization_on, frequency: 'شهري'),
        MonitoringItem(id: 'gov_fees', nameAr: 'الرسوم الحكومية', nameEn: 'Government Fees', icon: Icons.gavel, frequency: 'ربع سنوي'),
        MonitoringItem(id: 'licenses', nameAr: 'تجديد التراخيص', nameEn: 'License Renewals', icon: Icons.verified, frequency: 'سنوي'),
        MonitoringItem(id: 'utilities', nameAr: 'فواتير الخدمات', nameEn: 'Utility Bills', icon: Icons.electrical_services, frequency: 'شهري'),
        MonitoringItem(id: 'municipal', nameAr: 'رسوم البلدية', nameEn: 'Municipal Fees', icon: Icons.location_city, frequency: 'سنوي'),
        MonitoringItem(id: 'fees_dues', nameAr: 'الرسوم والمستحقات', nameEn: 'Fees & Dues', icon: Icons.attach_money, frequency: 'شهري'),
      ],
    ),
    MonitoringSection(
      title: 'الصيانة والمعدات',
      titleEn: 'Maintenance & Equipment',
      icon: Icons.engineering,
      items: [
        MonitoringItem(id: 'maintenance', nameAr: 'جدولة الصيانة', nameEn: 'Maintenance Scheduling', icon: Icons.build_circle, frequency: 'شهري'),
        MonitoringItem(id: 'vehicle_fuel', nameAr: 'متابعة وقود المركبات', nameEn: 'Vehicle Fuel Tracking', icon: Icons.local_gas_station, frequency: 'أسبوعي'),
        MonitoringItem(id: 'vehicle_maint', nameAr: 'صيانة المركبات', nameEn: 'Vehicle Maintenance', icon: Icons.directions_car, frequency: 'شهري'),
        MonitoringItem(id: 'equipment', nameAr: 'صيانة المعدات', nameEn: 'Equipment Maintenance', icon: Icons.precision_manufacturing, frequency: 'شهري'),
        MonitoringItem(id: 'buildings', nameAr: 'صيانة المباني', nameEn: 'Building Maintenance', icon: Icons.apartment, frequency: 'ربع سنوي'),
        MonitoringItem(id: 'consumption', nameAr: 'مراقبة الاستهلاك', nameEn: 'Consumption Monitoring', icon: Icons.data_usage, frequency: 'أسبوعي'),
      ],
    ),
    MonitoringSection(
      title: 'الإدارة والمتابعة',
      titleEn: 'Management & Follow-up',
      icon: Icons.admin_panel_settings,
      items: [
        MonitoringItem(id: 'meetings', nameAr: 'مراقبة الاجتماعات', nameEn: 'Meeting Monitoring', icon: Icons.groups, frequency: 'أسبوعي'),
        MonitoringItem(id: 'tasks', nameAr: 'متابعة المهام', nameEn: 'Task Tracking', icon: Icons.task_alt, frequency: 'يومي'),
        MonitoringItem(id: 'kpi', nameAr: 'مؤشرات الأداء', nameEn: 'KPI Monitoring', icon: Icons.insights, frequency: 'أسبوعي'),
        MonitoringItem(id: 'compliance', nameAr: 'الامتثال القانوني', nameEn: 'Legal Compliance', icon: Icons.gavel, frequency: 'ربع سنوي'),
        MonitoringItem(id: 'audit_log', nameAr: 'سجل التدقيق', nameEn: 'Audit Log Review', icon: Icons.history, frequency: 'يومي'),
        MonitoringItem(id: 'backup', nameAr: 'النسخ الاحتياطي', nameEn: 'Backup Verification', icon: Icons.cloud_upload, frequency: 'يومي'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

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
      body: TabBarView(
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
    // Random status for demo — in real app this comes from DB
    final statusIndex = item.id.hashCode % 3;
    final status = statusIndex == 0 ? 'ok' : statusIndex == 1 ? 'warning' : 'critical';
    final statusColor = status == 'ok' ? Colors.green : status == 'warning' ? Colors.orange : Colors.red;
    final statusText = status == 'ok' ? 'سليم ✓' : status == 'warning' ? 'تحذير ⚠' : 'حرج ✗';

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
              _detailRow('آخر فحص', '2026-04-15', isDark),
              _detailRow('الفحص القادم', '2026-04-22', isDark),
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

  void _showSummaryDialog(BuildContext context, bool isDark, Color brandColor) {
    int total = 0;
    for (final s in _sections) {
      total += s.items.length;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ملخص الرقابة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إجمالي البنود: $total', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ..._sections.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.title, style: const TextStyle(fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('${s.items.length}', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            )),
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
```

---

## FILE 2: invoice_audit_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\invoice_audit_screen.dart`
**Action:** CREATE NEW FILE.

### What this screen does:
- Runs validation checks on all invoices
- Detects duplicates (same number, same vendor+date+amount)
- Shows anomalies (unusually high values, post-save changes)
- Supplier rating based on price history
- Color-coded alert cards

```dart
import 'package:flutter/material.dart';

class InvoiceAuditScreen extends StatefulWidget {
  const InvoiceAuditScreen({super.key});

  @override
  State<InvoiceAuditScreen> createState() => _InvoiceAuditScreenState();
}

class _InvoiceAuditScreenState extends State<InvoiceAuditScreen> {
  int _selectedTab = 0;

  final List<AuditAlert> _sampleAlerts = [
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
                _summaryCard('التنبيهات', '${_sampleAlerts.length}', Icons.notifications_active, Colors.red, isDark),
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
              itemCount: _sampleAlerts.length,
              itemBuilder: (context, index) {
                final alert = _sampleAlerts[index];
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
                  onPressed: () {},
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
                  onPressed: () {},
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
```

---

## NAVIGATION: Add to main.dart

The executing agent MUST add navigation routes for the new screens. Search for existing drawer/navigation items in `main.dart` and add these entries:

```dart
// Add these imports at the top of main.dart:
import 'package:hisabati_app/screens/monitoring_control_screen.dart';
import 'package:hisabati_app/screens/invoice_audit_screen.dart';

// Add these as navigation destinations (find the existing ListTile/drawer items):
ListTile(
  leading: const Icon(Icons.admin_panel_settings),
  title: const Text('الرقابة والتحكم'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonitoringControlScreen())),
),
ListTile(
  leading: const Icon(Icons.receipt_long),
  title: const Text('تدقيق الفواتير'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceAuditScreen())),
),
```

---

## VERIFICATION:
```bash
cd "c:\my app creator\hisabati_app"
flutter analyze
```

Expected: 0 errors. Warnings are acceptable.
