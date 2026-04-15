// lib/services/module_config_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleConfigService extends ChangeNotifier {
  static final ModuleConfigService _instance = ModuleConfigService._internal();
  factory ModuleConfigService() => _instance;
  ModuleConfigService._internal();

  bool _isInitialized = false;
  bool _setupCompleted = false;
  List<String> _activeModules = [];

  bool get isInitialized => _isInitialized;
  bool get setupCompleted => _setupCompleted;
  List<String> get activeModules => _activeModules;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _setupCompleted = prefs.getBool('setup_completed') ?? false;
    // Default modules if none selected
    _activeModules = prefs.getStringList('active_modules') ?? ['accounting', 'trial_balance', 'ai_chat', 'hr', 'hr_payroll', 'inventory', 'hub_commercial', 'sales_purchase', 'purchases', 'sales_commissions', 'expiry', 'expiry_control', 'cloud_inbox', 'auditing', 'erp_management', 'budgeting', 'maintenance', 'financial_reports']; 
    
    // Auto-inject new Phase 2 modules for existing users
    const newModules = ['hub_commercial', 'sales_purchase', 'purchases', 'sales_commissions', 'expiry', 'expiry_control', 'cloud_inbox', 'budgeting', 'maintenance', 'financial_reports', 'erp_management', 'auditing'];
    bool changed = false;
    for (final m in newModules) {
      if (!_activeModules.contains(m)) {
        _activeModules.add(m);
        changed = true;
      }
    }
    if (changed) {
      await prefs.setStringList('active_modules', _activeModules);
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  bool isModuleActive(String moduleId) {
    // 0 = AI, 12 = Settings, 100 = Hub (Always active base modules)
    if (['ai', 'settings', 'hub'].contains(moduleId)) return true;
    
    // Admin role might override this, but for now strict check:
    return _activeModules.contains(moduleId);
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
