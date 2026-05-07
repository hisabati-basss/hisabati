import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/ai_chat_controller.dart';
import '../widgets/robot_avatar.dart';
import '../theme/app_theme_extension.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class AiCenterDock extends StatefulWidget {
  final Function(int)? onNavigate;
  const AiCenterDock({super.key, this.onNavigate});

  @override
  State<AiCenterDock> createState() => _AiCenterDockState();
}


class _AiCenterDockState extends State<AiCenterDock> with TickerProviderStateMixin {
  late AiChatController _controller;
  final TextEditingController _textController = TextEditingController();
  
  bool _isExpanded = false;
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = Provider.of<AiChatController>(context);
    
    _controller.onNavigateRequested = (index) {
      if (widget.onNavigate != null) widget.onNavigate!(index);
      _toggleExpansion(false);
    };
  }

  void _toggleExpansion(bool expand) {
    setState(() => _isExpanded = expand);
    if (expand) {
      _morphController.forward();
    } else {
      _morphController.reverse();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Fullscreen Backdrop when expanded
        if (_isExpanded)
          GestureDetector(
            onTap: () => _toggleExpansion(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              color: Colors.black.withValues(alpha: _isExpanded ? 0.3 : 0.0),
              width: size.width,
              height: size.height,
            ),
          ),

        // THE SMART DOCK
        AnimatedBuilder(
          animation: _morphAnimation,
          builder: (context, child) {
            double expandVal = _morphAnimation.value;
            double curveVal = Curves.easeInOutCubic.transform(expandVal.clamp(0.0, 1.0));
            
            double width = isMobile 
              ? size.width * (0.85 + (curveVal * 0.15)) 
              : (340 + (curveVal * 280)); // Slightly wider base
            double height = 64 + (curveVal * 450); 
            double bottomPadding = 24 + (curveVal * 12);

            return Positioned(
              bottom: bottomPadding,
              child: Hero(
                tag: 'ai_dock',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      // Premium Gradient background when speaking
                      gradient: _controller.isSpeaking 
                        ? context.primaryGradient 
                        : LinearGradient(
                            colors: [
                              context.cardSurface,
                              context.cardSurface.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                      borderRadius: BorderRadius.circular(_isExpanded ? 32 : 100),
                      border: Border.all(
                        color: _controller.isSpeaking 
                          ? Colors.white.withValues(alpha: 0.3) 
                          : context.cardBorder.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_controller.isSpeaking ? sunsetEnd : Colors.black)
                              .withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_isExpanded ? 32 : 100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // Deeper blur
                        child: _isExpanded 
                          ? _buildExpandedContent(curveVal.clamp(0.0, 1.0)) 
                          : _buildCollapsedContent(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // COLLAPSED: The sleek horizontal capsule
  Widget _buildCollapsedContent() {
    return Row(
      children: [
        const SizedBox(width: 8),
        // Mic Circle
        _buildActionButton(
          icon: _controller.isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: _controller.isListening ? Colors.redAccent : primaryOrange,
          onTap: () {
             _controller.toggleListening();
             if (!_isExpanded) _toggleExpansion(true);
          },
          isCircle: true,
        ),
        
        // Input Area
        Expanded(
          child: GestureDetector(
            onTap: () => _toggleExpansion(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child: Text(
                _controller.selectedFile != null ? "تحليل ملف..." : "تحدث مع مساعد حساباتي...",
                style: TextStyle(color: context.mutedText, fontSize: 13),
              ),
            ),
          ),
        ),

        // Small Actions
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: context.mutedText, size: 22),
          onPressed: () => _controller.pickFile(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // EXPANDED: The immersive chat experience
  Widget _buildExpandedContent(double progress) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "مساعد حساباتي",
                style: TextStyle(
                  color: primaryOrange.withValues(alpha: progress.clamp(0.0, 1.0)),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_fullscreen_rounded, color: context.mutedText, size: 18),
                onPressed: () => _toggleExpansion(false),
              ),
            ],
          ),
        ),

        // Robot and History
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                RobotAvatar(
                  state: _controller.robotState,
                  size: 160 * progress, 
                ),
                const SizedBox(height: 20),
                
                // Status or Last Message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _controller.isThinking ? tr('common.thinking') : (_controller.messages.isNotEmpty ? _controller.messages.first.text : tr('screens.ai_welcome')),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: _controller.isSpeaking ? Colors.white : context.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60), // Space for input bar
              ],
            ),
          ),
        ),

        // Input Bar (Fixed at bottom of dock)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.cardBorder.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              _buildActionButton(
                 icon: _controller.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                 color: _controller.isListening ? Colors.redAccent : primaryOrange,
                 onTap: () => _controller.toggleListening(),
                 isCircle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "أرسل رسالة إلى مساعد حساباتي...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _controller.sendTextMessage(val);
                      _textController.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: primaryOrange, size: 24),
                onPressed: () {
                   if (_textController.text.trim().isNotEmpty) {
                      _controller.sendTextMessage(_textController.text);
                      _textController.clear();
                   }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isCircle = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
