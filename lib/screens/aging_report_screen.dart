// lib/screens/aging_report_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class AgingReportScreen extends StatefulWidget {
  const AgingReportScreen({super.key});

  @override
  State<AgingReportScreen> createState() => _AgingReportScreenState();
}

class _AgingReportScreenState extends State<AgingReportScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgingReport();
  }

  Future<void> _loadAgingReport() async {
    try {
      // Specialized query for aging report
      final db = await _db.database;
      final res = await db.query('clients', where: 'balance > 0');
      if (mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading aging report: $e");
      if (mounted) {
        setState(() {
          _reportData = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(decoration: BoxDecoration(color: theme.colorScheme.surface))),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: context.sectionPadding),
                  _buildAgingSummary(context, theme),
                  SizedBox(height: context.sectionPadding),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAgingList(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new)),
        Text('أعمار ديون العملاء', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text('متابعة التحصيل والمبالغ المتأخرة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAgingSummary(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        _buildAgingBox(context, '30+ يوم', '12,500', Colors.orange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '60+ يوم', '8,200', Colors.deepOrange),
        SizedBox(width: context.cardPadding / 2),
        _buildAgingBox(context, '90+ يوم', '4,100', Colors.red),
      ],
    );
  }

  Widget _buildAgingBox(BuildContext context, String label, String amount, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(context.cardPadding / 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.cardRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      itemCount: _reportData.length,
      itemBuilder: (context, index) {
        final client = _reportData[index];
        return Card(
          child: ListTile(
            title: Text(client['name'] ?? 'Undefined', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الرصيد الكلي: ${client['balance']} ر.س'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}
