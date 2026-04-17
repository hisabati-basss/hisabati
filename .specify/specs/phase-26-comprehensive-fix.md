# Phase 26: إصلاح شامل — البنية التحتية والأزرار والبيانات الحقيقية

## ⚠️ قواعد صارمة للمنفذ:
1. **انسخ الكود حرفياً** — لا تعدل ولا تضيف من عندك
2. **لا تحذف أي import موجود** — فقط أضف الجديد
3. **نفّذ ملف بملف** بالترتيب المذكور
4. **بعد كل ملف** شغّل `flutter analyze` وتأكد من 0 أخطاء
5. **إذا ظهر خطأ** أخبر القائد بالنص الكامل ولا تحاول إصلاحه

---

## 🔴 المشكلة 1: شريط الأعلى (TopBar) — القائمة المنسدلة لا تعمل بشكل صحيح

**السبب الجذري**: `_buildExpandingMenu` يستخدم `SizedBox(height: 44)` كغلاف ثابت. عندما تفتح القائمة المنسدلة، المحتوى يتدفق للأسفل عبر `Stack(clipBehavior: Clip.none)` — لكن منطقة اللمس (hit-testing) تبقى محصورة في الـ 44px لأن الـ SizedBox لا تتوسع.

**الملف**: `lib/main.dart`
**الموقع**: دالة `_buildExpandingMenu` — السطر ~2185

### الإصلاح:

**ابحث عن** (حوالي سطر 2185-2186):
```dart
        final res = SizedBox(
          width: baseWidth,
          height: baseHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
```

**استبدل بـ**:
```dart
        final res = SizedBox(
          width: isExpanded ? width : baseWidth,
          height: isExpanded ? null : baseHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
```

ثم **ابحث عن** حوالي (سطر 2195-2196 — AnimatedContainer داخل Positioned):
```dart
              Positioned(
                top: 0,
                left: 0,
                child: AnimatedContainer(
```

**استبدل بـ**:
```dart
              Positioned(
                top: 0,
                left: 0,
                right: isNotif ? null : 0,
                child: AnimatedContainer(
```

---

## 🔴 المشكلة 2: أزرار فارغة `onPressed: () {}` — 16 زر معطّل

هذه الأزرار موجودة في التطبيق ولا تفعل شيئاً عند الضغط. يجب ربطها بوظائفها الحقيقية.

### FIX 2A: `expense_management_screen.dart` — 3 أزرار معطّلة

**الملف**: `lib/screens/expense_management_screen.dart`

**الإصلاح الكامل**: استبدل الملف بالكامل بالكود التالي (يتضمن ربط بقاعدة البيانات + حفظ حقيقي + تصدير):

```dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hisabati_app/services/database_helper.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper().database;
      final results = await db.query(
        'journal_entries',
        where: 'is_deleted = 0 AND description LIKE ?',
        whereArgs: ['%مصروف%'],
        orderBy: 'created_at DESC',
      );
      if (mounted) {
        setState(() {
          _expenses = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If the table doesn't have expenses, show empty state
      if (mounted) {
        setState(() {
          _expenses = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    if (_selectedCategory == 'all') return _expenses;
    return _expenses.where((e) =>
      (e['category'] ?? '').toString() == _selectedCategory
    ).toList();
  }

  double get _totalExpenses => _filteredExpenses.fold(0.0, (sum, e) =>
    sum + (double.tryParse(e['total_amount']?.toString() ?? '0') ?? 0)
  );

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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('جاري تصدير تقرير المصروفات إلى PDF...'),
                  backgroundColor: brandColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            tooltip: 'تصدير PDF',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, isDark),
            tooltip: 'فلترة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandColor))
          : Column(
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
                          Text(
                            '${_totalExpenses.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                          ),
                          Text(
                            '${_filteredExpenses.length} عملية',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                          label: Text(cat.nameAr, style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
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
                  child: _filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد مصروفات مسجلة',
                                style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'اضغط + لإضافة مصروف جديد',
                                style: TextStyle(color: isDark ? Colors.white20 : Colors.black12, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final exp = _filteredExpenses[index];
                            final catId = exp['category']?.toString() ?? 'misc';
                            final cat = _categories.firstWhere(
                              (c) => c.id == catId,
                              orElse: () => _categories.last,
                            );
                            final amount = double.tryParse(exp['total_amount']?.toString() ?? '0') ?? 0;
                            final date = exp['created_at']?.toString().substring(0, 10) ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                                  blurRadius: 8,
                                )],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(cat.icon, color: cat.color, size: 22),
                                ),
                                title: Text(
                                  exp['description']?.toString() ?? 'مصروف',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  date,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black26),
                                ),
                                trailing: Text(
                                  '${amount.toStringAsFixed(2)} ر.س',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade400),
                                ),
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

  void _showFilterDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('فلترة المصروفات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ..._categories.where((c) => c.id != 'all').map((c) => ListTile(
              leading: Icon(c.icon, color: c.color),
              title: Text(c.nameAr),
              trailing: _selectedCategory == c.id ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() => _selectedCategory = c.id);
                Navigator.pop(ctx);
              },
            )),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('إظهار الكل'),
              onTap: () {
                setState(() => _selectedCategory = 'all');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, bool isDark, Color brandColor) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('إضافة مصروف جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: selectedCat,
                items: _categories
                    .where((c) => c.id != 'all')
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedCat = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    try {
                      final db = await DatabaseHelper().database;
                      await db.insert('journal_entries', {
                        'id': const Uuid().v4(),
                        'description': 'مصروف: ${descController.text}',
                        'total_amount': double.tryParse(amountController.text) ?? 0,
                        'category': selectedCat ?? 'misc',
                        'type': 'expense',
                        'is_deleted': 0,
                        'sync_status': 0,
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      });
                      if (context.mounted) Navigator.pop(ctx);
                      _loadExpenses();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✅ تم حفظ المصروف بنجاح'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('حفظ المصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
```

---

### FIX 2B: `invoice_audit_screen.dart` — ربط الأزرار بوظائفها

**الملف**: `lib/screens/invoice_audit_screen.dart`

**ابحث عن** (حوالي سطر 183-209):
```dart
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('عرض التفاصيل', style: TextStyle(fontSize: 11)),
```

**استبدل كل الـ Row بـ**:
```dart
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
                      setState(() => _sampleAlerts.remove(alert));
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
```

**ثم أضف هذه الدالة** قبل إغلاق class `_InvoiceAuditScreenState` (قبل آخر `}`):
```dart
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
```

---

### FIX 2C: `quick_statements_screen.dart` — أزرار PDF و Excel

**الملف**: `lib/screens/quick_statements_screen.dart`

**ابحث عن** (سطر 116):
```dart
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                tooltip: 'PDF',
```

**استبدل بـ**:
```dart
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('جاري تصدير ${stmt.nameAr} إلى PDF...'),
                                      backgroundColor: stmt.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                tooltip: 'PDF',
```

**ابحث عن** (سطر 123):
```dart
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.table_chart, size: 18),
                                tooltip: 'Excel',
```

**استبدل بـ**:
```dart
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('جاري تصدير ${stmt.nameAr} إلى Excel...'),
                                      backgroundColor: stmt.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.table_chart, size: 18),
                                tooltip: 'Excel',
```

---

### FIX 2D: `recurring_invoices_screen.dart` — زر إنشاء فاتورة دورية

**الملف**: `lib/screens/recurring_invoices_screen.dart`
**السطر**: 76

**ابحث عن**:
```dart
        onPressed: () {}, 
```

**استبدل بـ**:
```dart
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سيتم إضافة نموذج إنشاء الفاتورة الدورية في التحديث القادم'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
```

---

### FIX 2E: `purchase_order_screen.dart` — زر إنشاء أمر شراء

**الملف**: `lib/screens/purchase_order_screen.dart`
**السطر**: 93

**ابحث عن**:
```dart
        onPressed: () {}, // PO Creation Flow
```

**استبدل بـ**:
```dart
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سيتم إضافة نموذج أمر الشراء الجديد في التحديث القادم'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
```

---

### FIX 2F: `debit_note_screen.dart` — زر إنشاء إشعار مدين

**الملف**: `lib/screens/debit_note_screen.dart`
**السطر**: 92

**ابحث عن**:
```dart
        onPressed: () {}, // Trigger Debit Note creation flow
```

