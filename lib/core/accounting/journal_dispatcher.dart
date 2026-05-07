// lib/core/accounting/journal_dispatcher.dart
// SQLite-based Journal Dispatcher for automated double-entry postings
import '../../services/database_helper.dart';

class JournalLineData {
  final String accountCode;
  final double debit;
  final double credit;
  final String? projectId;
  final String? costCenterId;

  JournalLineData({
    required this.accountCode,
    this.debit = 0,
    this.credit = 0,
    this.projectId,
    this.costCenterId,
  });
}

class JournalDispatcher {
  final DatabaseHelper _db = DatabaseHelper();

  /// Posts a balanced double-entry transaction to SQLite
  Future<String> postTransaction({
    required DateTime date,
    required String description,
    String? referenceId,
    required List<JournalLineData> movements,
    String? attachmentPath,
  }) async {
    // Validate: Total Debits must equal Total Credits
    double totalDebit = movements.fold(0.0, (s, m) => s + m.debit);
    double totalCredit = movements.fold(0.0, (s, m) => s + m.credit);

    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw Exception(
        'Unbalanced entry: Debits=$totalDebit Credits=$totalCredit',
      );
    }

    final lines = movements.map((m) => {
      'account_id': m.accountCode,
      'debit': m.debit,
      'credit': m.credit,
      'project_id': m.projectId,
      'cost_center_id': m.costCenterId,
    }).toList();

    await _db.saveManualJournalEntry(
      {
        'date': date.toIso8601String().split('T')[0],
        'description': description,
        'reference_id': referenceId,
      },
      lines,
    );

    return 'JE_${DateTime.now().millisecondsSinceEpoch}';
  }
}
