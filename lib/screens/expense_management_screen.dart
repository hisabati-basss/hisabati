import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hisabati_app/services/database_helper.dart';
import 'package:hisabati_app/services/approval_service.dart';
import 'package:hisabati_app/services/auth_service.dart';

// ─── Category model ───────────────────────────────────────────────────────────
class ExpenseCategory {
  final String id, nameAr;
  final IconData icon;
  final Color color;
  const ExpenseCategory({required this.id, required this.nameAr, required this.icon, required this.color});
}

const List<ExpenseCategory> kExpenseCategories = [
  ExpenseCategory(id: 'all',         nameAr: 'الكل',         icon: Icons.grid_view,             color: Color(0xFFFF6B00)),
  ExpenseCategory(id: 'operations',  nameAr: 'تشغيلية',      icon: Icons.settings,              color: Colors.blue),
  ExpenseCategory(id: 'rent',        nameAr: 'إيجارات',      icon: Icons.home,                  color: Colors.purple),
  ExpenseCategory(id: 'salaries',    nameAr: 'رواتب',        icon: Icons.people,                color: Colors.green),
  ExpenseCategory(id: 'utilities',   nameAr: 'خدمات',        icon: Icons.electrical_services,   color: Colors.cyan),
  ExpenseCategory(id: 'travel',      nameAr: 'سفر وانتقال',  icon: Icons.flight,                color: Colors.orange),
  ExpenseCategory(id: 'maintenance', nameAr: 'صيانة',        icon: Icons.build,                 color: Colors.brown),
  ExpenseCategory(id: 'marketing',   nameAr: 'تسويق',        icon: Icons.campaign,              color: Colors.pink),
  ExpenseCategory(id: 'office',      nameAr: 'مكتبية',       icon: Icons.print,                 color: Colors.teal),
  ExpenseCategory(id: 'misc',        nameAr: 'متنوعة',       icon: Icons.more_horiz,            color: Colors.grey),
];

ExpenseCategory _catById(String id) => kExpenseCategories.firstWhere(
  (c) => c.id == id,
  orElse: () => kExpenseCategories.last,
);

