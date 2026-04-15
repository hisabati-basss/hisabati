import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class AiInsightsScreen extends StatelessWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: primaryOrange, size: context.iconSize + 4), // 📉 Reduced from 28
              const SizedBox(width: 8), // 📉 Reduced from 12
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ملخص الذكاء الاصطناعي",
                    style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), // 📉 Reduced from 13
                  ),
                  const SizedBox(height: 2), // 📉 Reduced from 4
                  Text(
                    "تحليل ذكي للأداء", // 📉 Shortened
                    style: TextStyle(
                      fontSize: context.headerSize, // 📉 Reduced from 24/32
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16), // 📉 Reduced from 32

          _buildInsightCard(
            context,
            "النمو المالي",
            "زيادة في الأرباح الصافية بنسبة ١٨٪.", // 📉 Shortened
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 8), // 📉 Reduced from 16
          _buildInsightCard(
            context,
            "إدارة التكاليف",
            "طفرة في مصاريف التشغيل لفرع جدة (٨٪).", // 📉 Shortened
            Icons.warning_amber,
            Colors.orange,
          ),
          const SizedBox(height: 8), // 📉 Reduced from 16
          _buildInsightCard(
            context,
            "كفاءة الموظفين",
            "ارتفاع إنتاجية المبيعات بنسبة ١٢٪.", // 📉 Shortened
            Icons.groups,
            Colors.blue,
          ),

          const SizedBox(height: 16), // 📉 Reduced from 32
          Text(
            "توصيات ذكية", // 📉 Shortened
            style: TextStyle(
              fontSize: context.subHeaderSize, // 📉 Reduced from 18
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12), // 📉 Reduced from 16

          GridView.count(
            crossAxisCount: isMobile ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, // 📉 Reduced from 16
            mainAxisSpacing: 12, // 📉 Reduced from 16
            childAspectRatio: isMobile ? 2.8 : 1.8, // 📉 Adjusted for compacting
            children: [
              _buildRecommendation(
                context,
                "تحسين التدفق النقدي",
                "بناءً على التوقعات، يفضل تقديم خصم للسداد المبكر للعملاء المتعثرين.",
                Icons.lightbulb,
              ),
              _buildRecommendation(
                context,
                "توسعة المخزون",
                "تم رصد ارتفاع في الطلب على أصناف الإلكترونيات، يوصى بطلب كمية إضافية.",
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
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8), // 📉 Reduced from 12
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: context.iconSize), // 📉 Reduced from 24
          ),
          const SizedBox(width: 12), // 📉 Reduced from 20
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: context.subHeaderSize, // 📉 Reduced from 18
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4), // 📉 Reduced from 8
                Text(
                  description,
                  style: TextStyle(color: context.mutedText, fontSize: context.bodySize), // 📉 Reduced from 14
                ),
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
      padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 24
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryOrange, size: context.iconSize), // 📉 Reduced from 24
          const SizedBox(height: 12), // 📉 Reduced from 16
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.subHeaderSize), // 📉 Reduced from 16
          ),
          const SizedBox(height: 4), // 📉 Reduced from 8
          Text(
            hint,
            style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), // 📉 Reduced from 12
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
