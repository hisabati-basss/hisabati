import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/cheque_service.dart';
import '../services/database_helper.dart';
import '../services/reporting_service.dart';
import '../theme/app_theme_extension.dart';

class ChequesScreen extends StatefulWidget {
  const ChequesScreen({super.key});

  @override
  State<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends State<ChequesScreen> {
  final ChequeService _chequeService = ChequeService();
  final ReportingService _reportingService = ReportingService();
  
  List<Map<String, dynamic>> _cheques = [];
  Map<String, double> _stats = {
    'receivable_pending': 0, 
    'payable_pending': 0, 
    'bounced_total': 0,
    'cleared_total': 0
  };
  bool _isLoading = true;
  DateTimeRange? _selectedRange;

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
          floatingActionButton: FloatingActionButton( 
            onPressed: () => _showAddChequeDialog(context),
            backgroundColor: primaryOrange,
            mini: true, 
            child: Icon(Icons.add, color: Colors.white, size: context.iconSize - 4),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(context.sectionPadding), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16), 
                _buildDashboard(isMobile),
                const SizedBox(height: 20), 
                _buildDesktopTable(constraints.maxWidth),
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
            Text("الشيكات", style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor)), 
            Text("نظام الإدارة المالية", style: TextStyle(fontSize: context.bodySize - 2, color: context.mutedText)), 
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showReportFilter,
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text("تقرير الفترة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                foregroundColor: context.textColor,
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReportFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now().add(const Duration(days: 30))),
    );

    if (picked != null) {
      final cheques = await _chequeService.getChequesReport(picked.start, picked.end);
      if (cheques.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد شيكات في هذه الفترة")));
        return;
      }
      final periodStr = "${DateFormat('yyyy/MM/dd').format(picked.start)} - ${DateFormat('yyyy/MM/dd').format(picked.end)}";
      await _reportingService.generateChequeReportPDF(cheques: cheques, period: periodStr);
    }
  }

  Widget _buildDashboard(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard("شيكات واردة", _stats['receivable_pending']!, Icons.account_balance_wallet, [Colors.green.shade700, Colors.teal.shade400]),
          const SizedBox(width: 12),
          _buildStatCard("شيكات صادرة", _stats['payable_pending']!, Icons.payments, [Colors.orange.shade700, Colors.amber.shade400]),
          const SizedBox(width: 12),
          _buildStatCard("شيكات مُحصّلة", _stats['cleared_total']!, Icons.verified_user, [Colors.blue.shade700, Colors.indigo.shade400]),
          const SizedBox(width: 12),
          _buildStatCard("شيكات مرفوضة", _stats['bounced_total']!, Icons.report_problem, [Colors.red.shade700, Colors.pink.shade400]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, List<Color> colors) {
    return Container(
      width: 200,
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0].withValues(alpha: 0.8), colors[1].withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 60, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat("#,###.##").format(amount),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(double maxWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: maxWidth - (context.sectionPadding * 2)),
            child: DataTable(
              dataRowMaxHeight: 50,
              dataRowMinHeight: 45,
              headingRowHeight: 50,
              horizontalMargin: 16,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(context.bgSurface.withValues(alpha: 0.8)),
              columns: [
                DataColumn(label: Text("رقم", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("النوع", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("البنك", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("الطرف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("تاريخ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("المبلغ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("الحالة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
                DataColumn(label: Text("أوامر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize))),
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
                  DataCell(Text(cheque['cheque_number'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: context.bodySize - 1))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cheque['type'] == ChequeService.TYPE_RECEIVABLE ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(cheque['type'] == ChequeService.TYPE_RECEIVABLE ? "وارد" : "صادر", style: TextStyle(fontSize: context.bodySize - 2, color: cheque['type'] == ChequeService.TYPE_RECEIVABLE ? Colors.green : Colors.orange)),
                  )),
                  DataCell(Text(cheque['bank_name'] ?? '', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2))),
                  DataCell(Text(cheque['partner_name'] ?? '', style: TextStyle(color: context.textColor, fontSize: context.bodySize - 2))),
                  DataCell(Text(cheque['due_date']?.toString().split('T')[0] ?? '', style: TextStyle(color: isPastDue ? Colors.red : context.textColor, fontWeight: isPastDue ? FontWeight.bold : FontWeight.normal, fontSize: context.bodySize - 2))),
                  DataCell(Text(NumberFormat("#,###.##").format(cheque['amount']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1, color: primaryOrange))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        isPastDue ? 'متأخر' : 
                        (cheque['status'] == ChequeService.STATUS_PENDING ? 'قيد الانتظار' :
                         cheque['status'] == ChequeService.STATUS_CLEARED ? 'مُحصّل' :
                         cheque['status'] == ChequeService.STATUS_BOUNCED ? 'مرتجع' : (cheque['status'] ?? '')),
                        style: TextStyle(color: statusColor, fontSize: context.bodySize - 2)
                      ),
                    ],
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cheque['status'] == ChequeService.STATUS_PENDING) ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                          onPressed: () async {
                            await _chequeService.clearCheque(cheque['id']);
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                          onPressed: () async {
                            await _chequeService.bounceCheque(cheque['id']);
                            _loadData();
                          },
                        ),
                      ] else ...[
                        const Icon(Icons.done_all_rounded, color: Colors.blueGrey, size: 22),
                      ]
                    ],
                  )),
                ]);
              }).toList(),
            ),
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
