import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../services/database_helper.dart';
import '../../../theme/app_theme_extension.dart';

class DocumentsTab extends StatefulWidget {
  final String employeeId;
  const DocumentsTab({super.key, required this.employeeId});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final db = await _db.database;
    final res = await db.query(
      'documents',
      where: 'owner_id = ? AND is_deleted = 0',
      whereArgs: [widget.employeeId],
      orderBy: 'created_at DESC',
    );
    setState(() {
      _documents = res;
      _isLoading = false;
    });
  }

  Future<void> _addDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      
      // Copy to App Support Folder to ensure persistence
      final appDir = await getApplicationSupportDirectory();
      final docsDir = Directory(path.join(appDir.path, 'employee_documents'));
      if (!await docsDir.exists()) await docsDir.create(recursive: true);
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final savedPath = path.join(docsDir.path, fileName);
      await file.copy(savedPath);

      final db = await _db.database;
      final docId = const Uuid().v4();
      final nowStr = DateTime.now().toIso8601String();

      // Show dialog for metadata
      if (!mounted) return;
      
      String docName = result.files.single.name;
      DateTime? expiryDate;
      
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تفاصيل المستند'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'اسم المستند'),
                onChanged: (v) => docName = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تاريخ الانتهاء (اختياري)'),
                subtitle: Text(expiryDate?.toIso8601String().split('T').first ?? 'غير محدد'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => expiryDate = picked);
                    (ctx as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                await db.insert('documents', {
                  'id': docId,
                  'owner_type': 'employee',
                  'owner_id': widget.employeeId,
                  'name': docName,
                  'file_path': savedPath,
                  'file_type': path.extension(savedPath).replaceAll('.', ''),
                  'expiry_date': expiryDate?.toIso8601String(),
                  'status': 'active',
                  'created_at': nowStr,
                  'updated_at': nowStr,
                  'sync_status': 0,
                  'is_deleted': 0,
                });
                Navigator.pop(ctx);
                _loadDocuments();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    }
  }

  Color _getExpiryColor(String? expiryStr) {
    if (expiryStr == null || expiryStr.isEmpty) return Colors.grey;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return Colors.grey;

    final days = expiry.difference(DateTime.now()).inDays;
    if (days < 0) return Colors.red;
    if (days < 30) return Colors.deepOrange;
    if (days < 90) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("المستندات الرقمية", style: TextStyle(color: context.mutedText, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _addDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text("رفع مستند"),
              ),
            ],
          ),
        ),
        Expanded(
          child: _documents.isEmpty
              ? Center(child: Text("لا توجد مستندات بعد", style: TextStyle(color: context.mutedText)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (ctx, idx) {
                    final doc = _documents[idx];
                    final expiryColor = _getExpiryColor(doc['expiry_date']);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: expiryColor.withValues(alpha: 0.1),
                          child: Icon(Icons.description, color: expiryColor),
                        ),
                        title: Text(doc['name'] ?? 'مستند', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          doc['expiry_date'] != null 
                            ? "ينتهي في: ${doc['expiry_date'].toString().split('T').first}" 
                            : "لا يوجد تاريخ انتهاء",
                          style: TextStyle(color: context.mutedText, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
                          onPressed: () {
                             // Integration with PDF/Image viewer would go here
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
