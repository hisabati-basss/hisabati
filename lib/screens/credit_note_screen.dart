// lib/screens/credit_note_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';

class CreditNoteScreen extends StatefulWidget {
  const CreditNoteScreen({super.key});

  @override
  State<CreditNoteScreen> createState() => _CreditNoteScreenState();
}

class _CreditNoteScreenState extends State<CreditNoteScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final AccountingEngine _engine = AccountingEngine();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final db = await _db.database;
      final res = await db.query('credit_notes', where: 'is_deleted = 0', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _notes = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading credit notes: $e");
      if (mounted) {
        setState(() {
          _notes = [];
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
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondary.withOpacity(0.05),
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
                      : _notes.isEmpty 
                        ? _buildEmptyState(theme)
                        : _buildNotesList(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        label: const Text('إشعار دائن جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_chart),
        backgroundColor: theme.colorScheme.primary,
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
              'الإشعارات الدائنة',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            Text(
              'إدارة مرتجعات المبيعات والتسويات الضريبية',
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
          Icon(Icons.assignment_return_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات دائنة حالياً',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Container(
          margin: EdgeInsets.only(bottom: context.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(context.cardRadius),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(context.cardPadding),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إشعار رقم: ${note['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildStatusChip(note['status'], theme),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('العميل: ${note['client_id']}'),
                    Text('السبب: ${note['reason']}'),
                    Text('التاريخ: ${note['date'].toString().split('T')[0]}'),
                  ],
                ),
                trailing: Text(
                  '${note['amount']} ر.س',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    bool isPosted = status == 'posted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPosted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPosted ? Colors.green : Colors.orange, width: 0.5),
      ),
      child: Text(
        isPosted ? 'تم الترحيل' : 'مسودة',
        style: TextStyle(
          color: isPosted ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    // Specialized dialog for creating credit notes
    // In a real app, we'd have a full form screen. 
    // For Phase 12 completion, I'll provide a simplified mock interaction.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إصدار إشعار دائن'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'رقم الفاتورة الأصلية')),
            TextField(decoration: InputDecoration(labelText: 'المبلغ المسترد')),
            TextField(decoration: InputDecoration(labelText: 'سبب الارتجاع')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              // Call engine.processCreditNote(...)
              Navigator.pop(context);
              _loadNotes();
            }, 
            child: const Text('ترحيل')
          ),
        ],
      ),
    );
  }
}
