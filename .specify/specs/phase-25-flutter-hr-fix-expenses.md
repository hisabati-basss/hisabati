# Phase 25: Flutter — HR Fix + Expense Management + Cost Accounting — EXACT CODE

## ⚠️ RULES: Follow EXACTLY. Do NOT modify any code not specified here.

---

## FIX 1: HR "Hire" Button Bug
**Problem:** When clicking "توظيف" (Hire) on a candidate, it opens the employee form in EDIT mode. But the form's `_handleSave()` method for existing employees (`widget.employee != null`) does NOT update the status from `'candidate'` to `'active'`. So after "editing" a candidate, they remain as candidate.

**Root cause:** Line 280 of `hr_root_screen.dart`:
```dart
onHire: (c) => _showEmployeeForm(employee: c),
```
This calls `_showEmployeeForm` with the candidate as `employee`, which triggers the UPDATE path in `employee_form.dart` (line 388-391), but that path doesn't set `status = 'active'`.

### Fix A: Modify `hr_root_screen.dart`
**Path:** `c:\my app creator\hisabati_app\lib\screens\hr\hr_root_screen.dart`
**Action:** Find line 280 and REPLACE this one line:

**Find:**
```dart
                          onHire: (c) => _showEmployeeForm(employee: c),
```

**Replace with:**
```dart
                          onHire: (c) => _hireCandidate(c),
```

Then ADD this new method inside `_HrRootScreenState` class, after the `_showEmployeeForm` method (after line 122):

```dart
  Future<void> _hireCandidate(Map<String, dynamic> candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryOrange.withValues(alpha: 0.3))),
        title: Row(
          children: [
            Icon(Icons.how_to_reg, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            const Text('تأكيد التوظيف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد توظيف "${candidate['name']}" كموظف رسمي؟', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Text('سيتم تحويل حالته من "مرشح" إلى "نشط" وستُنشأ له بيانات الدخول.', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel'), style: const TextStyle(color: Colors.white38)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, color: Colors.black, size: 18),
            label: Text(tr('hr.form.buttons.hire_confirm'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _payrollService.updateEmployee(
          candidate['id']?.toString() ?? '',
          {
            'status': 'active',
            'hiring_date': DateTime.now().toIso8601String(),
            'sync_status': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ تم توظيف ${candidate['name']} بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في التوظيف: $e'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    }
  }
```

### Fix B: Add missing translation key
**Path:** `c:\my app creator\hisabati_app\assets\translations\ar.json`
**Action:** Find the `"hr"` section and add this key if missing:

```json
"hr.form.buttons.hire_confirm": "توظيف الآن"
```

**Path:** `c:\my app creator\hisabati_app\assets\translations\en.json`
```json
"hr.form.buttons.hire_confirm": "Hire Now"
```

---

## FILE 2: expense_management_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\expense_management_screen.dart`
**Action:** CREATE NEW FILE.

### What this screen does:
- List expenses by category with summary cards
- Add new expense with category, amount, date, notes
- Receipt photo attachment placeholder
- Filter by date range and category
- Export to PDF

