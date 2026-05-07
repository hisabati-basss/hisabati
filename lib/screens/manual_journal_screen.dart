import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../theme/app_theme_extension.dart';

class ManualJournalScreen extends StatefulWidget {
  const ManualJournalScreen({super.key});

  @override
  State<ManualJournalScreen> createState() => _ManualJournalScreenState();
}

class _ManualJournalScreenState extends State<ManualJournalScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<JournalLineModel> _lines = [JournalLineModel(), JournalLineModel()];

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _costCenters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final db = await _db.database;
    final accs = await db.query('accounts', orderBy: 'code ASC');

    final projs = <Map<String, dynamic>>[];
    final ccs = <Map<String, dynamic>>[];

    if (mounted) {
      setState(() {
        _accounts = accs.map((a) => {
          'id': a['id']?.toString() ?? '',
          'name': '${a['code']} - ${a['name']}',
          'code': a['code']?.toString() ?? '',
        }).toList();
        _projects = projs;
        _costCenters = ccs;
        _isLoading = false;
      });
    }
  }

  double get _totalDebit => _lines.fold(0.0, (sum, item) => sum + item.debit);
  double get _totalCredit => _lines.fold(0.0, (sum, item) => sum + item.credit);
  bool get _isBalanced =>
      (_totalDebit - _totalCredit).abs() < 0.01 && _totalDebit > 0;

  void _addLine() {
    setState(() => _lines.add(JournalLineModel()));
  }

  void _removeLine(int index) {
    if (_lines.length > 2) {
      setState(() => _lines.removeAt(index));
    }
  }

  Future<void> _saveEntry() async {
    if (!_isBalanced) {
      _showErrorDialog(tr('manual_journal.error_unbalanced'));
      return;
    }

    if (_descController.text.isEmpty) {
      _descController.text = tr(
        'manual_journal.new_title',
      ); // Default desc if left empty
    }

    if (_lines.any((l) => l.accountId == null)) {
      _showErrorDialog(tr('manual_journal.error_account'));
      return;
    }

    try {
      final lines = _lines.map((l) => {
        'account_id': l.accountId ?? '',
        'debit': l.debit,
        'credit': l.credit,
        'cost_center_id': l.costCenterId,
        'project_id': l.projectId,
      }).toList();

      await _db.saveManualJournalEntry(
        {
          'date': _selectedDate.toIso8601String().split('T')[0],
          'description': _descController.text,
        },
        lines,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('manual_journal.save_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          tr('manual_journal.error_data_title'),
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 18,
          ),
        ),
        content: Text(message,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('manual_journal.ok'), style: const TextStyle(color: primaryOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                // Header Bar for the Bottom Sheet
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('manual_journal.new_title'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close, color: context.mutedText),
                              ),
                              IconButton(
                                onPressed: _isLoading ? null : _saveEntry,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: _isBalanced ? Colors.greenAccent : Colors.white24,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryOrange,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(context.sectionPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderCard(isDark),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Text(
                                  tr('manual_journal.header_details'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._lines.asMap().entries.map(
                                (entry) => _buildLineCard(
                                  entry.key,
                                  entry.value,
                                  isDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAddLineButton(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
                _buildSummaryFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.cardBorder.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(context.cardRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: context.iconSize - 4,
                          color: primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate.toIso8601String().split('T')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              labelText: tr('manual_journal.desc_label'),
              labelStyle: TextStyle(fontSize: context.bodySize, color: Colors.white54),
              hintText: tr('manual_journal.desc_hint'),
              hintStyle: TextStyle(fontSize: context.bodySize, color: Colors.white24),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              floatingLabelStyle: const TextStyle(color: primaryOrange),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryOrange)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(int index, JournalLineModel line, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(context.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInlineDropdown(
                  tr('accounting_operations.account_col'),
                  line.accountId,
                  _accounts
                      .map(
                        (acc) => {
                          'id': acc['id'],
                          'name': "${acc['code']} - ${acc['name']}",
                        },
                      )
                      .toList(),
                  (val) => setState(() => line.accountId = val),
                  hint: tr('manual_journal.select_account_hint'),
                  isDark: isDark,
                ),
              ),
              IconButton(
                onPressed: () => _removeLine(index),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: context.iconSize - 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: context.bodySize),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: tr('accounting_operations.debit_col'),
                    prefixText: "↑ ",
                    labelStyle: TextStyle(fontSize: context.bodySize),
                    floatingLabelStyle: const TextStyle(
                      color: Colors.greenAccent,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      line.debit = double.tryParse(val) ?? 0;
                      if (line.debit > 0) line.credit = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: context.bodySize),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: tr('accounting_operations.credit_col'),
                    prefixText: "↓ ",
                    labelStyle: TextStyle(fontSize: context.bodySize),
                    floatingLabelStyle: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      line.credit = double.tryParse(val) ?? 0;
                      if (line.credit > 0) line.debit = 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInlineDropdown(
                  tr('manual_journal.select_cc_hint'),
                  line.costCenterId,
                  _costCenters.isNotEmpty
                      ? _costCenters
                            .map(
                              (cc) => {
                                'id': cc['id'],
                                'name': cc['name'] as String,
                              },
                            )
                            .toList()
                      : [
                          {'id': 'none', 'name': 'لا يوجد بيانات مسجلة'},
                        ],
                  (val) {
                    if (val != 'none') setState(() => line.costCenterId = val);
                  },
                  hint: tr('manual_journal.select_cc_hint'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInlineDropdown(
                  tr('manual_journal.project_label'),
                  line.projectId,
                  _projects.isNotEmpty
                      ? _projects
                            .map(
                              (p) => {
                                'id': p['id'] as String,
                                'name': p['name'] as String,
                              },
                            )
                            .toList()
                      : [
                          {'id': 'none', 'name': 'لا يوجد بيانات مسجلة'},
                        ],
                  (val) {
                    if (val != 'none') setState(() => line.projectId = val);
                  },
                  hint: tr('manual_journal.project_hint'),
                  allowNull: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineDropdown(
    String label,
    String? value,
    List<Map<String, dynamic>> items,
    Function(String?) onChanged, {
    String? hint,
    bool allowNull = false,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.bodySize - 3,
            color: context.mutedText,
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            hint: hint != null
                ? Text(hint, style: TextStyle(fontSize: context.bodySize - 2))
                : null,
            value: value,
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            icon: Icon(
              Icons.arrow_drop_down,
              color: primaryOrange,
              size: context.iconSize - 4,
            ),
            items: [
              if (allowNull)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    tr('manual_journal.no_project'),
                    style: TextStyle(fontSize: context.bodySize - 2),
                  ),
                ),
              ...items.map(
                (e) => DropdownMenuItem<String?>(
                  value: e['id'] as String,
                  child: Text(
                    e['name'] as String,
                    style: TextStyle(fontSize: context.bodySize - 2),
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAddLineButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _addLine,
        icon: Icon(
          Icons.add_circle_outline,
          color: primaryOrange,
          size: context.iconSize,
        ),
        label: Text(
          tr('manual_journal.add_line'),
          style: const TextStyle(
            color: primaryOrange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'manual_journal.total_debit',
                    args: [_totalDebit.toStringAsFixed(2)],
                  ),
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: context.bodySize,
                  ),
                ),
                Text(
                  tr(
                    'manual_journal.total_credit',
                    args: [_totalCredit.toStringAsFixed(2)],
                  ),
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: context.bodySize,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isBalanced
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.cardRadius),
                border: Border.all(
                  color: _isBalanced
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isBalanced ? Icons.check_circle : Icons.error_outline,
                    color: _isBalanced ? Colors.green : Colors.red,
                    size: context.iconSize - 4,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isBalanced
                        ? tr('manual_journal.balanced')
                        : tr('manual_journal.unbalanced'),
                    style: TextStyle(
                      color: _isBalanced ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: context.bodySize - 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalLineModel {
  String? accountId;
  double debit = 0;
  double credit = 0;
  String? projectId;
  String? costCenterId;

  JournalLineModel({
    this.accountId,
    this.debit = 0,
    this.credit = 0,
    this.projectId,
    this.costCenterId,
  });
}
