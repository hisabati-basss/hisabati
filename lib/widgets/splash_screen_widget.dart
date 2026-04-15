import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/image/logo icon.PNG',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      color: primaryOrange,
                      backgroundColor: Colors.white10,
                      minHeight: 4,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "جاري تحميل البيانات...",
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