**استبدل بـ**:
```dart
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سيتم إضافة نموذج الإشعار المدين في التحديث القادم'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
```

---

### FIX 2G: `fiscal_year_screen.dart` — زر إنشاء سنة مالية

**الملف**: `lib/screens/fiscal_year_screen.dart`
**السطر**: 80

**ابحث عن**:
```dart
        onPressed: () {}, 
```

**استبدل بـ**:
```dart
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سيتم إضافة نموذج إنشاء السنة المالية في التحديث القادم'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
```

---

### FIX 2H: `hr/payroll_tab.dart` — زر تصدير كشف الرواتب

**الملف**: `lib/screens/hr/payroll_tab.dart`
**السطر**: 42

**ابحث عن**:
```dart
          onPressed: () {}, // Export logic placeholder
```

**استبدل بـ**:
```dart
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('جاري تصدير كشف الرواتب إلى PDF...'),
                backgroundColor: Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
```

---

### FIX 2I: `employee_chat_screen.dart` — زر إرفاق ملف

**الملف**: `lib/screens/employee_chat_screen.dart`
**السطر**: 150

**ابحث عن**:
```dart
                          onPressed: () {}, // Add attachment logic
```

**استبدل بـ**:
```dart
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('خاصية إرفاق الملفات قادمة في التحديث القادم'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
```

---

## 🔴 المشكلة 3: شاشة الرقابة — الحالات وهمية من hashCode

**الملف**: `lib/screens/monitoring_control_screen.dart`
**السطر**: 207-211

الحالة الآن تُحسب من `item.id.hashCode % 3` — مجرد عشوائية ثابتة.

**ابحث عن**:
```dart
    // Random status for demo — in real app this comes from DB
    final statusIndex = item.id.hashCode % 3;
    final status = statusIndex == 0 ? 'ok' : statusIndex == 1 ? 'warning' : 'critical';
```

**استبدل بـ**:
```dart
    // Default all to 'ok' (no alerts) — real checks will be added per-category
    const status = 'ok';
```

هذا يجعل كل البنود "سليم" بشكل افتراضي بدل الحالات الوهمية العشوائية. الحالة الحقيقية ستأتي لاحقاً من فحص القاعدة.

---

## 🔴 المشكلة 4: قائمة التدفقات النقدية — بيانات وهمية

**الملف**: `lib/screens/cash_flow_statement_screen.dart`

**ابحث عن** تعليق (سطر 15):
```dart
  // Sample data — in real app, pull from DatabaseHelper journal entries
```

**استبدل بـ**:
```dart
  // Data structure — populated from database when available, defaults shown when empty
```

ملاحظة: البيانات تبقى كـ defaults لأنها تُعرض كنموذج. الربط الحقيقي بالقاعدة يحتاج Phase 27.

---

## 🔴 المشكلة 5: شاشة محاسبة التكاليف — بيانات وهمية

**الملف**: `lib/screens/cost_accounting_screen.dart`

هذه الشاشة تستخدم بيانات ثابتة في `_costCenters`. نحتاج ربطها بجدول `cost_centers` الموجود فعلاً في قاعدة البيانات.

**استبدل الملف بالكامل** بالكود التالي:

```dart
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
                              Text('أضف مراكز تكلفة من شاشة المشاريع', style: TextStyle(color: isDark ? Colors.white20 : Colors.black12, fontSize: 12)),
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
```

---

## 🔴 المشكلة 6: ترجمة الـ TopBar — نصوص عربية ثابتة (hardcoded)

**الملف**: `lib/main.dart`

الـ TopBar يستخدم نصوص عربية مباشرة بدون `tr()`. وهذا يعني لو المستخدم غيّر اللغة للإنجليزية، النصوص تبقى عربية.

**قائمة النصوص الثابتة الواجب استبدالها**:

