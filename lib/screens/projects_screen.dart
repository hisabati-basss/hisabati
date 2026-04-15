import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects([String query = '']) async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper();
    
    // Artificial delay for UI smoothness
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final projects = await dbHelper.getProjects();
      
      // Filter by query if needed
      final filtered = projects.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      // Map financials
      List<Map<String, dynamic>> enrichedProjects = [];
      for (var p in filtered) {
        final financials = await dbHelper.getProjectFinancials(p['id']);
        enrichedProjects.add({
          ...p,
          'financials': financials,
        });
      }

      // Seed dummy data if empty for preview
      if (enrichedProjects.isEmpty && query.isEmpty) {
        final db = await dbHelper.database;
        await db.insert('projects', {
          'id': 'PRJ_001',
          'name': 'مشروع مجمع الرياض السكني',
          'budget_amount': 2500000.0,
          'cost_center_id': 'CC_RYD_01',
          'start_date': '2026-01-01',
          'end_date': '2026-12-31',
          'status': 'active',
        });
        await db.insert('projects', {
          'id': 'PRJ_002',
          'name': 'كوبري مسار الملك سلمان',
          'budget_amount': 8000000.0,
          'cost_center_id': 'CC_KSD_02',
          'start_date': '2025-06-01',
          'end_date': '2027-06-01',
          'status': 'active',
        });
        
        // Seed Dummy expenses to show actual cost on PRJ_001
        final entryId = 'JE_DEMO_PRJ_001';
        await db.insert('journal_entries', {'id': entryId, 'date': '2026-02-10', 'description': 'فاتورة حديد تسليح للمجمع'});
        await db.insert('journal_entry_lines', {'id': '${entryId}_1', 'entry_id': entryId, 'account_id': 'ACC_COGS', 'debit': 2100000.0, 'project_id': 'PRJ_001'});
        
        // Run internal load again
        if (mounted) setState(() => _isLoading = false);
        _loadProjects();
        return;
      }

      if (mounted) {
        setState(() {
          _projects = enrichedProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading projects: $e");
      if (mounted) {
        setState(() {
          _projects = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddProjectModal() async {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final costCenterCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)), // 📉 Reduced from 20
        title: Text('إضافة مشروع', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)), // 📉 Reduced + Shortened
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المشروع'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(labelText: 'الميزانية التقديرية (ريال)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costCenterCtrl,
              decoration: const InputDecoration(labelText: 'رمز مركز التكلفة (مثال: CC-01)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && budgetCtrl.text.isNotEmpty) {
                await DatabaseHelper().createProject({
                  'id': 'PRJ_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text,
                  'budget_amount': double.tryParse(budgetCtrl.text) ?? 0.0,
                  'cost_center_id': costCenterCtrl.text,
                  'start_date': DateTime.now().toIso8601String().split('T')[0],
                  'status': 'active'
                });
                Navigator.pop(ctx);
                _loadProjects();
              }
            },
            child: const Text('حفظ المشروع', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.sectionPadding), // 📉 Reduced from 24
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Search
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => _loadProjects(val),
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: "بحث...", // 📉 Shortened
                        hintStyle: TextStyle(color: context.mutedText, fontSize: context.bodySize),
                        prefixIcon: Icon(Icons.search, color: context.mutedText, size: context.iconSize - 4), // 📉 Reduced from 18
                        fillColor: context.cardSurface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4), // 📉 Reduced height from 8
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
                          borderSide: BorderSide(color: context.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.cardRadius),
                          borderSide: BorderSide(color: context.cardBorder.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.cardRadius),
                          borderSide: const BorderSide(color: Color(0xFFFFB800)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Add Project Button
              ClipRRect(
                borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: InkWell(
                    onTap: _showAddProjectModal,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(context.cardRadius),
                        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Icon(Icons.add_business, color: const Color(0xFFFFB800), size: context.iconSize),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            "المشاريع",
            style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),

          // Glass Cards List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB800)))
              : _projects.isEmpty
                ? Center(
                    child: Text(
                      "لا توجد مشاريع متعاقد عليها.", 
                      style: TextStyle(color: context.mutedText, fontSize: 16)
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      final financials = project['financials'] as Map<String, dynamic>;
                      final spentPercentage = financials['spent_percentage'] as double;
                      final isCritical = financials['is_critical'] as bool;
                      final primaryColor = isCritical ? Colors.redAccent : Colors.tealAccent;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(context.cardRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Container(
                            padding: EdgeInsets.all(context.cardPadding),
                            decoration: BoxDecoration(
                              color: context.cardSurface,
                              borderRadius: BorderRadius.circular(context.cardRadius),
                              border: Border.all(color: isCritical ? Colors.red.withValues(alpha: 0.5) : context.cardBorder.withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)
                                )
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['name'] ?? '',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize + 1),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'مركز التكلفة : ${project['cost_center_id'] ?? '-'}',
                                            style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        "${(spentPercentage * 100).toStringAsFixed(1)}%",
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: context.bodySize - 2),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('التكلفة الفعلية', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)), // 📉 Reduced from 10 + Shortened
                                        const SizedBox(height: 2),
                                        Text(
                                          "${financials['actual_cost'].toStringAsFixed(2)}", 
                                          style: TextStyle(fontSize: context.bodySize, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : context.textColor) // 📉 Reduced from 14
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('المیزانية', style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 3)), // 📉 Reduced from 10 + Shortened
                                        const SizedBox(height: 2),
                                        Text(
                                          "${financials['budget'].toStringAsFixed(2)}", 
                                          style: TextStyle(fontSize: context.bodySize, fontWeight: FontWeight.bold) // 📉 Reduced from 14
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: spentPercentage.clamp(0.0, 1.0),
                                    backgroundColor: context.cardSurface.withValues(alpha: 0.5),
                                    color: primaryColor,
                                    minHeight: 6, // 📉 Reduced from 8
                                  ),
                                ),
                                if (isCritical)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0), // 📉 Reduced from 12
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: context.iconSize - 2), // 📉 Reduced from 16
                                        const SizedBox(width: 4), // 📉 Reduced from 6
                                        Expanded(child: Text("تنبيه: تجاوزت المصروفات 80% من الميزانية!", style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.9), fontSize: context.bodySize - 2))), // 📉 Reduced + Shortened
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
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
