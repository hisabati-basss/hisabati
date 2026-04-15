import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class AppleEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AppleEntrance({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: perfShowAnimations,
      builder: (context, showAnimations, child) {
        if (!showAnimations) return child!;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - value)),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      child: child,
    );
  }
}
