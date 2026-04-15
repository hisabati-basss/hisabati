import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../services/database_helper.dart';
import '../../../services/pdf_service.dart';
import '../../../theme/app_theme_extension.dart';

class ContractsTab extends StatefulWidget {
  final String employeeId;
  final Map<String, dynamic> employee;
  const ContractsTab({super.key, required this.employeeId, required this.employee});

  @override
  State<ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<ContractsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _activeContract;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    final db = await _db.database;
    final res = await db.query(
      'employee_contracts',
      where: 'employee_id = ? AND status = ? AND is_deleted = 0',
      whereArgs: [widget.employeeId, 'active'],
      limit: 1,
    );
    setState(() {
      _activeContract = res.isNotEmpty ? res.first : null;
      _isLoading = false;
    });
  }

  Future<void> _createNewContract() async {
    String type = 'دائم (Unlimited)';
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إنشاء عقد عمل جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: ['دائم (Unlimited)', 'محدد المدة (Fixed)', 'تدريب (Internship)']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => type = v!,
                decoration: const InputDecoration(labelText: 'نوع العقد'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تاريخ البداية'),
                subtitle: Text(startDate.toIso8601String().split('T').first),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
              ListTile(
                title: const Text('تاريخ النهاية'),
                subtitle: Text(endDate?.toIso8601String().split('T').first ?? 'غير محدد'),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final db = await _db.database;
                final nowStr = DateTime.now().toIso8601String();
                await db.insert('employee_contracts', {
                  'id': const Uuid().v4(),
                  'employee_id': widget.employeeId,
                  'contract_type': type,
                  'start_date': startDate.toIso8601String().split('T').first,
                  'end_date': endDate?.toIso8601String().split('T').first,
                  'basic_salary': widget.employee['basic_salary'],
                  'status': 'active',
                  'created_at': nowStr,
                  'updated_at': nowStr,
                  'sync_status': 0,
                  'is_deleted': 0,
                });
                Navigator.pop(ctx);
                _loadContract();
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printContract() async {
    if (_activeContract == null) return;
    
    final db = await _db.database;
    final companyRes = await db.query('companies', limit: 1);
    if (companyRes.isEmpty) return;

    await PdfService.generateContractPdf(
      employee: widget.employee,
      contract: _activeContract!,
      company: companyRes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_activeContract == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text("لا يوجد عقد نشط مسجل", style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewContract,
              icon: const Icon(Icons.add),
              label: const Text("إنشاء عقد جديد"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                const Text("عقد عمل ساري", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_activeContract!['contract_type'] ?? 'دائم', style: TextStyle(color: context.mutedText)),
                const Divider(height: 48, color: Colors.white10),
                _buildRow("تاريخ البدء", _activeContract!['start_date']),
                _buildRow("تاريخ الانتهاء", _activeContract!['end_date'] ?? "غير محدد"),
                _buildRow("الراتب المسجل", "${_activeContract!['basic_salary']} ر.س"),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _printContract,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text("طباعة العقد (PDF)"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.mutedText)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