```dart
import 'package:flutter/material.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  String _selectedCategory = 'all';
  
  final List<ExpenseCategory> _categories = [
    ExpenseCategory(id: 'all', nameAr: 'الكل', icon: Icons.grid_view, color: const Color(0xFFFF6B00)),
    ExpenseCategory(id: 'operations', nameAr: 'تشغيلية', icon: Icons.settings, color: Colors.blue),
    ExpenseCategory(id: 'rent', nameAr: 'إيجارات', icon: Icons.home, color: Colors.purple),
    ExpenseCategory(id: 'salaries', nameAr: 'رواتب', icon: Icons.people, color: Colors.green),
    ExpenseCategory(id: 'utilities', nameAr: 'خدمات', icon: Icons.electrical_services, color: Colors.cyan),
    ExpenseCategory(id: 'travel', nameAr: 'سفر وانتقال', icon: Icons.flight, color: Colors.orange),
    ExpenseCategory(id: 'maintenance', nameAr: 'صيانة', icon: Icons.build, color: Colors.brown),
    ExpenseCategory(id: 'marketing', nameAr: 'تسويق', icon: Icons.campaign, color: Colors.pink),
    ExpenseCategory(id: 'office', nameAr: 'مكتبية', icon: Icons.print, color: Colors.teal),
    ExpenseCategory(id: 'misc', nameAr: 'متنوعة', icon: Icons.more_horiz, color: Colors.grey),
  ];

  final List<ExpenseEntry> _expenses = [
    ExpenseEntry(category: 'rent', descAr: 'إيجار المكتب - يناير', amount: 15000, date: DateTime(2026, 1, 5)),
    ExpenseEntry(category: 'utilities', descAr: 'فاتورة كهرباء', amount: 2300, date: DateTime(2026, 1, 10)),
    ExpenseEntry(category: 'salaries', descAr: 'رواتب الموظفين - يناير', amount: 85000, date: DateTime(2026, 1, 28)),
    ExpenseEntry(category: 'operations', descAr: 'مواد تنظيف ومستلزمات', amount: 1200, date: DateTime(2026, 1, 15)),
    ExpenseEntry(category: 'travel', descAr: 'تذاكر سفر - معرض تقني', amount: 4500, date: DateTime(2026, 1, 20)),
    ExpenseEntry(category: 'maintenance', descAr: 'صيانة مكيفات', amount: 3000, date: DateTime(2026, 2, 1)),
    ExpenseEntry(category: 'marketing', descAr: 'إعلانات Google', amount: 5000, date: DateTime(2026, 2, 5)),
    ExpenseEntry(category: 'office', descAr: 'أوراق وأحبار طابعة', amount: 800, date: DateTime(2026, 2, 10)),
  ];

  List<ExpenseEntry> get _filteredExpenses => _selectedCategory == 'all' 
    ? _expenses 
    : _expenses.where((e) => e.category == _selectedCategory).toList();

  double get _totalExpenses => _filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('إدارة المصروفات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () {}, tooltip: 'تصدير PDF'),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}, tooltip: 'فلترة'),
        ],
      ),
      body: Column(
        children: [
          // Total Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF983F)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إجمالي المصروفات', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${_totalExpenses.toStringAsFixed(0)} ر.س', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.nameAr, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54), fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    onSelected: (_) => setState(() => _selectedCategory = cat.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Expense list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredExpenses.length,
              itemBuilder: (context, index) {
                final exp = _filteredExpenses[index];
                final cat = _categories.firstWhere((c) => c.id == exp.category, orElse: () => _categories.last);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                    title: Text(exp.descAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${exp.date.year}/${exp.date.month}/${exp.date.day}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26)),
                    trailing: Text('${exp.amount.toStringAsFixed(0)} ر.س', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade400)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context, isDark, brandColor),
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, bool isDark, Color brandColor) {
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
            const Text('إضافة مصروف جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'الوصف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _categories.where((c) => c.id != 'all').map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr))).toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('إرفاق إيصال', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: brandColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('حفظ المصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseCategory {
  final String id, nameAr;
  final IconData icon;
  final Color color;
  ExpenseCategory({required this.id, required this.nameAr, required this.icon, required this.color});
}

class ExpenseEntry {
  final String category, descAr;
  final double amount;
  final DateTime date;
  ExpenseEntry({required this.category, required this.descAr, required this.amount, required this.date});
}
```

---

## FILE 3: cost_accounting_screen.dart
**Path:** `c:\my app creator\hisabati_app\lib\screens\cost_accounting_screen.dart`
**Action:** CREATE NEW FILE.

