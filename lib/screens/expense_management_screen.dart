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
                                style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black12, fontSize: 12),
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
