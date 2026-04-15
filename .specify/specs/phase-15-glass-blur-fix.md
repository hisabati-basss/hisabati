# المرحلة 15: إصلاح واجهة الزجاج (Glass/Blur) + الألوان النهائية

## الأولوية: 🟡 متوسطة (بعد إكمال الوظائف)

## السياق
الزجاج `GlassContainer` حالياً يستخدم `Colors.white.withValues(alpha: 0.1)` بشكل ثابت.
هذا يجعل الزجاج **شفاف جداً** في كلا الوضعين (ليلي وساطع).

**المطلوب**: 
- في الوضع الليلي (Dark) → بلور **غامق** (dark frosted glass)
- في الوضع الساطع (Light) → بلور **فاتح** (light frosted glass)

## المهام

### 15.1 تحديث GlassContainer
**ملف:** `lib/widgets/glass_container.dart`

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1, // هذا يُستخدم فقط كقيمة fallback
    this.borderRadius = 24.0,
    this.color,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // === الفرق الجوهري ===
    // Dark Mode: زجاج غامق (أسود شبه شفاف)
    // Light Mode: زجاج فاتح (أبيض شبه شفاف)
    final glassColor = color ?? (isDark 
      ? const Color(0xFF1A1A2E).withValues(alpha: 0.65) // 🌑 غامق
      : Colors.white.withValues(alpha: 0.70));           // ☀️ فاتح
    
    final borderColor = isDark 
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### 15.2 مراجعة كل الشاشات التي تستخدم BackdropFilter يدوياً
البحث عن كل استخدام لـ `BackdropFilter` أو `ImageFilter.blur` في المشروع:
```bash
grep -rn "BackdropFilter\|ImageFilter.blur" lib/
```

كل موضع يُستخدم فيه `Colors.white.withValues(alpha: 0.1)` كلون للزجاج يجب تحديثه ليراعي `isDark`.

### 15.3 مراجعة ألوان الثيم
**ملف:** `lib/theme/app_theme_extension.dart`

التحقق أن كل getter يعطي ألواناً مناسبة:
- `cardSurface`: يجب أن يكون مرئياً في كلا الوضعين
- `obsidianGlass`: يجب أن يكون بلور غامق واضح في الليلي
- `sheetGlass`: يجب أن يكون قابلاً للقراءة
- `deepGlass`: يجب ألا يكون شفافاً أكثر من اللازم

## تنبيهات
> ⚠️ لا تغير ألوان `primaryOrange` أو `sunsetStart/End` — هذه هي الهوية البصرية
> ⚠️ لا تغير أحجام الخطوط في `app_theme_extension.dart` — تم ضبطها بعناية
> ⚠️ بعد التعديل، اختبر كل شاشة في كلا الوضعين (light/dark) للتأكد من أن النصوص مقروءة

## معايير القبول
- [ ] في الوضع الليلي: الزجاج **غامق** وواضح (ليس شفافاً)
- [ ] في الوضع الساطع: الزجاج **فاتح** وواضح
- [ ] كل النصوص مقروءة في كلا الوضعين
- [ ] الألوان الأساسية (البرتقالي) لم تتغير
