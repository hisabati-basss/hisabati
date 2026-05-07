import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final dynamic borderRadius; // Can be double or BorderRadiusGeometry
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.borderRadius = 24.0,
    this.color,
    this.padding,
    this.margin,
    this.border,
    this.width,
    this.height,
  });

  BorderRadiusGeometry get _effectiveRadius {
    if (borderRadius is num) {
      return BorderRadius.circular((borderRadius as num).toDouble());
    }
    if (borderRadius is BorderRadiusGeometry) {
      return borderRadius as BorderRadiusGeometry;
    }
    return BorderRadius.circular(24.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final glassColor = color ?? (isDark 
      ? const Color(0xFF2C2C2E).withValues(alpha: 0.65) 
      : const Color(0xFFF2F2F7).withValues(alpha: 0.75)); 
    
    final borderColor = isDark 
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.08);

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: _effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: _effectiveRadius,
              border: border ?? Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