// ─── Screen ───────────────────────────────────────────────────────────────────
class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});
  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  static const _brandColor = Color(0xFFFF6B00);

  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  // ── ensure table helper (called before every write) ─────────────────────────
  Future<void> _ensureTable() async {
    final db = await DatabaseHelper().database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        description TEXT,
        amount REAL DEFAULT 0,
        category TEXT DEFAULT 'misc',
        expense_date TEXT,
        payment_method TEXT DEFAULT 'cash',
        vendor TEXT,
        reference_no TEXT,
        notes TEXT,
        status TEXT DEFAULT 'approved',
        attachment_path TEXT,
        cost_center_id TEXT,
        created_by TEXT,
        sync_status INTEGER DEFAULT 0,
        updated_at TEXT,
        device_id TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
    // Add any missing columns defensively
    final cols = (await db.rawQuery('PRAGMA table_info(expenses)')).map((r) => r['name'].toString()).toSet();
    final missing = {
      'payment_method': "ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT 'cash'",
      'vendor':         "ALTER TABLE expenses ADD COLUMN vendor TEXT",
      'reference_no':   "ALTER TABLE expenses ADD COLUMN reference_no TEXT",
      'notes':          "ALTER TABLE expenses ADD COLUMN notes TEXT",
      'status':         "ALTER TABLE expenses ADD COLUMN status TEXT DEFAULT 'approved'",
      'cost_center_id': "ALTER TABLE expenses ADD COLUMN cost_center_id TEXT",
      'created_by':     "ALTER TABLE expenses ADD COLUMN created_by TEXT",
      'attachment_path':"ALTER TABLE expenses ADD COLUMN attachment_path TEXT",
      'expense_date':   "ALTER TABLE expenses ADD COLUMN expense_date TEXT",
      'created_at':     "ALTER TABLE expenses ADD COLUMN created_at TEXT",
      'updated_at':     "ALTER TABLE expenses ADD COLUMN updated_at TEXT",
      'is_deleted':     "ALTER TABLE expenses ADD COLUMN is_deleted INTEGER DEFAULT 0",
    };
    for (final col in missing.keys) {
      if (!cols.contains(col)) {
        try { await db.execute(missing[col]!); } catch (e) { debugPrint('Migration error for $col: $e'); }
      }
    }
  }

  Future<void> _initAndLoad() async {
    try { await _ensureTable(); } catch (e) { debugPrint('expenses init: $e'); }
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        'expenses',
        where: 'is_deleted = 0',
        orderBy: 'created_at DESC',
      );
      if (mounted) setState(() { _expenses = rows; _isLoading = false; });
    } catch (e) {
      debugPrint('load expenses: $e');
      if (mounted) setState(() { _expenses = []; _isLoading = false; });
    }
  }

  Future<List<Map<String, dynamic>>> _loadCostCenters() async {
    final db = await DatabaseHelper().database;
    return await db.query('cost_centers', where: 'is_deleted = 0');
  }

  Future<void> _deleteExpense(String id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.update('expenses', {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [id]);
      _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم حذف المصروف'), backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch (e) { debugPrint('delete expense: $e'); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedCategory == 'all') return _expenses;
    return _expenses.where((e) => (e['category'] ?? '') == _selectedCategory).toList();
  }

  double get _total => _filtered.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  // ── Add dialog ──────────────────────────────────────────────────────────────
  void _showAddDialog() {
    final descCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final notesCtrl  = TextEditingController();
    String selCat    = 'misc';
    String selMethod = 'cash';
    String? selCC;
    List<Map<String, dynamic>> costCenters = [];

    // Pre-load cost centers
    _loadCostCenters().then((list) {
      if (mounted) {
        costCenters = list;
        if (list.isNotEmpty) selCC = list.first['id'];
      }
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (ctx, anim, _, __) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim.value),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: StatefulBuilder(
              builder: (context, setS) => AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // title
                            const Center(
                              child: Text('إضافة مصروف جديد',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                            ),
                            const SizedBox(height: 20),

                            // description
                            _glassInput(descCtrl, 'الوصف *'),
                            const SizedBox(height: 10),

                            // amount
                            _glassInput(amountCtrl, 'المبلغ (ر.س) *', isNum: true),
                            const SizedBox(height: 10),

                            // vendor
                            _glassInput(vendorCtrl, 'المورد / الجهة'),
                            const SizedBox(height: 10),

                            // notes
                            _glassInput(notesCtrl, 'ملاحظات', maxLines: 2),
                            const SizedBox(height: 14),

                            // category chips
                            Text('التصنيف', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: kExpenseCategories
                                .where((c) => c.id != 'all')
                                .map((c) {
                                  final sel = selCat == c.id;
                                  return GestureDetector(
                                    onTap: () => setS(() => selCat = c.id),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sel ? c.color : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: sel ? c.color : Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(c.icon, size: 12, color: sel ? Colors.white : c.color),
                                        const SizedBox(width: 4),
                                        Text(c.nameAr, style: TextStyle(
                                          color: sel ? Colors.white : Colors.white60, fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                      ]),
                                    ),
                                  );
                                }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // payment method
                            Text('طريقة الدفع', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(children: [
                              _methodChip('نقداً',       'cash',   selMethod, (v) => setS(() => selMethod = v), Icons.money),
                              const SizedBox(width: 8),
                              _methodChip('بطاقة',       'card',   selMethod, (v) => setS(() => selMethod = v), Icons.credit_card),
                              const SizedBox(width: 8),
                              _methodChip('تحويل بنكي',  'bank',   selMethod, (v) => setS(() => selMethod = v), Icons.account_balance),
                            ]),
                            const SizedBox(height: 14),

                            // cost center
                            Text('مركز التكلفة', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: selCC,
                                isExpanded: true,
                                dropdownColor: Colors.black87,
                                underline: const SizedBox(),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: costCenters.map((cc) => DropdownMenuItem(
                                  value: cc['id'].toString(),
                                  child: Text(cc['name']?.toString() ?? 'مركز غير معروف'),
                                )).toList(),
                                onChanged: (v) => setS(() => selCC = v),
                                hint: const Text('اختر مركز تكلفة', style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // buttons
                            Row(children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('إلغاء', style: TextStyle(color: Colors.white54)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (descCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('يرجى ملء الوصف والمبلغ'), backgroundColor: Colors.red));
                                      return;
                                    }
                                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                                    if (amount <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر'), backgroundColor: Colors.red));
                                      return;
                                    }
                                    try {
                                      await _ensureTable();
                                      final db = await DatabaseHelper().database;
                                      final now = DateTime.now().toIso8601String();
                                      final String expenseId = const Uuid().v4();
                                      
                                      // 🛡️ Logic: If amount > 1000, require approval
                                      final bool needsApproval = amount > 1000;
                                      final String initialStatus = needsApproval ? 'pending' : 'approved';

                                      await db.insert('expenses', {
                                        'id':             expenseId,
                                        'description':    descCtrl.text.trim(),
                                        'amount':         amount,
                                        'category':       selCat,
                                        'payment_method': selMethod,
                                        'vendor':         vendorCtrl.text.trim(),
                                        'notes':          notesCtrl.text.trim(),
                                        'cost_center_id': selCC,
                                        'expense_date':   now.substring(0, 10),
                                        'status':         initialStatus,
                                        'is_deleted':     0,
                                        'sync_status':    0,
                                        'created_at':     now,
                                        'updated_at':     now,
                                      });

                                      if (needsApproval) {
                                        await ApprovalService().requestApproval(
                                          entityType: 'expense',
                                          entityId: expenseId,
                                          requesterId: AuthService().currentUser?.email ?? 'unknown',
                                          comments: 'مصروف بقيمة مرتفعة: ${amount} ر.س',
                                        );
                                      } else {
                                        // ── Accounting Integration (GL) ── Only if approved
                                        final String creditAccount = selMethod == 'cash' ? 'ACC_CASH' : 'ACC_BANK';
                                        await DatabaseHelper().saveManualJournalEntry(
                                          {
                                            'date': now.substring(0, 10),
                                            'description': 'مصروف: ${descCtrl.text.trim()} - ${vendorCtrl.text.trim()}',
                                            'reference_id': expenseId,
                                          },
                                          [
                                            {
                                              'account_id': 'ACC_EXPENSES_GENERAL', 
                                              'debit': amount, 
                                              'credit': 0.0,
                                              'cost_center_id': selCC
                                            },
                                            {
                                              'account_id': creditAccount, 
                                              'debit': 0.0, 
                                              'credit': amount,
                                              'cost_center_id': selCC
                                            },
                                          ],
                                        );
                                      }

                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        _loadExpenses();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(needsApproval ? '⏳ تم إرسال المصروف للموافقة' : '✅ تم حفظ المصروف بنجاح'),
                                            backgroundColor: needsApproval ? Colors.orange : Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                  ),
                                  child: const Text('حفظ المصروف', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────
  Widget _glassInput(TextEditingController c, String hint, {bool isNum = false, int maxLines = 1}) =>
    TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _brandColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _methodChip(String label, String val, String sel, Function(String) onTap, IconData icon) {
    final s = sel == val;
    return GestureDetector(
      onTap: () => onTap(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: s ? _brandColor : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: s ? _brandColor : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: s ? Colors.black : Colors.white54),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: s ? Colors.black : Colors.white60,
            fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إدارة المصروفات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExpenses, tooltip: 'تحديث'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : Column(children: [
              // ── KPI card ─────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF983F)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _brandColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('إجمالي المصروفات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${_total.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                      Text('${_filtered.length} سجل', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              // ── Category chips ────────────────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kExpenseCategories.length,
                  itemBuilder: (_, i) {
                    final cat = kExpenseCategories[i];
                    final isSel = _selectedCategory == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 14, color: isSel ? Colors.white : cat.color),
                        label: Text(cat.nameAr, style: TextStyle(
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                          fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: cat.color,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        onSelected: (_) => setState(() => _selectedCategory = cat.id),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ── List ───────────────────────────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long_outlined, size: 64,
                          color: isDark ? Colors.white12 : Colors.black12),
                        const SizedBox(height: 12),
                        Text('لا توجد مصروفات مسجلة',
                          style: TextStyle(color: isDark ? Colors.white30 : Colors.black26)),
                        const SizedBox(height: 4),
                        Text('اضغط + لإضافة مصروف جديد',
                          style: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 12)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, idx) {
                          final exp  = _filtered[idx];
                          final cat  = _catById(exp['category']?.toString() ?? 'misc');
                          final amt  = (exp['amount'] as num?)?.toDouble() ?? 0;
                          final date = (exp['expense_date'] ?? exp['created_at'] ?? '').toString().substring(0, 10);
                          final method = exp['payment_method']?.toString() ?? 'cash';
                          final methodLabel = method == 'card' ? 'بطاقة' : method == 'bank' ? 'تحويل' : 'نقداً';

                          return Dismissible(
                            key: ValueKey(exp['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: Text('هل تريد حذف "${exp['description']}"؟'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (_) => _deleteExpense(exp['id'].toString()),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(cat.icon, color: cat.color, size: 22),
                                ),
                                title: Text(exp['description']?.toString() ?? 'مصروف',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Row(children: [
                                  Text(date, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(cat.nameAr, style: TextStyle(fontSize: 9, color: cat.color, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(methodLabel, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : Colors.black26)),
                                ]),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${amt.toStringAsFixed(2)} ر.س',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade400)),
                                    if (exp['status'] == 'pending')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: const Text("بانتظار الموافقة", style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    if ((exp['vendor'] ?? '').toString().isNotEmpty)
                                      Text(exp['vendor'].toString(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : Colors.black38),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: _brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
