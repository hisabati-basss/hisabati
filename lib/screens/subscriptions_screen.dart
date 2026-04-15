import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12), // 📉 Reduced from 24
          Text(
            "باقات الاشتراك",
            style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), // 📉 Reduced from 13
          ),
          const SizedBox(height: 4), // 📉 Reduced from 8
          Text(
            "اختر الخطة المناسبة", // 📉 Shortened
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.headerSize, // 📉 Reduced from 26/36
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // 📉 Reduced from 48

          if (isMobile)
            Column(
              children: [
                _buildPriceCard(context, "الأساسية", "مجاناً", [
                  "محاسبة بسيطة",
                  "١٠٠ فاتورة/شهر",
                  "دعم فني محدود",
                ], false),
                const SizedBox(height: 24),
                _buildPriceCard(context, "الاحترافية", "٩٩ ر.س", [
                  "محاسبة AI متكاملة",
                  "ذكاء اصطناعي صوتي",
                  "تقارير ضريبية",
                  "فواتير غير محدودة",
                ], true),
                const SizedBox(height: 12), // 📉 Reduced from 24
                _buildPriceCard(context, "المؤسسات", "طلب خاص", [
                  "إدارة فروع غير محدودة",
                  "تخصيص كامل للنظام",
                  "مدير حساب مخصص",
                ], false),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPriceCard(context, "الأساسية", "مجاناً", [
                  "محاسبة بسيطة",
                  "١٠٠ فاتورة/شهر",
                  "دعم فني محدود",
                ], false),
                const SizedBox(width: 24),
                _buildPriceCard(context, "الاحترافية", "٩٩ ر.س", [
                  "محاسبة AI متكاملة",
                  "ذكاء اصطناعي صوتي",
                  "تقارير ضريبية",
                  "فواتير غير محدودة",
                ], true),
                const SizedBox(width: 12), // 📉 Reduced from 24
                _buildPriceCard(context, "المؤسسات", "طلب خاص", [
                  "إدارة فروع غير محدودة",
                  "تخصيص كامل للنظام",
                  "مدير حساب مخصص",
                ], false),
              ],
            ),
          const SizedBox(height: 24), // 📉 Reduced from 48
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    String title,
    String price,
    List<String> features,
    bool isFeatured,
  ) {
    return Container(
      width: 260, // 📉 Reduced from 320
      padding: EdgeInsets.all(context.cardPadding * 1.5), // 📉 Reduced from 32
      decoration: BoxDecoration(
        color: isFeatured
            ? primaryOrange.withValues(alpha: 0.1)
            : context.cardSurface,
        borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 32
        border: Border.all(
          color: isFeatured ? primaryOrange : context.cardBorder.withValues(alpha: 0.5),
          width: isFeatured ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFeatured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 📉 Reduced
              margin: const EdgeInsets.only(bottom: 12), // 📉 Reduced from 16
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 100
              ),
              child: Text(
                "الأكثر شيوعاً",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: context.bodySize - 3, // 📉 Reduced from 10
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(fontSize: context.subHeaderSize, fontWeight: FontWeight.bold), // 📉 Reduced from 20
          ),
          const SizedBox(height: 8), // 📉 Reduced from 12
          Text(
            price,
            style: TextStyle(
              fontSize: context.headerSize + 4, // 📉 Reduced from 32
              fontWeight: FontWeight.bold,
              color: isFeatured ? primaryOrange : context.textColor,
            ),
          ),
          const SizedBox(height: 4), // 📉 Reduced from 8
          Text(
            isFeatured ? "كل شهر / مستخدم" : "متاح دائماً", // 📉 Shortened
            style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 2), // 📉 Reduced from 12
          ),
          const SizedBox(height: 16), // 📉 Reduced from 32
          const Divider(color: Colors.white10),
          const SizedBox(height: 16), // 📉 Reduced from 32
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8), // 📉 Reduced from 16
              child: Row(
                children: [
                   Icon(
                    Icons.check_circle,
                    color: primaryOrange,
                    size: context.iconSize, // 📉 Reduced from 18
                  ),
                  const SizedBox(width: 8), // 📉 Reduced from 12
                  Expanded(
                    child: Text(f, style: TextStyle(fontSize: context.bodySize)), // 📉 Reduced from 14
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16), // 📉 Reduced from 32
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isFeatured
                    ? primaryOrange
                    : context.cardBorder,
                foregroundColor: isFeatured
                    ? Colors.black87
                    : context.textColor,
                padding: const EdgeInsets.symmetric(vertical: 8), // 📉 Reduced from 16
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 16
                ),
              ),
              child: const Text(
                "اشترك الآن",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
