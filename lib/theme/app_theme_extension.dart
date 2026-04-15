import 'package:flutter/material.dart';

// Global Notifier for Theme Toggle
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

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
  double get headerSize => 18.0;     // 📉 Reduced from 20.0
  double get subHeaderSize => 14.0;  // 📉 Reduced from 18.0
  double get bodySize => 11.0;       // 📉 Reduced from 12.0
  double get cardPadding => 8.0;     // 📉 Reduced from 12.0
  double get cardRadius => 12.0;     // 📉 Reduced from 16.0
  double get sectionPadding => 12.0; // 📉 Reduced from 16.0
  double get iconSize => 18.0;        // 🧊 NEW: Ultra-Compact Icon Size

  // THEME REACTIVE OBSIDIAN GLASS
  Color get obsidianGlass {
    return isDark 
      ? const Color(0xFF1A1A2E).withValues(alpha: 0.65) // 🌑 Dark frosted
      : Colors.white.withValues(alpha: 0.75);           // ☀️ Light frosted
  }

  // LIGHTER GLASS FOR FORMS & LISTS
  Color get sheetGlass {
    return isDark 
      ? const Color(0xFF1A1A2E).withValues(alpha: 0.50)
      : Colors.white.withValues(alpha: 0.85);
  }


  Color get glassBorder => isDark 
      ? Colors.white.withValues(alpha: 0.12) 
      : Colors.black.withValues(alpha: 0.08);

  double get glassBlurLevel => 25.0; // 📉 Deep Blur Constant
}
