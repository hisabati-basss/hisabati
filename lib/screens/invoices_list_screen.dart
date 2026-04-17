import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';
import 'invoice_entry_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final db = DatabaseHelper();
      final res = await (await db.database).query('invoices', orderBy: 'issue_date DESC');
      if (mounted) {
        setState(() {
          _invoices = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading invoices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Add Button
        Padding(
          padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24/16
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("سجل الفواتير", style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold, color: context.textColor)), // 📉 Reduced from 24
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceEntryScreen()));
                  _loadInvoices(); // Refresh after return
                },
                icon: Icon(Icons.add, size: context.iconSize - 4), // 📉 Reduced
                label: Text("إضافة", style: TextStyle(fontSize: context.bodySize - 1, fontWeight: FontWeight.bold)), // 📉 Smaller + Shortened
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 📉 Tightened
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 100
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: primaryOrange))
            : _invoices.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: context.sectionPadding), // 📉 Reduced from 24
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) => _buildInvoiceCard(_invoices[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: context.mutedText.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text("لا يوجد سجل فواتير حالياً", style: TextStyle(color: context.mutedText)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), // 📉 Reduced from 8
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 20
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // 📉 Reduced from 8
                decoration: BoxDecoration(color: primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.receipt, color: primaryOrange, size: context.iconSize - 2), // 📉 reduced from 20
              ),
              const SizedBox(width: 10), // 📉 Reduced from 12
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("#${(invoice['id'] ?? 'N/A').toString()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)), // 📉 Smaller
                  Text(invoice['issue_date'] != null ? invoice['issue_date'].toString().split('T')[0] : "---", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)), // 📉 Reduced from 12
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${double.tryParse(invoice['total']?.toString() ?? '0') ?? 0.0}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)), // 📉 Smaller/Simplified
              const SizedBox(height: 2), // 📉 Reduced from 4
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // 📉 Reduced
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(context.cardRadius / 2)),
                child: Text((invoice['status'] ?? "مكتمل").toString(), style: TextStyle(color: Colors.green, fontSize: context.bodySize - 4, fontWeight: FontWeight.bold)), // 📉 Reduced from 10
              ),
            ],
          ),
        ],
      ),
    );
  }
}
