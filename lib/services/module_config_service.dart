// lib/services/module_config_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/module_definitions.dart';
import 'subscription_service.dart';

class ModuleConfigService extends ChangeNotifier {
  static final ModuleConfigService _instance = ModuleConfigService._internal();
  factory ModuleConfigService() => _instance;
  ModuleConfigService._internal();

  bool _isInitialized = false;
  bool _setupCompleted = false;
  List<String> _activeModules = [];
  bool _showLockedModules = true;

  bool get isInitialized => _isInitialized;
  bool get setupCompleted => _setupCompleted;
  List<String> get activeModules => _activeModules;
  bool get showLockedModules => _showLockedModules;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _setupCompleted = prefs.getBool('setup_completed') ?? false;
    
    // 🚀 Full Activation: Force all modules to be active
    _activeModules = AppModules.allModules.map((m) => m.id).toList();
    
    _showLockedModules = prefs.getBool('show_locked_modules') ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  bool isModuleActive(String moduleId) {
    // 0 = AI, 12 = Settings, 100 = Hub (Always active base modules)
    if (['ai', 'settings', 'hub'].contains(moduleId)) return true;
    
    // Admin role might override this, but for now strict check:
    return _activeModules.contains(moduleId);
  }

  bool isModuleLockedBySubscription(String moduleId) {
    // 🔓 Full Activation: All modules are unlocked.
    return false;
  }

  Future<void> toggleShowLockedModules(bool show) async {
    _showLockedModules = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_locked_modules', show);
    notifyListeners();
  }

  Future<void> saveModules(List<String> modules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('active_modules', modules);
    await prefs.setBool('setup_completed', true);
    _activeModules = modules;
    _setupCompleted = true;
    notifyListeners();
  }
}
