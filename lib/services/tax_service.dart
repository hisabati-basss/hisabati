import 'database_helper.dart';
import 'notification_service.dart';

class TaxService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Checks for critical tax scenarios and triggers system notifications if needed.
  Future<void> checkAndTriggerTaxAlerts() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final notifications = NotificationService();

    // 1. Check filing deadline (within 7 days of end of quarter)
    // Quarter ends: Mar 31, Jun 30, Sep 30, Dec 31
    final quarterEnds = [
      DateTime(now.year, 3, 31),
      DateTime(now.year, 6, 30),
      DateTime(now.year, 9, 30),
      DateTime(now.year, 12, 31),
    ];

    for (var end in quarterEnds) {
      final daysDiff = end.difference(now).inDays;
      if (daysDiff >= 0 && daysDiff <= 7) {
        notifications.notify(
          title: "📅 اقتراب موعد الإقرار الضريبي",
          message: "بقي $daysDiff أيام على نهاية الفترة الضريبية الحالية. يرجى مراجعة فواتيرك.",
          type: NotificationType.warning,
        );
        break;
      }
    }

    // 2. Registration Threshold check (SAR 375,000 illustrative)
    final revenueRes = await db.rawQuery("SELECT SUM(total) as total_rev FROM invoices WHERE is_deleted = 0");
    double totalRevenue = (revenueRes.first['total_rev'] as num?)?.toDouble() ?? 0;
    if (totalRevenue > 300000 && totalRevenue < 375000) {
      notifications.notify(
        title: "⚡ تنبيه حد التسجيل الضريبي",
        message: "لقد اقتربت مبيعاتك من حد التسجيل الإلزامي (375,000 ريال). يرجى الاستعداد للتسجيل.",
        type: NotificationType.warning,
      );
    }

    // 3. Missing Tax IDs in B2B invoices (sample check for the last 10 invoices)
    final missingTaxIds = await db.rawQuery('''
      SELECT i.id, c.name FROM invoices i
      JOIN clients c ON i.client_id = c.id
      WHERE c.tax_id IS NULL OR c.tax_id = ''
      ORDER BY i.issue_date DESC LIMIT 5
    ''');
    
    if (missingTaxIds.isNotEmpty) {
      notifications.notify(
        title: "📝 فواتير بدون رقم ضريبي",
        message: "يوجد ${missingTaxIds.length} فواتير حديثة لعملاء بدون رقم ضريبي مسجل.",
        type: NotificationType.info,
      );
    }
  }

  /// Generates a ZATCA-compliant VAT Return summary for a given period.
  Future<Map<String, dynamic>> generateVatReturn(String startDate, String endDate) async {
    final db = await _dbHelper.database;

    // 1. Output VAT (Sales Invoices)
    // We treat 'is_return' = 1 as Credit Notes (which reduce output VAT)
    final salesRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN is_return = 0 THEN tax_amount ELSE 0 END) as output_vat,
        SUM(CASE WHEN is_return = 1 THEN tax_amount ELSE 0 END) as return_vat,
        SUM(CASE WHEN is_return = 0 THEN subtotal ELSE 0 END) as sales_revenue,
        SUM(CASE WHEN is_return = 1 THEN subtotal ELSE 0 END) as return_revenue
      FROM invoices 
      WHERE issue_date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    // 2. Input VAT (Purchase Invoices & Maintenance)
    final purchaseRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN is_return = 0 THEN tax_amount ELSE 0 END) as input_vat,
        SUM(CASE WHEN is_return = 1 THEN tax_amount ELSE 0 END) as return_input_vat,
        SUM(CASE WHEN is_return = 0 THEN subtotal ELSE 0 END) as purchase_cost,
        SUM(CASE WHEN is_return = 1 THEN subtotal ELSE 0 END) as return_cost
      FROM purchase_invoices 
      WHERE issue_date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    double outputVat = (salesRes.first['output_vat'] as num?)?.toDouble() ?? 0.0;
    double outputReturnVat = (salesRes.first['return_vat'] as num?)?.toDouble() ?? 0.0;
    
    double inputVat = (purchaseRes.first['input_vat'] as num?)?.toDouble() ?? 0.0;
    double inputReturnVat = (purchaseRes.first['return_input_vat'] as num?)?.toDouble() ?? 0.0;

    // Net Output VAT = Output VAT - Output Return VAT (Credit Notes)
    double netOutputVat = outputVat - outputReturnVat;
    
    // Net Input VAT = Input VAT - Input Return VAT
    double netInputVat = inputVat - inputReturnVat;

    // Tax Due (Payable to ZATCA)
    double taxDue = netOutputVat - netInputVat;

    return {
      'total_sales_revenue': (salesRes.first['sales_revenue'] as num?)?.toDouble() ?? 0.0,
      'total_sales_returns': (salesRes.first['return_revenue'] as num?)?.toDouble() ?? 0.0,
      'output_vat': outputVat,
      'credit_notes_vat': outputReturnVat,
      'net_output_vat': netOutputVat,
      'input_vat': inputVat,
      'input_return_vat': inputReturnVat,
      'net_input_vat': netInputVat,
      'tax_due': taxDue,
    };
  }

  /// Calculates a highly approximate Zakat base (وعاء الزكاة)
  Future<Map<String, double>> estimateZakat(String yearStartDate, String yearEndDate) async {
    final db = await _dbHelper.database;
    
    // Zakat roughly = (Equity + Net Profit - Fixed Assets) * 2.5%
    // This is a simplified estimation model for the dashboard.
    
    // 1. Net Profit from P&L (simplified approach via journal entries for the year)
    final pnlRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN a.type = 'revenue' THEN (jel.credit - jel.debit) ELSE 0 END) as revenue,
        SUM(CASE WHEN a.type = 'expense' THEN (jel.debit - jel.credit) ELSE 0 END) as expense
      FROM journal_entry_lines jel
      JOIN journal_entries je ON jel.entry_id = je.id
      JOIN accounts a ON jel.account_id = a.id
      WHERE je.date BETWEEN ? AND ?
    ''', [yearStartDate, yearEndDate]);
    
    double revenue = (pnlRes.first['revenue'] as num?)?.toDouble() ?? 0.0;
    double expense = (pnlRes.first['expense'] as num?)?.toDouble() ?? 0.0;
    double netProfit = revenue - expense;

    // 2. Fixed Assets (Net Book Value approx)
    final assetsRes = await db.rawQuery('''
      SELECT SUM(cost_price) as total_cost 
      FROM assets WHERE status != 'scrap' AND purchase_date <= ?
    ''', [yearEndDate]);
    
    final accDepRes = await db.rawQuery('''
      SELECT SUM(amount) as total_dep 
      FROM asset_depreciation_logs WHERE date <= ?
    ''', [yearEndDate]);
    
    double assetsCost = (assetsRes.first['total_cost'] as num?)?.toDouble() ?? 0.0;
    double accDep = (accDepRes.first['total_dep'] as num?)?.toDouble() ?? 0.0;
    double fixedAssetsNBV = assetsCost - accDep;

    // 3. Equity (Capital + Retained Earnings at start of year) - we'll mock Equity from Capital Account
    final capitalRes = await db.rawQuery("SELECT balance FROM accounts WHERE id = 'ACC_CAPITAL'");
    double capital = capitalRes.isNotEmpty ? (capitalRes.first['balance'] as num?)?.toDouble() ?? 0.0 : 0.0;

    double estimatedBase = (capital + netProfit) - fixedAssetsNBV;
    if (estimatedBase < 0) estimatedBase = 0;

    double estimatedZakat = estimatedBase * 0.025; // 2.5%

    return {
      'net_profit': netProfit,
      'fixed_assets_nbv': fixedAssetsNBV,
      'capital': capital,
      'zakat_base': estimatedBase,
      'estimated_zakat': estimatedZakat
    };
  }
}
