import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class AppleEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AppleEntrance({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<AppleEntrance> createState() => _AppleEntranceState();
}

class _AppleEntranceState extends State<AppleEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );

    _checkAnimation();
  }

  void _checkAnimation() async {
    if (perfShowAnimations.value) {
      if (widget.delay > Duration.zero) {
        await Future.delayed(widget.delay);
      }
      if (mounted) {
        setState(() => _shouldAnimate = true);
        _controller.forward();
      }
    } else {
      if (mounted) setState(() => _shouldAnimate = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!perfShowAnimations.value) return widget.child;

    return ExcludeSemantics(
      excluding: !_shouldAnimate || _controller.value < 0.9,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return RepaintBoundary(
            child: Opacity(
              opacity: _opacity.value,
              child: FractionalTranslation(
                translation: _slide.value,
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
