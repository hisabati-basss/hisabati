import 'package:flutter/material.dart';

// Global Notifier for Theme Toggle
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// Apple-style Premium Palette
const primaryOrange = Color(0xFFFF6B00);
const sunsetStart = Color(0xFFFF8C42);
const sunsetEnd = Color(0xFFFF3D00);
const accentGold = Color(0xFFFFD700);

// --- PERFORMANCE DIAGNOSTIC CONTROLS ---
final ValueNotifier<bool> perfShowBlur = ValueNotifier<bool>(true);
final ValueNotifier<bool> perfShowShadows = ValueNotifier<bool>(true);
final ValueNotifier<bool> perfShowAnimations = ValueNotifier<bool>(true);

extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Background Surfaces
  Color get bgSurface => isDark ? const Color(0xFF0F0F12) : const Color(0xFFF3F4F6);
  Color get scaffoldBackground => bgSurface;
  Color get primaryOrange => const Color(0xFFFF6B00);
  
  // Premium Glassmorphism & Performance Fallbacks
  Color get cardSurface {
    if (!perfShowBlur.value) {
       return isDark ? const Color(0xFF1E1E24) : Colors.white;
    }
    return isDark 
      ? Colors.white.withValues(alpha: 0.08) 
      : Colors.white.withValues(alpha: 0.45);
  }
      
  Color get cardBorder => isDark 
      ? Colors.white.withValues(alpha: 0.15) 
      : Colors.black.withValues(alpha: 0.1);

  // Gradient for Primary Actions
  Gradient get primaryGradient => const LinearGradient(
    colors: [sunsetStart, sunsetEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Colors
  Color get textColor => isDark ? Colors.white : const Color(0xFF1E1E24);
  Color get mutedText => isDark ? const Color(0xFF9BA0A6) : const Color(0xFF5F6368);

  // Glassmorphism specific
  Color get glassMenu => isDark 
      ? const Color(0xFF1E1E24).withValues(alpha: 0.85) 
      : Colors.white.withValues(alpha: 0.75);
  
  // Additional elements
  Color get successColor => const Color(0xFF00F260); // Green
  Color get errorColor => Colors.redAccent;
  Color get badgeSurface => isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3F4F6);

  // GLASS HUD ENHANCEMENTS
  Color get deepGlass => isDark 
      ? Colors.black.withValues(alpha: 0.4) 
      : Colors.white.withValues(alpha: 0.9);
      
  double get glassBlurLow => 8.0;
  double get glassBlurMed => 12.0;
  double get glassBlurHigh => 20.0;

  // --- COMPACT MODE TOKENS (NEW) ---
  double get headerSize => 18.0;     
  double get subHeaderSize => 14.0;  
  double get bodySize => 10.0;       
  double get cardPadding => 6.0;     
  double get cardRadius => 10.0;     
  double get sectionPadding => 10.0; 
  double get iconSize => 16.0;        

  // THEME REACTIVE OBSIDIAN GLASS
  Color get obsidianGlass {
    return isDark 
      ? const Color(0xFF1A1A1E).withValues(alpha: 0.92) // 🌑 Deep Obsidian
      : const Color(0xFFFFFFFF).withValues(alpha: 0.45); // ☀️ True Glass Light
  }

  // LIGHTER GLASS FOR FORMS & LISTS
  Color get sheetGlass {
    return isDark 
      ? const Color(0xFF2C2C2E).withValues(alpha: 0.50)
      : const Color(0xFFF2F2F7).withValues(alpha: 0.55); // ☀️ True Glass Light
  }


  Color get glassBorder => isDark 
      ? Colors.white.withValues(alpha: 0.12) 
      : Colors.black.withValues(alpha: 0.08);

  double get glassBlurLevel => 25.0; // 📉 Deep Blur Constant

  // --- NEW UNIFIED DECORATIONS ---
  BoxDecoration get glassDecoration => BoxDecoration(
    color: cardSurface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: cardBorder),
    boxShadow: isDark ? [] : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Color get primaryColor => primaryOrange;
}
