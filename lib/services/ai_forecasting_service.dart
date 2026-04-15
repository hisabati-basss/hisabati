import '../services/database_helper.dart';

class AiForecastingService {
  final DatabaseHelper _db = DatabaseHelper();

  /// AI Feature 1: Inventory Depletion Radar (نظام رادار التنبؤ بنفاذ المخزون)
  Future<List<Map<String, dynamic>>> predictStockDepletion({int analysisDays = 30}) async {
    final db = await _db.database;
    final items = await _db.getProducts();
    
    // Get recent sales invoice lines for consumption analysis
    final startDate = DateTime.now().subtract(Duration(days: analysisDays)).toIso8601String().split('T')[0];
    final salesLines = await db.rawQuery('''
      SELECT il.name, SUM(il.quantity) as total_sold
      FROM invoice_lines il
      JOIN invoices i ON il.invoice_id = i.id
      WHERE i.issue_date >= ? AND i.status = 'posted'
      GROUP BY il.name
    ''', [startDate]);

    Map<String, double> consumptionByName = {};
    for (var sl in salesLines) {
      consumptionByName[sl['name']?.toString() ?? ''] = (sl['total_sold'] as num?)?.toDouble() ?? 0;
    }

    List<Map<String, dynamic>> alerts = [];

    for (var item in items) {
      final name = item['name']?.toString() ?? '';
      final stock = (item['quantity'] as num?)?.toDouble() ?? 0;
      final consumed = consumptionByName[name] ?? 0;

      if (consumed > 0 && stock > 0) {
        final dailyBurnRate = consumed / analysisDays;
        final daysLeft = (stock / dailyBurnRate).round();

        if (daysLeft <= 10) {
          alerts.add({
            'item_name': name,
            'current_stock': stock,
            'daily_burn_rate': dailyBurnRate.toStringAsFixed(2),
            'days_left': daysLeft,
            'depletion_date': DateTime.now().add(Duration(days: daysLeft)),
            'severity': daysLeft <= 3 ? 'critical' : 'warning',
          });
        }
      } else if (stock == 0 && consumed > 0) {
        alerts.add({
          'item_name': name,
          'current_stock': 0,
          'daily_burn_rate': (consumed / analysisDays).toStringAsFixed(2),
          'days_left': 0,
          'depletion_date': DateTime.now(),
          'severity': 'out_of_stock',
        });
      }
    }

    alerts.sort((a, b) => (a['days_left'] as int).compareTo(b['days_left'] as int));
    return alerts;
  }

  /// AI Feature 2: Cash Flow Prediction (التنبؤ بالسيولة النقدية)
  Future<Map<String, dynamic>> predictCashFlow30Days() async {
    final db = await _db.database;

    // 1. Current cash balance
    final cashRes = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total FROM accounts 
      WHERE code LIKE '111%' OR code LIKE '112%'
    ''');
    double currentCash = (cashRes.first['total'] as num?)?.toDouble() ?? 0;

    // 2. Recent revenue pace
    final last30 = DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    final salesRes = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total FROM invoices 
      WHERE issue_date >= ? AND status = 'posted'
    ''', [last30]);
    double monthlyRevenue = (salesRes.first['total'] as num?)?.toDouble() ?? 0;

    // 3. Upcoming salaries
    final empRes = await db.rawQuery('''
      SELECT COALESCE(SUM(salary + COALESCE(housing,0) + COALESCE(transport,0)), 0) as total
      FROM employees WHERE status = 'active'
    ''');
    double upcomingSalaries = (empRes.first['total'] as num?)?.toDouble() ?? 0;

    // 4. Pending purchase invoices
    final purchaseRes = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total FROM purchase_invoices 
      WHERE payment_type = 'credit'
    ''');
    double pendingPurchases = (purchaseRes.first['total'] as num?)?.toDouble() ?? 0;

    double projected = currentCash + monthlyRevenue - (upcomingSalaries + pendingPurchases);

    return {
      'current_cash': currentCash,
      'projected_revenue': monthlyRevenue,
      'upcoming_liabilities': (upcomingSalaries + pendingPurchases),
      'projected_net_cash_30d': projected,
      'is_healthy': projected > 0,
      'warning_message': projected < 0
          ? "تحذير ذكي ⚠️: السيولة الحالية ومتوسط المبيعات قد لا يغطي الالتزامات ورواتب الشهر القادم. يُتوقع عجز بقيمة ${projected.abs().toStringAsFixed(2)}."
          : "السيولة المتوقعة تبدو مستقرة وآمنة وتغطي الرواتب والتزامات الشهر القادم.",
    };
  }
}
