import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';

class LanguageToggleCapsule extends StatelessWidget {
  const LanguageToggleCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    bool isArabic = context.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (isArabic) {
          context.setLocale(const Locale('en'));
        } else {
          context.setLocale(const Locale('ar'));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            width: 80,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 32,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: isArabic ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.blueAccent.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: (isArabic ? Colors.greenAccent : Colors.blueAccent).withValues(alpha: 0.4),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isArabic ? "AR" : "EN",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: isArabic ? 0 : 28, right: isArabic ? 28 : 0),
                    child: Text(
                      isArabic ? "EN" : "AR",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
