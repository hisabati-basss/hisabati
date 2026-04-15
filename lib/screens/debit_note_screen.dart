// lib/screens/debit_note_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../core/accounting/accounting_engine.dart';
import '../theme/app_theme_extension.dart';

class DebitNoteScreen extends StatefulWidget {
  const DebitNoteScreen({super.key});

  @override
  State<DebitNoteScreen> createState() => _DebitNoteScreenState();
}

class _DebitNoteScreenState extends State<DebitNoteScreen> {
  final DatabaseHelper _db = DatabaseHelper();
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
      final res = await db.query('debit_notes', where: 'is_deleted = 0', orderBy: 'created_at DESC');
      if (mounted) {
        setState(() {
          _notes = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading debit notes: $e");
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.05),
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
        onPressed: () {}, // Trigger Debit Note creation flow
        label: const Text('إشعار مدين جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.outbox_rounded),
        backgroundColor: theme.colorScheme.secondary,
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
              'الإشعارات المدينة',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'إدارة مرتجعات المشتريات والتسويات مع الموردين',
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
          Icon(Icons.inventory_2_outlined, size: 80, color: theme.colorScheme.secondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات مدينة حالياً',
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
            border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListTile(
                contentPadding: EdgeInsets.all(context.cardPadding),
                title: Text(
                  'إشعار رقم: ${note['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('المورد: ${note['supplier_id']}'),
                    Text('السبب: ${note['reason']}'),
                    Text('التاريخ: ${note['date'].toString().split('T')[0]}'),
                  ],
                ),
                trailing: Text(
                  '${note['amount']} ر.س',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
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
}
