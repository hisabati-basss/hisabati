import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../services/gmail_service.dart';
import '../services/ocr_service.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme_extension.dart';

class CloudInboxScreen extends StatefulWidget {
  final bool isMobile;
  const CloudInboxScreen({super.key, this.isMobile = false});

  @override
  State<CloudInboxScreen> createState() => _CloudInboxScreenState();
}

class _CloudInboxScreenState extends State<CloudInboxScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final GmailService _gmailService = GmailService();
  final OCRService _ocrService = OCRService();

  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    final drafts = await _dbHelper.getDraftInvoices();
    setState(() {
      // Only show pending drafts
      _drafts = drafts.where((d) => d['status'] == 'pending').toList();
      _isLoading = false;
    });
  }

  Future<void> _syncGmail() async {
     setState(() => _isSyncing = true);
     
     try {
       final mockDrafts = await _gmailService.getMockDrafts();
       for (var draft in mockDrafts) {
          await _dbHelper.saveDraftInvoice(draft);
       }
       
       await Future.delayed(const Duration(seconds: 2));
       await _loadDrafts();
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(tr('cloud_inbox.sync_success')), backgroundColor: Colors.greenAccent),
         );
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${tr('cloud_inbox.sync_error')}: $e"), backgroundColor: Colors.redAccent),
         );
       }
     } finally {
       if (mounted) {
         setState(() => _isSyncing = false);
       }
     }
  }

  Future<void> _approveDraft(Map<String, dynamic> draft) async {
    setState(() => _isLoading = true);
    try {
      final success = await _dbHelper.approveDraftInvoice(draft['id']);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('cloud_inbox.approve_success')), backgroundColor: Colors.green),
        );
      }
      await _loadDrafts();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${tr('cloud_inbox.approve_error')}: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectDraft(Map<String, dynamic> draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text(tr('cloud_inbox.reject_confirm_title')),
        content: Text(tr('cloud_inbox.reject_confirm_desc', args: [draft['supplier_name'] ?? ''])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(tr('cloud_inbox.reject'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.rejectDraftInvoice(draft['id']);
      await _loadDrafts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('cloud_inbox.rejected')), backgroundColor: Colors.orangeAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('cloud_inbox.subtitle'), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                  const SizedBox(height: 4),
                  Text(tr('cloud_inbox.title'), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncGmail,
                icon: Icon(Icons.sync_rounded, size: context.iconSize - 2),
                label: Text(
                  _isSyncing ? tr('cloud_inbox.syncing') : tr('cloud_inbox.sync'),
                  style: TextStyle(fontSize: context.bodySize),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius / 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _drafts.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(tr('cloud_inbox.empty'), style: const TextStyle(color: Colors.white24)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _drafts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            padding: EdgeInsets.all(context.cardPadding),
                            borderRadius: context.cardRadius,
                            child: Column(
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    Icon(Icons.mark_email_unread_outlined, color: Colors.blueAccent, size: context.iconSize),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(draft['supplier_name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
                                          Text("${draft['date']} | ${draft['total_amount']} ${tr('onboarding.currency_hint')}", style: TextStyle(color: Colors.white38, fontSize: context.bodySize - 2)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _showReviewDialog(draft),
                                      icon: Icon(Icons.visibility_outlined, color: Colors.white54, size: context.iconSize),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Action Buttons Row
                                Row(
                                  children: [
                                    // Reject button
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _rejectDraft(draft),
                                        icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                        label: Text(tr('cloud_inbox.reject'), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Approve button
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _approveDraft(draft),
                                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.black),
                                        label: Text(tr('cloud_inbox.approve'), style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> draft) {
    final supplierController = TextEditingController(text: draft['supplier_name'] ?? '');
    final totalController = TextEditingController(text: draft['total_amount']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.cardRadius)),
        title: Text("${tr('cloud_inbox.review')}: ${draft['supplier_name']}", style: TextStyle(fontSize: context.subHeaderSize)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('cloud_inbox.ai_extracted'), style: TextStyle(fontSize: context.bodySize - 2, color: Colors.white38)),
              const SizedBox(height: 12),
              // Editable fields (QuickBooks style — edit before approve)
              TextField(
                controller: supplierController,
                decoration: InputDecoration(
                  labelText: tr('cloud_inbox.supplier_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              _detailItem(tr('cloud_inbox.date_label'), draft['date'] ?? ''),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('cloud_inbox.total_label'),
                  suffixText: tr('onboarding.currency_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(context.cardRadius / 2)),
                child: Center(child: Text(tr('cloud_inbox.invoice_preview'), style: TextStyle(fontSize: context.bodySize - 2, color: Colors.white24))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'), style: TextStyle(fontSize: context.bodySize))),
          ElevatedButton.icon(
            onPressed: () async {
              // Update draft with edited values then approve
              final db = await _dbHelper.database;
              await db.update('draft_invoices', {
                'supplier_name': supplierController.text,
                'total_amount': double.tryParse(totalController.text) ?? draft['total_amount'],
              }, where: 'id = ?', whereArgs: [draft['id']]);
              
              Navigator.pop(context);
              _approveDraft({...draft, 'supplier_name': supplierController.text, 'total_amount': double.tryParse(totalController.text) ?? draft['total_amount']});
            },
            icon: const Icon(Icons.check, color: Colors.black, size: 16),
            label: Text(tr('cloud_inbox.approve_edited'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize)), 
        const SizedBox(width: 8), 
        Text(value, style: TextStyle(fontSize: context.bodySize)),
      ]),
    );
  }
}
