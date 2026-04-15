import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_chat_controller.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/ai_agent_hud.dart';
import '../theme/app_theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';

class AiHomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AiHomeScreen({super.key, this.onNavigate});

  @override
  State<AiHomeScreen> createState() => _AiHomeScreenState();
}

class _AiHomeScreenState extends State<AiHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow Layers for 3D depth
          _buildBackgroundGlows(size),

          // Main HUD Layout (Redundant elements removed, now managed in main.dart)
          Center(
            child: Opacity(
              opacity: 0.3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 80, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    tr('screens.ai_welcome'), 
                    style: TextStyle(
                      color: context.mutedText, 
                      fontSize: 16, 
                      letterSpacing: 1.2
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlows(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: size.width * 0.1,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [primaryOrange.withValues(alpha: 0.1), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

}