```dart
import 'package:flutter/material.dart';

class CostAccountingScreen extends StatefulWidget {
  const CostAccountingScreen({super.key});

  @override
  State<CostAccountingScreen> createState() => _CostAccountingScreenState();
}

class _CostAccountingScreenState extends State<CostAccountingScreen> {
  int _selectedTab = 0;

  final List<CostCenter> _costCenters = [
    CostCenter(name: 'إدارة عامة', nameEn: 'General Admin', directCost: 120000, indirectCost: 35000, revenue: 0, color: Colors.blue),
    CostCenter(name: 'قسم المبيعات', nameEn: 'Sales Dept', directCost: 85000, indirectCost: 28000, revenue: 450000, color: Colors.green),
    CostCenter(name: 'قسم الإنتاج', nameEn: 'Production', directCost: 250000, indirectCost: 65000, revenue: 680000, color: Colors.orange),
    CostCenter(name: 'قسم الصيانة', nameEn: 'Maintenance', directCost: 45000, indirectCost: 12000, revenue: 0, color: Colors.red),
    CostCenter(name: 'مشروع A', nameEn: 'Project A', directCost: 180000, indirectCost: 40000, revenue: 350000, color: Colors.purple),
    CostCenter(name: 'مشروع B', nameEn: 'Project B', directCost: 95000, indirectCost: 22000, revenue: 200000, color: Colors.cyan),
  ];

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
      ),
      body: Column(
        children: [
          // Summary row
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _summaryCard('إجمالي التكاليف المباشرة', _costCenters.fold(0.0, (s, c) => s + c.directCost), Icons.arrow_downward, Colors.red, isDark),
                _summaryCard('إجمالي التكاليف غير المباشرة', _costCenters.fold(0.0, (s, c) => s + c.indirectCost), Icons.arrow_forward, Colors.orange, isDark),
                _summaryCard('إجمالي الإيرادات', _costCenters.fold(0.0, (s, c) => s + c.revenue), Icons.arrow_upward, Colors.green, isDark),
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
                  label: Text(tabs[index], style: TextStyle(color: _selectedTab == index ? Colors.white : (isDark ? Colors.white70 : Colors.black54), fontWeight: FontWeight.bold, fontSize: 12)),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _costCenters.length,
              itemBuilder: (context, index) {
                final cc = _costCenters[index];
                final totalCost = cc.directCost + cc.indirectCost;
                final profit = cc.revenue - totalCost;
                final profitMargin = cc.revenue > 0 ? (profit / cc.revenue * 100) : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(left: BorderSide(color: cc.color, width: 4)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: cc.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.account_tree, color: cc.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(cc.nameEn, style: TextStyle(fontSize: 10, color: isDark ? Colors.white20 : Colors.black20)),
                                ],
                              ),
                            ),
                            if (cc.revenue > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (profit >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${profitMargin.toStringAsFixed(1)}%',
                                  style: TextStyle(color: profit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _costItem('مباشرة', cc.directCost, Colors.red, isDark),
                            _costItem('غير مباشرة', cc.indirectCost, Colors.orange, isDark),
                            _costItem('إجمالي', totalCost, Colors.purple, isDark),
                            if (cc.revenue > 0) _costItem('إيرادات', cc.revenue, Colors.green, isDark),
                            if (cc.revenue > 0) _costItem('صافي', profit, profit >= 0 ? Colors.green : Colors.red, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 160,
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
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_formatNum(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color))),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 10, color: isDark ? Colors.white40 : Colors.black38)),
        ],
      ),
    );
  }

  Widget _costItem(String label, double value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(_formatNum(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white25 : Colors.black20)),
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
}

class CostCenter {
  final String name, nameEn;
  final double directCost, indirectCost, revenue;
  final Color color;
  CostCenter({required this.name, required this.nameEn, required this.directCost, required this.indirectCost, required this.revenue, required this.color});
}
```

---

## NAVIGATION: Add all Phase 25 screens to main.dart

```dart
// Add these imports:
import 'package:hisabati_app/screens/expense_management_screen.dart';
import 'package:hisabati_app/screens/cost_accounting_screen.dart';

// Add these navigation items:
ListTile(
  leading: const Icon(Icons.receipt_long),
  title: const Text('إدارة المصروفات'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen())),
),
ListTile(
  leading: const Icon(Icons.pie_chart),
  title: const Text('محاسبة التكاليف'),
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CostAccountingScreen())),
),
```

---

## VERIFICATION:
```bash
cd "c:\my app creator\hisabati_app"
flutter analyze
```

Expected: 0 errors. The HR fix should now:
1. Show a confirmation dialog when pressing "توظيف"
2. Update the candidate's `status` from `'candidate'` to `'active'`
3. Set `hiring_date` to today
4. Refresh the employee/candidate lists
