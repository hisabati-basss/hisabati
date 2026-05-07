// lib/screens/fiscal_year_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../services/fiscal_year_service.dart';
import '../theme/app_theme_extension.dart';

class FiscalYearScreen extends StatefulWidget {
  const FiscalYearScreen({super.key});

  @override
  State<FiscalYearScreen> createState() => _FiscalYearScreenState();
}

class _FiscalYearScreenState extends State<FiscalYearScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final FiscalYearService _fyService = FiscalYearService();
  List<Map<String, dynamic>> _years = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    try {
      final db = await _db.database;
      final res = await db.query('fiscal_years', orderBy: 'end_date DESC');
      if (mounted) {
        setState(() {
          _years = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading fiscal years: $e");
      if (mounted) {
        setState(() {
          _years = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Column(
                  children: [
                    // Enhanced Header with Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: context.mutedText),
                            style: IconButton.styleFrom(
                              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isAr ? "السنوات المالية" : "Fiscal Years",
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_month, color: primaryOrange, size: 20),
                                ],
                              ),
                              Text(isAr ? "إدارة الفترات المحاسبية" : "Accounting Period Management", style: TextStyle(color: context.mutedText, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Glass Summary KPI
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildGlassKPI(isDark, isAr),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                        : _years.isEmpty 
                          ? _buildEmptyState(context, isAr)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _years.length,
                              itemBuilder: (context, index) => _buildCompactYearItem(isDark, _years[index], isAr),
                            ),
                    ),
                    
                    // Bottom Glass Action Bar
                    _buildBottomAction(isDark, isAr),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassKPI(bool isDark, bool isAr) {
    int openYears = _years.where((y) => y['is_closed'] == 0).length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMiniKPI(isAr ? "سنوات مفتوحة" : "Open Years", openYears.toDouble(), primaryOrange, isAr)),
              Container(width: 1, height: 20, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
              Expanded(child: _buildMiniKPI(isAr ? "الإجمالي" : "Total", _years.length.toDouble(), Colors.blue, isAr)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniKPI(String label, double value, Color color, bool isAr) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.mutedText, fontSize: 9)),
        Text(
          value.toStringAsFixed(0), 
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildCompactYearItem(bool isDark, Map<String, dynamic> year, bool isAr) {
    final bool isClosed = year['is_closed'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isClosed 
          ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
          : primaryOrange.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isClosed ? Colors.grey.withValues(alpha: 0.1) : primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isClosed ? Icons.lock_outline : Icons.lock_open_rounded, 
              color: isClosed ? Colors.grey : primaryOrange, 
              size: 16
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(year['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  isAr 
                    ? 'الفترة: ${year['start_date']} إلى ${year['end_date']}'
                    : 'Period: ${year['start_date']} to ${year['end_date']}', 
                  style: TextStyle(color: context.mutedText, fontSize: 8)
                ),
              ],
            ),
          ),
          if (!isClosed)
            GestureDetector(
              onTap: () => _closeYear(year, isAr),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAr ? "إقفال السنة" : "Close Year",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
             Text(
               isAr ? "مقفل" : "Closed",
               style: TextStyle(color: context.mutedText, fontSize: 10),
             ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isDark, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _showAddYearDialog,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: primaryOrange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: primaryOrange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? "فتح سنة مالية جديدة" : "Open New Fiscal Year",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _closeYear(Map<String, dynamic> year, bool isAr) async {
    try {
      await _fyService.closeFiscalYear(year['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم إقفال السنة المالية بنجاح وترحيل الأرباح' : 'Fiscal year closed and profits transferred successfully'), 
          backgroundColor: Colors.green
        ));
        _loadYears();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'خطأ أثناء الإقفال: $e' : 'Error during closing: $e'), 
          backgroundColor: Colors.redAccent
        ));
      }
    }
  }

  void _showAddYearDialog() {
    bool isAr = context.locale.languageCode == 'ar';
    final nameController = TextEditingController(text: isAr ? 'سنة ${DateTime.now().year}' : 'Year ${DateTime.now().year}');
    final startController = TextEditingController(text: '${DateTime.now().year}-01-01');
    final endController = TextEditingController(text: '${DateTime.now().year}-12-31');

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isAr ? 'فتح سنة مالية جديدة' : 'Open New Fiscal Year', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, isAr ? 'اسم السنة' : 'Year Name'),
              const SizedBox(height: 12),
              _buildDialogField(startController, isAr ? 'تاريخ البداية (YYYY-MM-DD)' : 'Start Date'),
              const SizedBox(height: 12),
              _buildDialogField(endController, isAr ? 'تاريخ النهاية (YYYY-MM-DD)' : 'End Date'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: context.mutedText))),
            ElevatedButton(
              onPressed: () async {
                await _addYear(nameController.text, startController.text, endController.text);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: context.mutedText),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _addYear(String name, String start, String end) async {
    final db = await _db.database;
    await db.insert('fiscal_years', {
      'id': 'FY_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'start_date': start,
      'end_date': end,
      'is_closed': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    _loadYears();
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 40, color: context.mutedText.withValues(alpha: 0.2)),
          Text(isAr ? "لم يتم تعريف سنوات مالية" : "No Fiscal Years Defined", style: TextStyle(color: context.mutedText, fontSize: 12)),
        ],
      ),
    );
  }
}
