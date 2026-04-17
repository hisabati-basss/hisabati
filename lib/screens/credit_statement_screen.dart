import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class CreditStatementScreen extends StatefulWidget {
  const CreditStatementScreen({super.key});

  @override
  State<CreditStatementScreen> createState() => _CreditStatementScreenState();
}

class _CreditStatementScreenState extends State<CreditStatementScreen> {
  int _selectedTab = 0; // 0 = Clients (Receivables), 1 = Suppliers (Payables)
  
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
    
    // Clients are loaded directly — no dummy data

    if (_selectedTab == 0) {
      // Load Clients
      _partners = await db.query('clients');
    } else {
      // Load Suppliers
      _partners = await db.query('suppliers');
    }
    
    setState(() => _isLoading = false);
  }

  Future<double> _getPartnerBalance(String id, String type) async {
     final dbHelper = DatabaseHelper();
     final db = await dbHelper.database;
     if (type == 'supplier') {
        final res = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
        if (res.isNotEmpty) {
           return (res.first['balance'] as num).toDouble();
        }
     } else {
        // For clients, we estimate balance by finding total credit invoices minus payments
        final invoices = await db.query('invoices', where: 'client_id = ? AND payment_type = ?', whereArgs: [id, 'credit']);
        final payments = await db.query('payments', where: 'partner_id = ? AND type = ?', whereArgs: [id, 'receive']);
        
        double totalCredit = invoices.fold(0.0, (sum, item) => sum + ((item['total'] as num?) ?? 0.0));
        double totalPaid = payments.fold(0.0, (sum, item) => sum + ((item['amount'] as num?) ?? 0.0));
        return totalCredit - totalPaid;
     }
     return 0.0;
  }

  // Add a new supplier
  Future<void> _addSupplier() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.insert('suppliers', {
       'id': 'SUP_${DateTime.now().millisecondsSinceEpoch}',
       'name': 'مورد جديد (بضائع)',
       'contact_info': '050000000',
       'balance': 0.0,
    });
    _loadData();
  }

  // Create a credit purchase from a supplier
  Future<void> _makeCreditPurchase(String supplierId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.savePurchaseInvoice(
      supplierId: supplierId,
      total: 1150.0,
      paymentType: 'credit',
      lines: [
        {'item_id': 'ITEM_CREDIT_${DateTime.now().millisecondsSinceEpoch}', 'name': 'عملية شراء آجل', 'quantity': 1.0, 'price': 1150.0},
      ]
    );
    _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل فاتورة مشتريات (آجل) بنجاح')));
  }

  Future<void> _processPayment(String id, String name, double amount) async {
    final type = _selectedTab == 0 ? 'client' : 'supplier';
    final dbHelper = DatabaseHelper();
    await dbHelper.processPayment(
      partnerId: id,
      partnerType: type,
      amount: amount
    );
    _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(type == 'supplier' ? 'تم سداد الدفعة للمورد بنجاح' : 'تم تحصيل الدفعة بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Added padding
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("إدارة الائتمان", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)), // 📉 Reduced from 13
                    const SizedBox(height: 4),
                    Text(
                      "المديونية", // 📉 Shortened
                      style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold), // 📉 Reduced from 24/32
                    ),
                  ],
                ),
                _buildTabs(context, isMobile),
              ],
            ),
          ),
          const SizedBox(height: 20), // 📉 Reduced from 32
          
          if (_selectedTab == 1)
             Padding(
               padding: const EdgeInsets.only(bottom: 16),
               child: _buildCapsuleButton(context, icon: Icons.person_add, label: "إضافة مورد جديد", isPrimary: true, onTap: _addSupplier),
             ),

          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _partners.isEmpty 
               ? Center(child: Text("لا توجد بيانات حالياً", style: TextStyle(color: context.mutedText)))
               : ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _partners.length,
                   itemBuilder: (context, index) {
                      return _buildPartnerCard(context, _partners[index], isMobile);
                   },
                 ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(2), // 📉 Reduced from 4
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Consistent with AppTheme
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(context, "العملاء (ذمم مدينة)", 0, Icons.people_outline, isMobile),
          _buildTabButton(context, "الموردين (ذمم دائنة)", 1, Icons.business, isMobile),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index, IconData icon, bool isMobile) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 4), // 📉 Reduced from 16/8
        decoration: BoxDecoration(
          color: isSelected ? (_selectedTab == 0 ? Colors.greenAccent : Colors.redAccent) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Consistent with AppTheme
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSize - 2, color: isSelected ? Colors.black87 : context.mutedText), // 📉 Reduced from 16
            const SizedBox(width: 6), // 📉 Reduced from 8
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black87 : context.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: context.bodySize - 1, // 📉 Reduced from 12
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, Map<String, dynamic> partner, bool isMobile) {
    final type = _selectedTab == 0 ? 'client' : 'supplier';
    return FutureBuilder<double>(
      future: _getPartnerBalance(partner['id'], type),
      builder: (context, snapshot) {
         final balance = snapshot.data ?? 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8), // 📉 Reduced from 12
            padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 20
              border: Border.all(color: context.cardBorder),
            ),
           child: Row(
             children: [
                Container(
                  padding: const EdgeInsets.all(8), // 📉 Reduced from 12
                  decoration: BoxDecoration(
                    color: type == 'client' ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type == 'client' ? Icons.person : Icons.factory, color: type == 'client' ? Colors.greenAccent : Colors.redAccent, size: context.iconSize), // 📉 Added size
                ),
                const SizedBox(width: 12), // 📉 Reduced from 16
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(partner['name'] ?? 'بدون اسم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)), // 📉 Reduced from 16
                      Text(type == 'client' ? "له" : "عليه", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)), // 📉 Reduced from 12 + Shortened
                      Text(
                        "${balance.toStringAsFixed(2)} ر.س",
                        style: TextStyle(
                          color: balance > 0 ? (type == 'client' ? Colors.greenAccent : Colors.redAccent) : context.mutedText,
                          fontWeight: FontWeight.bold,
                          fontSize: context.headerSize, // 📉 Reduced from 18
                        ),
                      ),
                   ],
                 ),
               ),
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // WhatsApp icon
                    Container(
                      padding: const EdgeInsets.all(6), // 📉 Reduced from 8
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat, color: Colors.green, size: context.iconSize - 4), // 📉 Reduced from 18
                    ),
                    const SizedBox(width: 6), // 📉 Reduced from 8
                   if (type == 'supplier')
                      _buildCapsuleButton(
                         context, 
                         icon: Icons.add_shopping_cart, 
                         label: "شراء", 
                         isPrimary: false,
                         onTap: () => _makeCreditPurchase(partner['id']),
                      ),
                   const SizedBox(width: 8),
                   if (balance > 0)
                      _buildCapsuleButton(
                        context,
                        icon: type == 'client' ? Icons.call_received : Icons.payment,
                        label: type == 'client' ? "تحصيل" : "سداد",
                        isPrimary: true,
                        color: type == 'client' ? Colors.greenAccent : Colors.redAccent,
                        onTap: () => _processPayment(partner['id'], partner['name'], balance),
                      ),
                 ],
               ),
             ],
           ),
         );
      }
    );
  }

  Widget _buildCapsuleButton(BuildContext context, {required IconData icon, required String label, required bool isPrimary, required VoidCallback onTap, Color? color}) {
    Color baseColor = color ?? primaryOrange;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 📉 Reduced from 16/10
            decoration: BoxDecoration(
              color: isPrimary ? baseColor : baseColor.withValues(alpha: 0.05),
              border: Border.all(color: baseColor.withValues(alpha: isPrimary ? 0.0 : 0.3)),
              borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Consistent with AppTheme
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: context.iconSize - 4, color: isPrimary ? Colors.black87 : context.textColor), // 📉 Reduced from 14
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.black87 : context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: context.bodySize - 1, // 📉 Reduced from 12
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
