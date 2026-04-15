import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme_extension.dart';

class AiChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? attachmentName;

  const AiChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.attachmentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? context.primaryGradient : null,
              color: isUser ? null : context.cardSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              border: Border.all(
                color: isUser 
                  ? Colors.white.withValues(alpha: 0.2) 
                  : context.cardBorder.withValues(alpha: 0.1),
              ),
              boxShadow: [
                if (isUser)
                  BoxShadow(
                    color: sunsetEnd.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (attachmentName != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            attachmentName!,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : context.textColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Timestamp (Dummy for now)
          const SizedBox(height: 4),
          Text(
            "العاشرة مساءً", // Timestamp placeholder
            style: TextStyle(
              fontSize: 10,
              color: context.mutedText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
