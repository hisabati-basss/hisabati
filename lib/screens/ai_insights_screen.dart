import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';
import '../services/ai_forecasting_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/config/app_constants.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final AiForecastingService _forecastingService = AiForecastingService();
  bool _isLoading = true;
  Map<String, dynamic>? _cashFlowData;
  List<Map<String, dynamic>> _stockAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cashFlow = await _forecastingService.predictCashFlow30Days();
      final stockAlerts = await _forecastingService.predictStockDepletion();
      
      if (mounted) {
        setState(() {
          _cashFlowData = cashFlow;
          _stockAlerts = stockAlerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppConstants.primaryOrange, size: context.iconSize + 4),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ai.insights_summary".tr(), style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2)),
                  const SizedBox(height: 2),
                  Text("ai.insights_performance".tr(), style: TextStyle(fontSize: context.headerSize, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cash Flow Insights
          if (_cashFlowData != null)
            _buildInsightCard(
              context,
              "ai.liquidity_prediction".tr(),
              _cashFlowData!['warning_message'] ?? "ai.liquidity_stable".tr(),
              _cashFlowData!['is_healthy'] ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
              _cashFlowData!['is_healthy'] ? Colors.green : Colors.orange,
            ),
          
          const SizedBox(height: 12),

          // Stock Depletion Insights
          if (_stockAlerts.isNotEmpty)
            ..._stockAlerts.take(2).map((alert) => Column(
              children: [
                _buildInsightCard(
                  context,
                  "${"inventory.stock_alert".tr()}: ${alert['item_name']}",
                  "ai.stock_depletion_warning".tr(args: [alert['days_left'].toString()]),
                  Icons.inventory_2_outlined,
                  alert['severity'] == 'critical' ? Colors.redAccent : Colors.orangeAccent,
                ),
                const SizedBox(height: 8),
              ],
            )),

          const SizedBox(height: 16),
          Text(
            "ai.smart_recommendations".tr(),
            style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold, color: context.textColor),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: isMobile ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 2.8 : 1.8,
            children: [
              _buildRecommendation(
                context,
                "ai.optimize_cashflow".tr(),
                _cashFlowData!['is_healthy'] 
                  ? "ai.cashflow_good_hint".tr()
                  : "ai.cashflow_bad_hint".tr(),
                Icons.lightbulb,
              ),
              _buildRecommendation(
                context,
                "ai.reorder_stock".tr(),
                _stockAlerts.isEmpty 
                  ? "ai.stock_stable_hint".tr()
                  : "ai.stock_depleting_hint".tr(),
                Icons.shopping_cart,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(context.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: context.iconSize),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize, color: context.textColor)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: context.mutedText, fontSize: context.bodySize)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(
    BuildContext context,
    String title,
    String hint,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(context.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryOrange, size: context.iconSize),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize)),
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
