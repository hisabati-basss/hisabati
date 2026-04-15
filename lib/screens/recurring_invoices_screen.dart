// lib/screens/recurring_invoices_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class RecurringInvoicesScreen extends StatefulWidget {
  const RecurringInvoicesScreen({super.key});

  @override
  State<RecurringInvoicesScreen> createState() => _RecurringInvoicesScreenState();
}

class _RecurringInvoicesScreenState extends State<RecurringInvoicesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _recurring = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecurring();
  }

  Future<void> _loadRecurring() async {
    final db = await _db.database;
    final res = await db.query('recurring_transactions');
    setState(() {
      _recurring = res;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.05),
                    theme.colorScheme.surface,
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
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
                      : _recurring.isEmpty 
                        ? _buildEmptyState(theme)
                        : _buildRecurringList(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, 
        label: const Text('إعداد تكرار جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.autorenew),
        backgroundColor: Colors.purpleAccent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفواتير المتكررة',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'أتمتة الفواتير الدورية والاشتراكات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.purple.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير متكررة نشطة',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      itemCount: _recurring.length,
      itemBuilder: (context, index) {
        final item = _recurring[index];
        return Card(
          elevation: 0,
          color: theme.colorScheme.surface.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.cardRadius),
            side: BorderSide(color: Colors.purple.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(context.cardPadding),
            leading: const CircleAvatar(
              backgroundColor: Colors.purpleAccent,
              child: Icon(Icons.replay, color: Colors.white),
            ),
            title: Text(
              'تكرار ${item['frequency']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('التشغيل القادم: ${item['next_run_date'] ?? 'N/A'}'),
            trailing: Switch(
              value: item['is_active'] == 1,
              onChanged: (val) {},
              activeColor: Colors.purpleAccent,
            ),
          ),
        );
      },
    );
  }
}
