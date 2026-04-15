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
    this.opacity = 0.1,
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
