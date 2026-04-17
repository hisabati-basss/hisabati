import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/ai_chat_controller.dart';
import '../services/industry_provider.dart';
import '../services/reporting_service.dart';
import '../widgets/robot_avatar.dart';
import '../theme/app_theme_extension.dart';

class AiCoreScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AiCoreScreen({super.key, this.onNavigate});

  @override
  State<AiCoreScreen> createState() => _AiCoreScreenState();
}

class _AiCoreScreenState extends State<AiCoreScreen> {
  final AiChatController _controller = AiChatController();
  final TextEditingController _textController = TextEditingController();
  bool _isScannerOpen = false;

  @override
  void initState() {
    super.initState();
    _controller.onNavigateRequested = (index) {
      if (widget.onNavigate != null) widget.onNavigate!(index);
    };

    _controller.onIndustryChanged = (type) {
      Provider.of<IndustryProvider>(context, listen: false).setIndustry(type);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr('ai.sector_switched')}: ${type.toString().split('.').last}"))
      );
    };

    _controller.onReportRequested = (type) async {

       await ReportingService().generateAndShareReport(type);
    };

    _controller.addListener(() {
      if (_controller.messages.isNotEmpty && _controller.messages.first.text.contains('[SCAN_BARCODE]')) {
        setState(() => _isScannerOpen = true);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header with Title and Clear button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "HBASSS - وكيلك المالي الذكي",
                    style: TextStyle(
                      color: context.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: context.mutedText,
                      size: 20,
                    ),
                    tooltip: tr('ai.reset_tooltip'),
                    onPressed: () => _controller.clearChat(),
                  ),
                ],
              ),

              // Central Robot Persona
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RobotAvatar(
                      state: _controller.robotState,
                      size: 240, // Much larger as requested
                    ),
                    const SizedBox(height: 24),
                    
                    // Status Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _controller.isThinking
                            ? tr('ai.analyzing')
                            : _controller.isListening
                            ? tr('ai.listening')
                            : _controller.isSpeaking
                            ? tr('ai.speaking')
                            : tr('ai.greeting'),
                        key: ValueKey<String>(_controller.robotState.toString()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _controller.isSpeaking ? primaryOrange : context.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Latest Message Display (Bubble style)
                    if (_controller.messages.isNotEmpty)
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.cardSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
                            ),
                            constraints: const BoxConstraints(maxHeight: 100),
                            child: SingleChildScrollView(
                              child: Text(
                                _controller.messages.first.text,
                                style: TextStyle(
                                  color: _controller.messages.first.isUser
                                      ? context.mutedText
                                      : primaryOrange,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          
                          // ✨ RETRY BUTTON (Visible only on failure)
                          if (_controller.isLastRequestFailed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () => _controller.retryLastMessage(),
                                icon: const Icon(Icons.refresh_rounded, color: primaryOrange, size: 16),
                                label: Text(
                                  "إعادة محاولة جيميناي",
                                  style: TextStyle(color: primaryOrange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: primaryOrange.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Enhanced Input Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardSurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: context.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Voice/Stop Button
                    GestureDetector(
                      onTap: () => _controller.toggleListening(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _controller.isListening 
                              ? [Colors.redAccent, Colors.red] 
                              : [primaryOrange, accentGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_controller.isListening ? Colors.red : primaryOrange)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _controller.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.black87,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: tr('ai.input_hint'),
                          hintStyle: TextStyle(
                            color: context.mutedText,
                            fontSize: 13,
                          ),
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

                    // File Attachment (Small action)
                    IconButton(
                      icon: Icon(
                        _controller.selectedFile != null
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: _controller.selectedFile != null 
                            ? Colors.greenAccent 
                            : context.mutedText,
                        size: 24,
                      ),
                      onPressed: () => _controller.selectedFile != null
                          ? _controller.removeFile()
                          : _controller.pickFile(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    if (!_isScannerOpen) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  setState(() => _isScannerOpen = false);
                  _controller.sendTextMessage("تم مسح الباركود: ${barcodes.first.rawValue}");
                }
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => setState(() => _isScannerOpen = false),
              ),
            ),
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: primaryOrange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