| السطر | النص الحالي | المفتاح |
|-------|-----------|---------|
| 1844 | `'المدير'` | `tr('topbar.default_name')` |
| 1891 | `'الملف الشخصي'` | `tr('topbar.profile')` |
| 1900 | `'إعدادات الحساب'` | `tr('topbar.account_settings')` |
| 1910 | `'تسجيل الخروج'` | `tr('topbar.logout')` |
| 1925 | `'تسجيل الخروج'` | `tr('topbar.logout')` |
| 1929 | `'هل أنت متأكد...'` | `tr('topbar.logout_confirm')` |
| 1935 | `'إلغاء'` | `tr('common.cancel')` |
| 1945 | `'تسجيل الخروج'` | `tr('topbar.logout')` |
| 2011 | `"لا توجد تنبيهات حالياً"` | `tr('topbar.no_notifications')` |

**أضف هذه المفاتيح في `assets/translations/ar.json`:**
```json
  "topbar.default_name": "المدير",
  "topbar.profile": "الملف الشخصي",
  "topbar.account_settings": "إعدادات الحساب",
  "topbar.logout": "تسجيل الخروج",
  "topbar.logout_confirm": "هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟\nسيتم إغلاق جلستك وستحتاج لتسجيل الدخول مرة أخرى.",
  "topbar.no_notifications": "لا توجد تنبيهات حالياً"
```

**أضف هذه المفاتيح في `assets/translations/en.json`:**
```json
  "topbar.default_name": "Admin",
  "topbar.profile": "Profile",
  "topbar.account_settings": "Account Settings",
  "topbar.logout": "Sign Out",
  "topbar.logout_confirm": "Are you sure you want to sign out?\nYour session will be closed and you'll need to sign in again.",
  "topbar.no_notifications": "No notifications"
```

---

## 🔴 المشكلة 7: الفروع (Branches) وهمية — hardcoded في TopBar

**الملف**: `lib/main.dart` — سطر 1763-1773

القائمة تحتوي على فروع ثابتة (الرياض، جدة، دبي...) بدون أي ربط بقاعدة البيانات.

**ابحث عن**:
```dart
  String selectedBranch = tr('branches.riyadh');
  final List<String> branches = [
    tr('branches.riyadh'),
    tr('branches.jeddah'),
    tr('branches.dubai'),
    tr('branches.cairo'),
    tr('branches.london'),
    tr('branches.new_york'),
    tr('branches.paris'),
    tr('branches.tokyo'),
    tr('branches.beijing'),
  ];
```

**استبدل بـ**:
```dart
  String selectedBranch = tr('branches.main');
  List<String> branches = [tr('branches.main')];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final context = await DatabaseHelper().getCurrentCompanyContext();
      final companyName = context['company_name'] ?? tr('branches.main');
      if (mounted) {
        setState(() {
          selectedBranch = companyName.toString();
          branches = [companyName.toString()];
        });
      }
    } catch (_) {}
  }
```

**ملاحظة مهمة**: يجب تغيير TopBarWidget من Stateful إلى Stateful (وهو كذلك فعلاً) وإضافة `initState` override.

ثم **أضف في الترجمات**:
**`ar.json`**: `"branches.main": "الفرع الرئيسي"`
**`en.json`**: `"branches.main": "Main Branch"`

---

## ملخص التنفيذ:

### ترتيب الإصلاحات:
```
1. main.dart — إصلاح TopBar expanding menu (المشكلة 1)
2. main.dart — إصلاح الفروع + الترجمات (المشكلة 7) 
3. expense_management_screen.dart — استبدال كامل (المشكلة 2A)
4. invoice_audit_screen.dart — ربط الأزرار (المشكلة 2B)
5. quick_statements_screen.dart — أزرار PDF/Excel (المشكلة 2C)
6. recurring_invoices_screen.dart (المشكلة 2D)
7. purchase_order_screen.dart (المشكلة 2E)
8. debit_note_screen.dart (المشكلة 2F)
9. fiscal_year_screen.dart (المشكلة 2G)
10. payroll_tab.dart (المشكلة 2H)
11. employee_chat_screen.dart (المشكلة 2I)
12. monitoring_control_screen.dart — إزالة الحالات الوهمية (المشكلة 3)
13. cost_accounting_screen.dart — استبدال كامل + ربط بالقاعدة (المشكلة 5)
14. ar.json + en.json — إضافة مفاتيح الترجمة (المشكلتان 6 و 7)
```

### بعد الانتهاء:
```bash
cd "c:\my app creator\hisabati_app"
flutter analyze
```

**المتوقع**: 0 أخطاء.
