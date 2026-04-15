import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/database_helper.dart';

class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});
  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _affiliates = [];
  List<Map<String, dynamic>> _referrals = [];
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      // Check if tables exist, create if not
      await db.execute('''CREATE TABLE IF NOT EXISTS affiliates (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT, phone TEXT,
        referral_code TEXT UNIQUE, commission_rate REAL DEFAULT 0.1,
        total_sales REAL DEFAULT 0, total_earned REAL DEFAULT 0,
        status TEXT DEFAULT 'active', created_at TEXT
      )''');
      await db.execute('''CREATE TABLE IF NOT EXISTS affiliate_referrals (
        id TEXT PRIMARY KEY, affiliate_id TEXT, invoice_id TEXT,
        amount REAL DEFAULT 0, commission REAL DEFAULT 0,
        status TEXT DEFAULT 'pending', created_at TEXT,
        FOREIGN KEY (affiliate_id) REFERENCES affiliates(id)
      )''');

      _affiliates = (await db.query('affiliates', orderBy: 'total_earned DESC')).map((a) => Map<String, dynamic>.from(a)).toList();
      _referrals = (await db.rawQuery('''
        SELECT ar.*, af.name as affiliate_name FROM affiliate_referrals ar
        LEFT JOIN affiliates af ON ar.affiliate_id = af.id
        ORDER BY ar.created_at DESC LIMIT 50
      ''')).map((r) => Map<String, dynamic>.from(r)).toList();
      _totalEarnings = _affiliates.fold<double>(0, (s, a) => s + ((a['total_earned'] as num?)?.toDouble() ?? 0));
    } catch (e) { debugPrint("Affiliate: $e"); }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: "10");

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.cardSurface.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(tr('affiliate.add_partner_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(nameCtrl, tr('affiliate.name_req')),
        const SizedBox(height: 8),
        _input(emailCtrl, tr('affiliate.email')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _input(phoneCtrl, tr('affiliate.phone'))),
          const SizedBox(width: 8),
          Expanded(child: _input(rateCtrl, tr('affiliate.commission_rate_label'), isNum: true)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("إلغاء", style: TextStyle(color: context.mutedText))),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final db = await _db.database;
            final code = "AFF${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";
            await db.insert('affiliates', {
              'id': 'AFF_${DateTime.now().millisecondsSinceEpoch}',
              'name': nameCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
              'referral_code': code,
              'commission_rate': (double.tryParse(rateCtrl.text) ?? 10) / 100,
              'status': 'active',
              'created_at': DateTime.now().toIso8601String(),
            });
            if (mounted) { Navigator.pop(ctx); _loadData(); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.black87),
          child: const Text("حفظ"),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.sectionPadding, 8, context.sectionPadding, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('affiliate.program_title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
              Text("${_affiliates.length} ${tr('affiliate.partner_count_label')} • ${tr('affiliate.total_commissions_label')}: ${_totalEarnings.toStringAsFixed(0)}", style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1)),
            ])),
            GestureDetector(onTap: _showAddDialog, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_add, size: 14, color: Colors.black87), const SizedBox(width: 4), Text(tr('affiliate.new_partner_btn'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12))]),
            )),
          ]),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.sectionPadding, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
          child: TabBar(controller: _tabController, isScrollable: false, labelColor: Colors.black87, unselectedLabelColor: context.mutedText,
            indicator: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)), indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1),
            tabs: [Tab(text: tr('affiliate.tabs.partners')), Tab(text: tr('affiliate.tabs.referrals'))]),
        ),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : TabBarView(controller: _tabController, children: [_buildAffiliatesTab(), _buildReferralsTab()])),
      ]),
    );
  }

  Widget _buildAffiliatesTab() {
    if (_affiliates.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people, size: 48, color: context.mutedText.withValues(alpha: 0.2)), const SizedBox(height: 8),
      Text(tr('affiliate.empty_state'), style: TextStyle(color: context.mutedText)),
    ]));
    return ListView.builder(padding: EdgeInsets.all(context.sectionPadding), itemCount: _affiliates.length, itemBuilder: (_, i) {
      final a = _affiliates[i];
      final earned = (a['total_earned'] as num?)?.toDouble() ?? 0;
      final rate = ((a['commission_rate'] as num?)?.toDouble() ?? 0.1) * 100;
      final status = a['status']?.toString() ?? 'active';
      return Container(
        margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: context.cardBorder.withValues(alpha: 0.08))),
        child: Row(children: [
          Container(width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text("${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)),
            Text("${tr('affiliate.code_label')}: ${a['referral_code']} • ${tr('affiliate.commission_label')}: ${rate.toInt()}%", style: TextStyle(color: context.mutedText, fontSize: 10)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("${earned.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: context.bodySize + 1)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: (status == 'active' ? Colors.green : Colors.red).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(status == 'active' ? "نشط" : "معطل", style: TextStyle(color: status == 'active' ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold))),
          ]),
        ]),
      );
    });
  }

  Widget _buildReferralsTab() {
    if (_referrals.isEmpty) return Center(child: Text(tr('affiliate.no_referrals'), style: TextStyle(color: context.mutedText)));
    return ListView.builder(padding: EdgeInsets.all(context.sectionPadding), itemCount: _referrals.length, itemBuilder: (_, i) {
      final r = _referrals[i];
      return Container(
        margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.cardSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['affiliate_name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 1)),
            Text("${tr('accounting_module.actions.invoice')}: ${r['invoice_id'] ?? ''} • ${r['created_at']?.toString().substring(0, 10) ?? ''}", style: TextStyle(color: context.mutedText, fontSize: 10)),
          ])),
          Text("${((r['commission'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ]),
      );
    });
  }

  Widget _input(TextEditingController ctrl, String hint, {bool isNum = false}) => TextField(
    controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text,
    style: TextStyle(color: context.textColor, fontSize: 13),
    decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: context.mutedText, fontSize: 12),
      filled: true, fillColor: context.cardSurface.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
  );
}
