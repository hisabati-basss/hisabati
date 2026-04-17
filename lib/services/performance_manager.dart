import 'package:flutter/foundation.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme_extension.dart';

class PerformanceManager {
  
  /// Checks device hardware and applies "High Performance Mode" if RAM < 4GB.
  static Future<void> optimizeForDevice() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        // totalMemory is in megabytes for system_info_plus 0.0.6
        final totalRamMb = await SystemInfoPlus.physicalMemory;
        
        // Check RAM (4GB is 4096MB)
        final isLowRam = totalRamMb != null && totalRamMb < 3800; // Guard for ~4GB

        if (isLowRam) {
          // AUTO-OPTIMIZATION: Disable expensive effects on low-memory devices
          perfShowBlur.value = false;
          perfShowShadows.value = false;
          
          await _showSmartNotificationOnce();
        }
      }
    } catch (e) {
      // Graceful fallback if device info fails
      debugPrint("Performance Optimization failed: $e");
    }
  }

  /// Shows a one-time snackbar/banner informing the user about the auto-optimization.
  static Future<void> _showSmartNotificationOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('perf_optimized_notice_shown') ?? false;

    if (!hasShown) {
      _shouldShowAlert = true;
      await prefs.setBool('perf_optimized_notice_shown', true);
    }
  }

  static bool _shouldShowAlert = false;
  static bool get shouldShowAlert => _shouldShowAlert;
  
  static void consumeAlert() => _shouldShowAlert = false;
}
