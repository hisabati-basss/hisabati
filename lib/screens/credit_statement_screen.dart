import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import 'hr/loan_installments_screen.dart';

class CreditStatementScreen extends StatefulWidget {
  const CreditStatementScreen({super.key});

  @override
  State<CreditStatementScreen> createState() => _CreditStatementScreenState();
}

class _CreditStatementScreenState extends State<CreditStatementScreen> {
  int _selectedTab = 0; // 0 = Clients, 1 = Suppliers, 2 = Employee Loans
  
  List<Map<String, dynamic>> _partners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    if (_selectedTab == 0) {
      _partners = await db.query('clients');
    } else if (_selectedTab == 1) {
      _partners = await db.query('suppliers');
    } else {
      _partners = await db.rawQuery('''
        SELECT el.*, e.name as employee_name 
        FROM employee_loans el 
        JOIN employees e ON el.employee_id = e.id 
        WHERE el.is_deleted = 0
      ''');
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<double> _getPartnerBalance(String id, String type) async {
     final dbHelper = DatabaseHelper();
     final db = await dbHelper.database;
     if (type == 'supplier') {
        final res = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
        return res.isNotEmpty ? (res.first['balance'] as num).toDouble() : 0.0;
     } else if (type == 'client') {
        final invoices = await db.query('invoices', where: 'client_id = ? AND payment_type = ?', whereArgs: [id, 'credit']);
        final payments = await db.query('payments', where: 'partner_id = ? AND type = ?', whereArgs: [id, 'receive']);
        double totalCredit = invoices.fold(0.0, (sum, item) => sum + ((item['total'] as num?) ?? 0.0));
        double totalPaid = payments.fold(0.0, (sum, item) => sum + ((item['amount'] as num?) ?? 0.0));
        return totalCredit - totalPaid;
     }
     return 0.0;
  }

  Future<void> _processPayment(String id, String name, double amount) async {
    final type = _selectedTab == 0 ? 'client' : 'supplier';
    final dbHelper = DatabaseHelper();
    await dbHelper.processPayment(
      paymentId: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
      partnerId: id,
      amount: amount,
      type: type == 'client' ? 'receive' : 'pay',
      dateIso: DateTime.now().toIso8601String(),
    );
    _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(type == 'supplier' ? 'تم سداد الدفعة للمورد بنجاح' : 'تم تحصيل الدفعة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 20),
          
          if (_isLoading) 
            const Center(child: CircularProgressIndicator())
          else if (_partners.isEmpty) 
            Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text("لا توجد بيانات حالياً", style: TextStyle(color: context.mutedText)),
            ))
          else 
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _partners.length,
              itemBuilder: (context, index) => _buildPartnerCard(context, _partners[index], isMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("إدارة الائتمان", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
              const SizedBox(height: 4),
              Text("المديونية والذمم", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
            ],
          ),
          _buildTabs(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(context, "العملاء", 0, Icons.people_outline, isMobile),
          _buildTabButton(context, "الموردين", 1, Icons.business, isMobile),
          _buildTabButton(context, "سلف الموظفين", 2, Icons.badge_outlined, isMobile),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index, IconData icon, bool isMobile) {
    bool isSelected = _selectedTab == index;
    Color activeColor = _selectedTab == 0 ? Colors.greenAccent : (_selectedTab == 1 ? Colors.redAccent : Colors.indigoAccent);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.cardRadius - 4),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSize - 4, color: isSelected ? activeColor : context.mutedText),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : context.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: context.bodySize - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, Map<String, dynamic> partner, bool isMobile) {
    final type = _selectedTab == 0 ? 'client' : (_selectedTab == 1 ? 'supplier' : 'loan');
    
    return FutureBuilder<double>(
      future: type == 'loan' ? Future.value((partner['balance'] as num?)?.toDouble() ?? 0.0) : _getPartnerBalance(partner['id'], type),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        final Color themeColor = type == 'client' ? Colors.greenAccent : (type == 'supplier' ? Colors.redAccent : Colors.indigoAccent);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: context.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(type == 'client' ? Icons.person : (type == 'supplier' ? Icons.factory : Icons.badge), color: themeColor, size: context.iconSize),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(type == 'loan' ? (partner['employee_name'] ?? 'موظف') : (partner['name'] ?? 'بدون اسم'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (type == 'loan' && balance > 0) ...[
                           const SizedBox(width: 8),
                           _buildLateBadge(partner['start_date']),
                        ],
                      ],
                    ),
                    Text(type == 'client' ? "له" : (type == 'supplier' ? "عليه" : "قرض مستحق"), style: TextStyle(color: context.mutedText, fontSize: 12)),
                    Text(
                      "${balance.toStringAsFixed(2)} ر.س",
                      style: TextStyle(color: balance > 0 ? themeColor : context.mutedText, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'loan')
                    _buildCapsuleButton(
                      context,
                      icon: Icons.history,
                      label: "الأقساط",
                      isPrimary: false,
                      color: Colors.indigoAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => LoanInstallmentsScreen(
                        loanId: partner['id'],
                        employeeName: partner['employee_name'] ?? 'موظف',
                        totalAmount: (partner['amount'] as num?)?.toDouble() ?? 0.0,
                      ))),
                    )
                  else if (balance > 0)
                    _buildCapsuleButton(
                      context,
                      icon: type == 'client' ? Icons.call_received : Icons.payment,
                      label: type == 'client' ? "تحصيل" : "سداد",
                      isPrimary: true,
                      color: themeColor,
                      onTap: () => _processPayment(partner['id'], partner['name'], balance),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapsuleButton(BuildContext context, {required IconData icon, required String label, required bool isPrimary, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.black87 : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: isPrimary ? Colors.black87 : color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLateBadge(dynamic startDate) {
    if (startDate == null) return const SizedBox();
    final date = DateTime.tryParse(startDate.toString());
    if (date == null) return const SizedBox();
    
    // If start date is more than 30 days ago, consider it "Active" but needs checking
    final isOld = DateTime.now().difference(date).inDays > 30;
    if (!isOld) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
      child: const Text("متأخر", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
