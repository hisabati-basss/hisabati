// lib/screens/fiscal_year_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';

class FiscalYearScreen extends StatefulWidget {
  const FiscalYearScreen({super.key});

  @override
  State<FiscalYearScreen> createState() => _FiscalYearScreenState();
}

class _FiscalYearScreenState extends State<FiscalYearScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
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
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _years.isEmpty 
                        ? _buildEmptyState(theme)
                        : _buildYearsList(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, 
        label: const Text('فتح سنة مالية جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.calendar_today),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new)),
        Text('السنوات المالية', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text('إدارة الفترات المحاسبية والإقفال السنوي', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.teal.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('لم يتم تعريف سنوات مالية بعد'),
        ],
      ),
    );
  }

  Widget _buildYearsList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      itemCount: _years.length,
      itemBuilder: (context, index) {
        final year = _years[index];
        final bool isClosed = year['is_closed'] == 1;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.cardRadius),
            side: BorderSide(color: isClosed ? Colors.grey.withOpacity(0.2) : Colors.teal.withOpacity(0.3)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(context.cardPadding),
            title: Text(year['name'] ?? 'Undefined Year', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الفترة: ${year['start_date']} إلى ${year['end_date']}'),
            trailing: isClosed 
              ? const Icon(Icons.lock, color: Colors.grey)
              : ElevatedButton(
                  onPressed: () => _closeYear(year),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('إقفال السنة'),
                ),
          ),
        );
      },
    );
  }

  Future<void> _closeYear(Map<String, dynamic> year) async {
    final success = await _engine.closeFiscalYear(
      year['name'], 
      year['start_date'], 
      year['end_date']
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إقفال السنة المالية بنجاح'), backgroundColor: Colors.green));
      _loadYears();
    }
  }
}
