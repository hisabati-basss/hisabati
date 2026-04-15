import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum RobotState { idle, thinking, speaking, listening, success, error }

class RobotAvatar extends StatefulWidget {
  final RobotState state;
  final double size;

  const RobotAvatar({
    super.key,
    this.state = RobotState.idle,
    this.size = 200,
  });

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

  String get _lottieAsset {
    return 'assets/image/Anima Bot.json';
  }

class _RobotAvatarState extends State<RobotAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Glow for 3D effect
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: widget.size * 0.7 * value,
                      height: widget.size * 0.7 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Lottie.asset(
                  'assets/image/Anima Bot.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.smart_toy_rounded, size: widget.size * 0.5, color: Colors.orange);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SmartInsightCapsule extends StatefulWidget {
  final String hint;
  final String fullMessage;
  const SmartInsightCapsule({super.key, required this.hint, required this.fullMessage});

  @override
  State<SmartInsightCapsule> createState() => _SmartInsightCapsuleState();
}

class _SmartInsightCapsuleState extends State<SmartInsightCapsule> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: _isExpanded ? 300 : 120),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.orange.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _isExpanded ? widget.fullMessage : widget.hint,
                style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: _isExpanded ? 5 : 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
