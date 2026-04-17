import 'database_helper.dart';

class CashFlowLine {
  final String nameAr;
  final String nameEn;
  final double amount;
  CashFlowLine({required this.nameAr, required this.nameEn, required this.amount});
}

class CashFlowService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> getCashFlowStatement(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // 1. Opening Cash
    // Sum of balances for accounts of type 'asset' with code starting with '111' (Cash) or '112' (Bank)
    final openingCashRes = await db.rawQuery('''
      SELECT SUM(jl.debit - jl.credit) as balance
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE (a.code LIKE '111%' OR a.code LIKE '112%')
      AND je.date < ?
    ''', [startStr]);
    double openingCash = (openingCashRes.first['balance'] as num?)?.toDouble() ?? 0.0;

    // 2. Net Income
    final netIncomeRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN a.type = 'revenue' THEN (jl.credit - jl.debit) ELSE 0 END) -
        SUM(CASE WHEN a.type = 'expense' THEN (jl.debit - jl.credit) ELSE 0 END) as net_income
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE je.date BETWEEN ? AND ?
    ''', [startStr, endStr]);
    double netIncome = (netIncomeRes.first['net_income'] as num?)?.toDouble() ?? 0.0;

    // 3. Operating Activities
    List<CashFlowLine> operatingLines = [
      CashFlowLine(nameAr: 'صافي الربح', nameEn: 'Net Income', amount: netIncome),
    ];

    // Depreciation (Non-cash expense)
    final depreciationRes = await db.rawQuery('''
      SELECT SUM(jl.debit - jl.credit) as total
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE a.code LIKE '573%' OR a.name LIKE '%إهلاك%'
      AND je.date BETWEEN ? AND ?
    ''', [startStr, endStr]);
    double depreciation = (depreciationRes.first['total'] as num?)?.toDouble() ?? 0.0;
    if (depreciation != 0) {
      operatingLines.add(CashFlowLine(nameAr: 'إهلاك الأصول', nameEn: 'Depreciation', amount: depreciation));
    }

    // Working Capital Changes
    // AR, Inventory (Current Assets except Cash)
    // Assets: Increase = Outflow (-), Decrease = Inflow (+)
    final currentAssetsRes = await db.rawQuery('''
      SELECT a.name as name_ar, a.code, SUM(jl.debit - jl.credit) as change
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE a.type = 'asset' 
      AND a.code LIKE '11%' 
      AND NOT (a.code LIKE '111%' OR a.code LIKE '112%')
      AND je.date BETWEEN ? AND ?
      GROUP BY a.id
    ''', [startStr, endStr]);

    for (var row in currentAssetsRes) {
      double change = (row['change'] as num?)?.toDouble() ?? 0.0;
      if (change != 0) {
        operatingLines.add(CashFlowLine(
          nameAr: 'تغير في ${row['name_ar']}', 
          nameEn: 'Change in ${row['name_ar']}', 
          amount: -change // Asset increase = cash outflow
        ));
      }
    }

    // AP, Accrued Expenses (Current Liabilities)
    // Liabilities: Increase = Inflow (+), Decrease = Outflow (-)
    final currentLiabilitiesRes = await db.rawQuery('''
      SELECT a.name as name_ar, a.code, SUM(jl.credit - jl.debit) as change
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE a.type = 'liability' 
      AND a.code LIKE '21%'
      AND je.date BETWEEN ? AND ?
      GROUP BY a.id
    ''', [startStr, endStr]);

    for (var row in currentLiabilitiesRes) {
      double change = (row['change'] as num?)?.toDouble() ?? 0.0;
      if (change != 0) {
        operatingLines.add(CashFlowLine(
          nameAr: 'تغير في ${row['name_ar']}', 
          nameEn: 'Change in ${row['name_ar']}', 
          amount: change // Liability increase = cash inflow
        ));
      }
    }

    // 4. Investing Activities (Fixed Assets)
    List<CashFlowLine> investingLines = [];
    final fixedAssetsRes = await db.rawQuery('''
      SELECT a.name as name_ar, SUM(jl.debit - jl.credit) as change
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE a.type = 'asset' AND a.code LIKE '12%'
      AND je.date BETWEEN ? AND ?
      GROUP BY a.id
    ''', [startStr, endStr]);

    for (var row in fixedAssetsRes) {
      double change = (row['change'] as num?)?.toDouble() ?? 0.0;
      if (change != 0) {
        investingLines.add(CashFlowLine(
          nameAr: change > 0 ? 'شراء ${row['name_ar']}' : 'بيع ${row['name_ar']}', 
          nameEn: change > 0 ? 'Purchase of ${row['name_ar']}' : 'Sale of ${row['name_ar']}', 
          amount: -change
        ));
      }
    }

    // 5. Financing Activities (Equity & Long-term Liabilities)
    List<CashFlowLine> financingLines = [];
    final financingRes = await db.rawQuery('''
      SELECT a.name as name_ar, SUM(jl.credit - jl.debit) as change
      FROM journal_entry_lines jl
      JOIN journal_entries je ON jl.entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE (a.type = 'equity' OR (a.type = 'liability' AND a.code LIKE '22%'))
      AND je.date BETWEEN ? AND ?
      GROUP BY a.id
    ''', [startStr, endStr]);

    for (var row in financingRes) {
      double change = (row['change'] as num?)?.toDouble() ?? 0.0;
      if (change != 0) {
        financingLines.add(CashFlowLine(
          nameAr: 'تغير في ${row['name_ar']}', 
          nameEn: 'Change in ${row['name_ar']}', 
          amount: change
        ));
      }
    }

    return {
      'opening_cash': openingCash,
      'operating': operatingLines,
      'investing': investingLines,
      'financing': financingLines,
    };
  }

  /// Forecasts liquidity for the next N days.
  Future<Map<String, dynamic>> forecastLiquidity(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    final futureDateStr = futureDate.toIso8601String();

    // Current Cash
    final currentCashRes = await db.rawQuery('''
      SELECT SUM(jl.debit - jl.credit) as balance
      FROM journal_entry_lines jl
      JOIN accounts a ON jl.account_id = a.id
      WHERE (a.code LIKE '111%' OR a.code LIKE '112%')
    ''');
    double currentCash = (currentCashRes.first['balance'] as num?)?.toDouble() ?? 0.0;

    // Expected Inflows (e.g., Receivable Cheques, unpaid invoices)
    final inflowRes = await db.rawQuery('''
      SELECT SUM(amount) as total FROM cheques WHERE type = 'receivable' AND status = 'pending'
    ''');
    double expectedInflow = (inflowRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Expected Outflows (e.g., Payable Cheques, pending maintenance)
    final outflowRes = await db.rawQuery('''
      SELECT SUM(amount) as total FROM cheques WHERE type = 'payable' AND status = 'pending'
    ''');
    double expectedOutflow = (outflowRes.first['total'] as num?)?.toDouble() ?? 0.0;

    double projectedCash = currentCash + expectedInflow - expectedOutflow;

    return {
      'current_cash': currentCash,
      'expected_inflow': expectedInflow,
      'expected_outflow': expectedOutflow,
      'projected_cash': projectedCash,
      'risk_level': projectedCash < 0 ? 'High' : (projectedCash < currentCash * 0.5 ? 'Medium' : 'Low'),
    };
  }
}
