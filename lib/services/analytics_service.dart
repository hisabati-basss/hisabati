import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class AnalyticsService {
  final DatabaseHelper _db = DatabaseHelper();

  /// 1. Live P&L for the given period
  Future<Map<String, double>> getLivePNL({DateTime? startDate, DateTime? endDate}) async {
    final db = await _db.database;
    // Default to Year to Date (YTD) to ensure the CEO sees meaningful data
    final start = (startDate ?? DateTime(DateTime.now().year, 1, 1)).toIso8601String().split('T')[0];
    final end = (endDate ?? DateTime.now()).toIso8601String().split('T')[0];

    try {
      final revRes = await db.rawQuery('''
        SELECT 
          (SELECT COALESCE(SUM(jel.credit - jel.debit), 0) FROM journal_entry_lines jel JOIN accounts a ON jel.account_id = a.id JOIN journal_entries je ON jel.entry_id = je.id WHERE LOWER(a.type) = 'revenue' AND date(je.date) >= date(?) AND date(je.date) <= date(?) AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init') AND je.id NOT LIKE 'DEMO_%') +
          (SELECT COALESCE(SUM(total), 0) FROM pos_receipts WHERE date(date) >= date(?) AND date(date) <= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')) as total
      ''', [start, end, start, end]);
      double totalRevenue = (revRes.first['total'] as num?)?.toDouble() ?? 0;

      final expRes = await db.rawQuery('''
        SELECT COALESCE(SUM(jel.debit - jel.credit), 0) as total
        FROM journal_entry_lines jel
        JOIN accounts a ON jel.account_id = a.id
        JOIN journal_entries je ON jel.entry_id = je.id
        WHERE LOWER(a.type) = 'expense' AND date(je.date) >= date(?) AND date(je.date) <= date(?) AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init') AND je.id NOT LIKE 'DEMO_%'
      ''', [start, end]);
      double totalExpense = (expRes.first['total'] as num?)?.toDouble() ?? 0;

      return {
        'total_revenue': totalRevenue,
        'total_expense': totalExpense,
        'net_profit': totalRevenue - totalExpense,
      };
    } catch (e) {
      debugPrint("❌ Analytics Error (getLivePNL): $e");
      return {'total_revenue': 0, 'total_expense': 0, 'net_profit': 0};
    }
  }

  /// 2. Executive Dashboard Highlights
  Future<Map<String, dynamic>> getExecutiveHighlights() async {
    final db = await _db.database;

    try {
      // Total cash = all asset accounts (cash, bank, cheques)
      final cashRes = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total FROM accounts 
        WHERE LOWER(type) = 'asset' AND (id LIKE 'ACC_CASH%' OR id LIKE 'ACC_BANK%' OR code IN ('101','104','105')) 
        AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND id NOT LIKE 'DEMO_%'
      ''');
      double totalCash = (cashRes.first['total'] as num?)?.toDouble() ?? 0;

      final pendingRes = await db.rawQuery(
        "SELECT COUNT(*) as c FROM salary_slips WHERE status = 'draft' AND is_deleted = 0"
      );
      int pendingSalaries = (pendingRes.first['c'] as int?) ?? 0;

      final custodyRes = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM financial_custodies WHERE status = 'pending' AND is_deleted = 0"
      );
      double totalCustody = (custodyRes.first['total'] as num?)?.toDouble() ?? 0;

      // Receivables
      final recvRes = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total FROM accounts 
        WHERE id = 'ACC_RECEIVABLE'
        AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND id NOT LIKE 'DEMO_%'
      ''');
      double totalReceivable = (recvRes.first['total'] as num?)?.toDouble() ?? 0;

      // Payables
      final payRes = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total FROM accounts 
        WHERE id = 'ACC_PAYABLE'
        AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND id NOT LIKE 'DEMO_%'
      ''');
      double totalPayable = (payRes.first['total'] as num?)?.toDouble() ?? 0;

      // Total invoices this month
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final invoicesThisMonth = await db.rawQuery('''
        SELECT 
          (SELECT COUNT(*) FROM invoices WHERE date(issue_date) >= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')) +
          (SELECT COUNT(*) FROM pos_receipts WHERE date(date) >= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')) as c,
          (SELECT COALESCE(SUM(total), 0) FROM invoices WHERE date(issue_date) >= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')) +
          (SELECT COALESCE(SUM(total), 0) FROM pos_receipts WHERE date(date) >= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')) as total
      ''', [monthStart, monthStart, monthStart, monthStart]);
      int invoiceCount = (invoicesThisMonth.first['c'] as int?) ?? 0;
      double invoiceTotal = (invoicesThisMonth.first['total'] as num?)?.toDouble() ?? 0;

      // Total expenses this month
      final expensesThisMonth = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total FROM purchase_invoices 
        WHERE date(issue_date) >= date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
      ''', [monthStart]);
      double expenseTotal = (expensesThisMonth.first['total'] as num?)?.toDouble() ?? 0;

      // Overdue invoices
      final overdueRes = await db.rawQuery('''
        SELECT COUNT(*) as c FROM invoices 
        WHERE status != 'paid' AND date(due_date) < date(?) AND is_deleted = 0
      ''', [now.toIso8601String().split('T')[0]]);
      int overdueCount = (overdueRes.first['c'] as int?) ?? 0;

      // Total employees
      final empRes = await db.rawQuery('SELECT COUNT(*) as c FROM employees WHERE is_deleted = 0');
      int employeeCount = (empRes.first['c'] as int?) ?? 0;

      // Inventory value
      final invRes = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity * cost_price), 0) as total FROM items WHERE quantity > 0 AND is_deleted = 0
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
    } catch (e) {
      debugPrint("❌ Analytics Error (getExecutiveHighlights): $e");
      return {};
    }
  }

  /// 3. Sales trend for last 7 days (Fully Unified)
  Future<List<Map<String, dynamic>>> getSalesTrendLast7Days() async {
    final db = await _db.database;
    final now = DateTime.now();
    List<Map<String, dynamic>> trend = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      final res = await db.rawQuery('''
        SELECT SUM(daily_total) as total FROM (
          SELECT COALESCE(SUM(total), 0) as daily_total FROM invoices WHERE date(issue_date) = date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
          UNION ALL
          SELECT COALESCE(SUM(total), 0) as daily_total FROM pos_receipts WHERE date(date) = date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
        )
      ''', [dateStr, dateStr]);
      
      double dailySales = (res.first['total'] as num?)?.toDouble() ?? 0;

      trend.add({
        'day_name': _getArabicDayName(date.weekday),
        'date': date,
        'amount': dailySales,
      });
    }

    return trend;
  }

  /// 4. Monthly sales trend (last 6 months - Fully Unified)
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
        SELECT SUM(total) as total FROM (
          SELECT COALESCE(SUM(total), 0) as total FROM invoices WHERE date(issue_date) BETWEEN date(?) AND date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
          UNION ALL
          SELECT COALESCE(SUM(total), 0) as total FROM pos_receipts WHERE date(date) BETWEEN date(?) AND date(?) AND is_deleted = 0 AND COALESCE(device_id, '') NOT IN ('system_seed', 'onboarding_init')
        )
      ''', [startStr, endStr, startStr, endStr]);

      final purchases = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total FROM purchase_invoices 
        WHERE date(issue_date) BETWEEN date(?) AND date(?) AND is_deleted = 0
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

  /// 5. Top Selling Products (Fully Unified & Filtered)
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT name, SUM(quantity) as total_qty, SUM(revenue) as total_revenue FROM (
        SELECT il.name, il.quantity, (il.quantity * il.price_at_sale) as revenue 
        FROM invoice_lines il 
        JOIN invoices i ON il.invoice_id = i.id 
        WHERE i.is_deleted = 0 AND COALESCE(i.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        
        UNION ALL
        
        SELECT pl.name, pl.quantity, (pl.quantity * pl.price) as revenue 
        FROM pos_receipt_lines pl
        JOIN pos_receipts pr ON pl.receipt_id = pr.id
        WHERE pr.is_deleted = 0 AND COALESCE(pr.device_id, '') NOT IN ('system_seed', 'onboarding_init')
      )
      GROUP BY name
      ORDER BY total_revenue DESC
      LIMIT ?
    ''', [limit]);
  }

  /// 6. Top Customers (Fully Unified)
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 5}) async {
    final db = await _db.database;
    // Merging Client IDs from Invoices and POS Receipts
    return await db.rawQuery('''
      SELECT name, COUNT(*) as invoice_count, SUM(total) as total_spent FROM (
        SELECT client_id as name, total FROM invoices WHERE client_id IS NOT NULL AND client_id != '' AND is_deleted = 0
        UNION ALL
        SELECT client_id as name, total FROM pos_receipts WHERE client_id IS NOT NULL AND client_id != '' AND is_deleted = 0
      )
      GROUP BY name
      ORDER BY total_spent DESC
      LIMIT ?
    ''', [limit]);
  }

  /// 7. Expense by Category
  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT a.name, a.code, COALESCE(SUM(jel.debit - jel.credit), 0) as total
      FROM journal_entry_lines jel
      JOIN accounts a ON jel.account_id = a.id
      JOIN journal_entries je ON jel.entry_id = je.id
      WHERE LOWER(a.type) = 'expense'
        AND je.is_deleted = 0
        AND COALESCE(je.device_id, '') NOT IN ('system_seed', 'onboarding_init')
        AND je.id NOT LIKE 'DEMO_%'
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

  /// 8. Industry-Specific KPIs (Diversity Support)
  Future<Map<String, dynamic>> getIndustryDiverseKPIs() async {
    final db = await _db.database;
    Map<String, dynamic> kpis = {};

    try {
      // Medical: Patients & Appointments
      final medRes = await db.rawQuery("SELECT COUNT(*) as c FROM medical_patients WHERE is_deleted = 0");
      final apptRes = await db.rawQuery("SELECT COUNT(*) as c FROM medical_appointments WHERE status = 'pending' AND is_deleted = 0");
      kpis['medical'] = {
        'total_patients': (medRes.first['c'] as int?) ?? 0,
        'pending_appointments': (apptRes.first['c'] as int?) ?? 0,
      };

      // Hospitality: Occupancy Rate
      final roomsRes = await db.rawQuery("SELECT COUNT(*) as total, SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END) as occupied FROM hotel_rooms WHERE is_deleted = 0");
      int totalRooms = (roomsRes.first['total'] as int?) ?? 0;
      int occupiedRooms = (roomsRes.first['occupied'] as int?) ?? 0;
      kpis['hospitality'] = {
        'total_rooms': totalRooms,
        'occupancy_rate': totalRooms > 0 ? (occupiedRooms / totalRooms * 100) : 0.0,
      };

      // Manufacturing: Production Efficiency
      final moRes = await db.rawQuery("SELECT COUNT(*) as c FROM manufacturing_orders WHERE status = 'in_progress' AND is_deleted = 0");
      kpis['manufacturing'] = {
        'active_orders': (moRes.first['c'] as int?) ?? 0,
      };

      // Real Estate: Rental Income & Vacancy
      final reRes = await db.rawQuery("SELECT COUNT(*) as total, SUM(CASE WHEN status = 'rented' THEN 1 ELSE 0 END) as rented FROM real_estate_units WHERE is_deleted = 0");
      int totalUnits = (reRes.first['total'] as int?) ?? 0;
      int rentedUnits = (reRes.first['rented'] as int?) ?? 0;
      kpis['real_estate'] = {
        'total_units': totalUnits,
        'occupancy_rate': totalUnits > 0 ? (rentedUnits / totalUnits * 100) : 0.0,
      };

    } catch (e) {
      debugPrint("❌ Industry KPI Error: $e");
    }
    return kpis;
  }
}
