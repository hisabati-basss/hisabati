import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/cheque_service.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class ChequesScreen extends StatefulWidget {
  const ChequesScreen({super.key});

  @override
  State<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends State<ChequesScreen> {
  final ChequeService _chequeService = ChequeService();
  
  List<Map<String, dynamic>> _cheques = [];
  Map<String, double> _stats = {'receivable_pending': 0, 'payable_pending': 0, 'bounced_total': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cheques = await _chequeService.getAllCheques();
      final stats = await _chequeService.getChequeStats();
      setState(() {
        _cheques = cheques;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في جلب الشيكات: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton( // 📉 Slimmer
            onPressed: () => _showAddChequeDialog(context),
            backgroundColor: primaryOrange,
            mini: true, // 📉 Mini FAB
            child: Icon(Icons.add, color: Colors.white, size: context.iconSize - 4),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16), // 📉 Reduced from 24
                _buildDashboard(isMobile),
                const SizedBox(height: 20), // 📉 Reduced from 32
                _buildDesktopTable(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الشيكات", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Reduced/Shortened
            Text("نظام الإدارة المالية", style: TextStyle(fontSize: context.bodySize - 2, color: context.mutedText)), // 📉 Reduced from 14 + Shortened
          ],
        ),
      ],
    );
  }

  Widget _buildDashboard(bool isMobile) {
    return Wrap(
      spacing: 8, // 📉 Reduced from 16
      runSpacing: 16,
      children: [
        _buildStatCard("شيكات واردة (متوقعة)", _stats['receivable_pending']!, Icons.arrow_downward, Colors.green),
        _buildStatCard("شيكات صادرة (مطلوبة)", _stats['payable_pending']!, Icons.arrow_upward, Colors.orange),
        _buildStatCard("شيكات مرفوضة", _stats['bounced_total']!, Icons.error_outline, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      width: 110, // 📉 Reduced from 140
      padding: const EdgeInsets.all(8), // 📉 Reduced from cardPadding
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4), // 📉 Sharper
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.6), size: context.iconSize - 10), // 📉 Reduced
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: TextStyle(fontSize: context.bodySize - 5, color: context.mutedText), maxLines: 1)), // 📉 Reduced
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "${amount.toStringAsFixed(0)}",
            style: TextStyle(fontSize: context.bodySize + 1, fontWeight: FontWeight.bold, color: context.textColor), // 📉 Reduced
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
        border: Border.all(color: context.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMaxHeight: 22, // 📉 Reduced from 28
            dataRowMinHeight: 18, // 📉 Reduced from 20
            headingRowHeight: 26, // 📉 Reduced from 32
            horizontalMargin: 4, // 📉 Reduced from 6
            columnSpacing: 8, // 📉 Reduced from 10
            headingRowColor: WidgetStateProperty.all(context.bgSurface.withValues(alpha: 0.5)),
            columns: [
              DataColumn(label: Text("رقم", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))), // 📉 Shortened
              DataColumn(label: Text("النوع", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              DataColumn(label: Text("البنك", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              DataColumn(label: Text("الطرف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))), // 📉 Shortened
              DataColumn(label: Text("تاريخ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              DataColumn(label: Text("المبلغ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              DataColumn(label: Text("الحالة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))),
              DataColumn(label: Text("أمر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1))), // 📉 Shortened
            ],
            rows: _cheques.map((cheque) {
              Color statusColor = Colors.grey;
              if (cheque['status'] == ChequeService.STATUS_CLEARED) statusColor = Colors.green;
              if (cheque['status'] == ChequeService.STATUS_BOUNCED) statusColor = Colors.red;
              if (cheque['status'] == ChequeService.STATUS_PENDING) statusColor = Colors.orange;

              DateTime? dueDate = DateTime.tryParse(cheque['due_date'] ?? '');
              bool isPastDue = false;
              if (dueDate != null && cheque['status'] == ChequeService.STATUS_PENDING) {
                if (dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                  isPastDue = true;
                  statusColor = Colors.redAccent;
                }
              }

              return DataRow(cells: [
                DataCell(Text(cheque['cheque_number'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: context.bodySize - 3))), // 📉 Reduced
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 📉 Reduced
                  decoration: BoxDecoration(
                    color: cheque['type'] == ChequeService.TYPE_RECEIVABLE ? Colors.green.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(2), // 📉 Sharper
                  ),
                  child: Text(cheque['type'] == ChequeService.TYPE_RECEIVABLE ? "وارد" : "صادر", style: TextStyle(fontSize: context.bodySize - 5, color: cheque['type'] == ChequeService.TYPE_RECEIVABLE ? Colors.green : Colors.orange)), // 📉 Shortened
                )),
                DataCell(Text(cheque['bank_name'] ?? '', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 4))), // 📉 Reduced
                DataCell(Text(cheque['partner_name'] ?? '', style: TextStyle(color: context.textColor, fontSize: context.bodySize - 4))), // 📉 Reduced
                DataCell(Text(cheque['due_date']?.toString().split('T')[0] ?? '', style: TextStyle(color: isPastDue ? Colors.red : context.textColor, fontWeight: isPastDue ? FontWeight.bold : FontWeight.normal, fontSize: context.bodySize - 4))), // 📉 Reduced
                DataCell(Text("${cheque['amount']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 3))), // 📉 Reduced
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)), // 📉 Reduced
                    const SizedBox(width: 4),
                    Text(
                      isPastDue ? 'متأخر' : 
                      (cheque['status'] == ChequeService.STATUS_PENDING ? 'قيد الانتظار' :
                       cheque['status'] == ChequeService.STATUS_CLEARED ? 'مُحصّل' :
                       cheque['status'] == ChequeService.STATUS_BOUNCED ? 'مرتجع' : (cheque['status'] ?? '')),
                      style: TextStyle(color: statusColor, fontSize: context.bodySize - 4)
                    ),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cheque['status'] == ChequeService.STATUS_PENDING) ...[
                      Tooltip(
                        message: "تأكيد",
                        child: IconButton(
                          icon: Icon(Icons.check_circle_outline, color: Colors.green, size: context.iconSize),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await _chequeService.clearCheque(cheque['id']);
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "رفض",
                        child: IconButton(
                          icon: Icon(Icons.cancel_outlined, color: Colors.red, size: context.iconSize),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await _chequeService.bounceCheque(cheque['id']);
                            _loadData();
                          },
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.done_all, color: Colors.grey, size: context.iconSize),
                    ]
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddChequeDialog(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final clients = await dbHelper.getClients();
    final suppliers = await dbHelper.getSuppliers();
    final accounts = await db.query('accounts', where: "type = 'asset'");

    final numberCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    String type = ChequeService.TYPE_RECEIVABLE;
    
    String? selectedPartnerId = clients.isNotEmpty ? clients.first['id']?.toString() : null;
    String? selectedPartnerName = clients.isNotEmpty ? clients.first['name']?.toString() : 'عميل غير معروف';
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first['id']?.toString() : null;
    String? selectedAccountName = accounts.isNotEmpty ? accounts.first['name']?.toString() : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final List<Map<String, dynamic>> currentPartners = type == ChequeService.TYPE_RECEIVABLE ? clients : suppliers;

          return AlertDialog(
            backgroundColor: context.bgSurface,
            title: const Text("إضافة شيك جديد"),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: "نوع الشيك"),
                      items: const [
                        DropdownMenuItem(value: ChequeService.TYPE_RECEIVABLE, child: Text("شيك وارد (من عميل)")),
                        DropdownMenuItem(value: ChequeService.TYPE_PAYABLE, child: Text("شيك صادر (لمورد)")),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          type = val!;
                          final nextPartners = type == ChequeService.TYPE_RECEIVABLE ? clients : suppliers;
                          if (nextPartners.isNotEmpty) {
                            selectedPartnerId = nextPartners.first['id'];
                            selectedPartnerName = nextPartners.first['name'];
                          } else {
                            selectedPartnerId = null;
                            selectedPartnerName = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPartnerId,
                      decoration: InputDecoration(labelText: type == ChequeService.TYPE_RECEIVABLE ? "اختر العميل" : "اختر المورد"),
                      items: currentPartners.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] as String))).toList(),
                      hint: const Text("اختر الطرف الثاني"),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedPartnerId = val;
                          selectedPartnerName = currentPartners.firstWhere((p) => p['id']?.toString() == val)['name']?.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numberCtrl,
                      decoration: const InputDecoration(labelText: "رقم الشيك (Cheque No)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(labelText: "البنك المسحوب عليه/له", border: OutlineInputBorder()),
                      items: accounts.map((a) => DropdownMenuItem(value: a['id']?.toString(), child: Text(a['name']?.toString() ?? ''))).toList(),
                      hint: const Text("اختر حساب البنك"),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedAccountId = val;
                          selectedAccountName = accounts.firstWhere((a) => a['id']?.toString() == val)['name']?.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "المبلغ", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("تاريخ الاستحقاق"),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () async {
                  if (numberCtrl.text.isEmpty || amountCtrl.text.isEmpty || selectedPartnerId == null || selectedAccountId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء كافة الحقول واختيار الطرف الثاني والبنك")));
                    return;
                  }
                  
                  await _chequeService.addCheque(
                    chequeNumber: numberCtrl.text,
                    bankName: selectedAccountName ?? 'غير معروف',
                    amount: double.tryParse(amountCtrl.text) ?? 0,
                    issueDate: DateTime.now(),
                    dueDate: dueDate,
                    type: type,
                    partnerId: selectedPartnerId!,
                    partnerName: selectedPartnerName ?? 'غير معروف',
                    partnerType: type == ChequeService.TYPE_RECEIVABLE ? 'client' : 'supplier',
                  );
                  
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إضافة الشيك وتوليد القيود بنجاح")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white),
                child: const Text("حفظ الشيك"),
              ),
            ],
          );
        }
      ),
    );
  }
}
