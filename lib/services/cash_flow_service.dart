import 'database_helper.dart';

class CashFlowService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Forecasts cash flow for the upcoming days (e.g., 30, 60, 90 days)
  /// based on current balances, expected receivables (due_date), and payables.
  Future<Map<String, dynamic>> forecastLiquidity(int daysAhead) async {
    final db = await _dbHelper.database;
    final DateTime now = DateTime.now();
    final DateTime targetDate = now.add(Duration(days: daysAhead));
    final String nowStr = now.toIso8601String().split('T')[0];
    final String targetStr = targetDate.toIso8601String().split('T')[0];

    // 1. Current Liquid Assets (Cash + Bank)
    final cashRes = await db.rawQuery('''
      SELECT SUM(balance) as total_cash FROM accounts 
      WHERE (id = 'ACC_CASH' OR id LIKE 'ACC_BANK%')
    ''');
    double currentCash = (cashRes.first['total_cash'] as num?)?.toDouble() ?? 0.0;

    // 2. Expected Receivables (Sales Invoices unpaid and due within the window)
    // Assuming status != 'paid' and payment_type = 'credit'
    final receivablesRes = await db.rawQuery('''
      SELECT SUM(total) as expected_in 
      FROM invoices 
      WHERE payment_type = 'credit' 
        AND status != 'paid' 
        AND is_return = 0
        AND due_date BETWEEN ? AND ?
    ''', [nowStr, targetStr]);
    double expectedIn = (receivablesRes.first['expected_in'] as num?)?.toDouble() ?? 0.0;

    // 3. Expected Payables (Purchase Invoices unpaid and due within the window)
    // For purchase_invoices, if there's no status column, we assume payment_type='credit' means unpaid unless linked to a payment logic.
    // Assuming we have due_date in purchase_invoices.
    final payablesRes = await db.rawQuery('''
      SELECT SUM(total) as expected_out 
      FROM purchase_invoices 
      WHERE payment_type = 'credit'
        AND is_return = 0
        AND due_date BETWEEN ? AND ?
    ''', [nowStr, targetStr]);
    double expectedOut = (payablesRes.first['expected_out'] as num?)?.toDouble() ?? 0.0;

    // 4. Expected Salaries (Rough estimation based on total monthly payroll)
    // Count how many months pass in 'daysAhead'
    int monthsAhead = (daysAhead / 30).ceil();
    final salariesRes = await db.rawQuery('SELECT SUM(basic_salary) as monthly_payroll FROM employees WHERE status = ?', ['active']);
    double monthlyPayroll = (salariesRes.first['monthly_payroll'] as num?)?.toDouble() ?? 0.0;
    double expectedPayroll = monthlyPayroll * monthsAhead;

    // Projected Liquidity
    double netInOut = expectedIn - (expectedOut + expectedPayroll);
    double projectedCash = currentCash + netInOut;

    // Determine Risk Level
    String riskLevel = 'Low';
    if (projectedCash < (expectedOut + expectedPayroll) * 0.3) {
      riskLevel = 'High'; // Less than 30% of upcoming obligations covered
    } else if (projectedCash < (expectedOut + expectedPayroll)) {
      riskLevel = 'Medium';
    }

    return {
      'current_cash': currentCash,
      'expected_inflow': expectedIn,
      'expected_outflow': expectedOut + expectedPayroll,
      'breakdown': {
        'invoices': expectedIn,
        'purchases': expectedOut,
        'salaries': expectedPayroll,
      },
      'projected_cash': projectedCash,
      'risk_level': riskLevel,
      'target_date': targetStr,
    };
  }
}
