import '../services/database_helper.dart';

class AnalyticsService {
  final DatabaseHelper _db = DatabaseHelper();

  /// 1. Live P&L for the given period
  Future<Map<String, double>> getLivePNL({DateTime? startDate, DateTime? endDate}) async {
    final db = await _db.database;
    final start = (startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1)).toIso8601String().split('T')[0];
    final end = (endDate ?? DateTime.now()).toIso8601String().split('T')[0];

    final revRes = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.credit - jel.debit), 0) as total
      FROM journal_entry_lines jel
      JOIN accounts a ON jel.account_id = a.id
      JOIN journal_entries je ON jel.journal_entry_id = je.id
      WHERE a.type = 'revenue' AND je.date >= ? AND je.date <= ?
    ''', [start, end]);
    double totalRevenue = (revRes.first['total'] as num?)?.toDouble() ?? 0;

    final expRes = await db.rawQuery('''
      SELECT COALESCE(SUM(jel.debit - jel.credit), 0) as total
      FROM journal_entry_lines jel
      JOIN accounts a ON jel.account_id = a.id
      JOIN journal_entries je ON jel.journal_entry_id = je.id
      WHERE a.type = 'expense' AND je.date >= ? AND je.date <= ?
    ''', [start, end]);
    double totalExpense = (expRes.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'total_revenue': totalRevenue,
      'total_expense': totalExpense,
      'net_profit': totalRevenue - totalExpense,
    };
  }

  /// 2. Executive Dashboard Highlights
  Future<Map<String, dynamic>> getExecutiveHighlights() async {
    final db = await _db.database;

    // Total cash = all asset accounts (cash, bank, cheques)
    final cashRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts 
      WHERE type = 'asset' AND (id LIKE 'ACC_CASH%' OR id LIKE 'ACC_BANK%' OR code IN ('101','104','105'))
    ''');
    double totalCash = (cashRes.first['total'] as num?)?.toDouble() ?? 0;

    final pendingRes = await db.rawQuery(
      "SELECT COUNT(*) as c FROM salary_slips WHERE status = 'draft'"
    );
    int pendingSalaries = (pendingRes.first['c'] as int?) ?? 0;

    final custodyRes = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM financial_custodies WHERE status = 'pending'"
    );
    double totalCustody = (custodyRes.first['total'] as num?)?.toDouble() ?? 0;

    // Receivables
    final recvRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE id = 'ACC_RECEIVABLE'
    ''');
    double totalReceivable = (recvRes.first['total'] as num?)?.toDouble() ?? 0;

    // Payables
    final payRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts WHERE id = 'ACC_PAYABLE'
    ''');
    double totalPayable = (payRes.first['total'] as num?)?.toDouble() ?? 0;

    // Total invoices this month
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
    final invoicesThisMonth = await db.rawQuery('''
      SELECT COUNT(*) as c, COALESCE(SUM(total), 0) as total FROM invoices 
      WHERE issue_date >= ?
    ''', [monthStart]);
    int invoiceCount = (invoicesThisMonth.first['c'] as int?) ?? 0;
    double invoiceTotal = (invoicesThisMonth.first['total'] as num?)?.toDouble() ?? 0;

    // Total expenses this month
    final expensesThisMonth = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total FROM purchase_invoices 
      WHERE issue_date >= ?
    ''', [monthStart]);
    double expenseTotal = (expensesThisMonth.first['total'] as num?)?.toDouble() ?? 0;

    // Overdue invoices
    final overdueRes = await db.rawQuery('''
      SELECT COUNT(*) as c FROM invoices 
      WHERE payment_status != 'paid' AND due_date < ?
    ''', [now.toIso8601String().split('T')[0]]);
    int overdueCount = (overdueRes.first['c'] as int?) ?? 0;

    // Total employees
    final empRes = await db.rawQuery('SELECT COUNT(*) as c FROM employees');
    int employeeCount = (empRes.first['c'] as int?) ?? 0;

    // Inventory value
    final invRes = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity * cost_price), 0) as total FROM items WHERE quantity > 0
    ''');
    double inventoryValue = (invRes.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'total_cash': totalCash,
      'pending_salaries_count': pendingSalaries,
      'uncleared_custodies_amount': totalCustody,
      'total_receivable': totalReceivable,
      'total_payable': totalPayable,
      'invoice_count_month': invoiceCount,
      'invoice_total_month': invoiceTotal,
      'expense_total_month': expenseTotal,
      'overdue_count': overdueCount,
      'employee_count': employeeCount,
      'inventory_value': inventoryValue,
    };
  }

  /// 3. Sales trend for last 7 days
  Future<List<Map<String, dynamic>>> getSalesTrendLast7Days() async {
    final db = await _db.database;
    final now = DateTime.now();
    List<Map<String, dynamic>> trend = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      final res = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as daily_total FROM invoices 
        WHERE issue_date LIKE ?
      ''', ['$dateStr%']);
      
      double dailySales = (res.first['daily_total'] as num?)?.toDouble() ?? 0;

      trend.add({
        'day_name': _getArabicDayName(date.weekday),
        'date': date,
        'amount': dailySales,
      });
    }

    return trend;
  }

  /// 4. Monthly sales trend (last 6 months)
  Future<List<Map<String, dynamic>>> getMonthlySalesTrend() async {
    final db = await _db.database;
    final now = DateTime.now();
    List<Map<String, dynamic>> trend = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      final startStr = month.toIso8601String().split('T')[0];
      final endStr = monthEnd.toIso8601String().split('T')[0];

      final sales = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total FROM invoices 
        WHERE issue_date >= ? AND issue_date <= ?
      ''', [startStr, endStr]);

      final purchases = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total FROM purchase_invoices 
        WHERE issue_date >= ? AND issue_date <= ?
      ''', [startStr, endStr]);

      trend.add({
        'month': _getArabicMonthName(month.month),
        'month_num': month.month,
        'sales': (sales.first['total'] as num?)?.toDouble() ?? 0,
        'purchases': (purchases.first['total'] as num?)?.toDouble() ?? 0,
      });
    }
    return trend;
  }

  /// 5. Top Selling Products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT il.name, SUM(il.quantity) as total_qty, SUM(il.quantity * il.price_at_sale) as total_revenue
      FROM invoice_lines il
      GROUP BY il.name
      ORDER BY total_revenue DESC
      LIMIT ?
    ''', [limit]);
  }

  /// 6. Top Customers
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 5}) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT client_id as name, COUNT(*) as invoice_count, COALESCE(SUM(total), 0) as total_spent
      FROM invoices
      WHERE client_id IS NOT NULL AND client_id != ''
      GROUP BY client_id
      ORDER BY total_spent DESC
      LIMIT ?
    ''', [limit]);
  }

  /// 7. Expense by Category
  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT a.name, a.code, COALESCE(SUM(jel.debit), 0) as total
      FROM journal_entry_lines jel
      JOIN accounts a ON jel.account_id = a.id
      WHERE a.type = 'expense'
      GROUP BY a.id
      ORDER BY total DESC
    ''');
  }

  String _getArabicDayName(int weekday) {
    const days = {
      1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 
      4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد'
    };
    return days[weekday] ?? '';
  }

  String _getArabicMonthName(int month) {
    const months = {
      1: 'يناير', 2: 'فبراير', 3: 'مارس', 4: 'أبريل',
      5: 'مايو', 6: 'يونيو', 7: 'يوليو', 8: 'أغسطس',
      9: 'سبتمبر', 10: 'أكتوبر', 11: 'نوفمبر', 12: 'ديسمبر',
    };
    return months[month] ?? '';
  }
}
