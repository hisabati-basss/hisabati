import 'package:flutter/foundation.dart';
import 'dart:convert';

enum UserRole { admin, manager, accountant, hrManager, employee, viewer, custom }

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  UserRole _currentRole = UserRole.admin;
  UserRole get currentRole => _currentRole;

  /// Holds granular permissions from the database. Format: {'hr': {'view': true, 'create': false...}}
  Map<String, Map<String, bool>> _customPermissions = {};
  String? _currentUserId;
  String? _currentBranchId;

  void setUserContext(String userId, String roleStr, String? permissionsJson, String? branchId) {
    _currentUserId = userId;
    _currentBranchId = branchId;
    
    // Parse role
    try {
      _currentRole = UserRole.values.firstWhere((e) => e.toString().split('.').last == roleStr);
    } catch (_) {
      _currentRole = UserRole.custom;
    }

    // Parse custom permissions JSON if available
    _customPermissions.clear();
    if (permissionsJson != null && permissionsJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(permissionsJson);
        decoded.forEach((module, actions) {
          if (actions is Map) {
            _customPermissions[module] = Map<String, bool>.from(actions);
          }
        });
      } catch (e) {
        debugPrint("Error parsing permissions: $e");
      }
    }

    debugPrint("🛡️ User Context Set: Role: $_currentRole, Branch: $_currentBranchId");
  }

  // Fallback default permissions for each role
  static const Map<UserRole, Set<String>> _defaultPermissions = {
    UserRole.admin: {'*'}, // Everything
    UserRole.manager: {
      'dashboard', 'invoices', 'purchases', 'inventory', 'hr', 'payroll',
      'reports', 'accounting', 'projects', 'assets', 'cheques', 'custody',
      'pos', 'warehouse', 'manufacturing', 'investments', 'realEstate',
      'commissions', 'audit_view', 'ai_chat', 'settings'
    },
    UserRole.accountant: {
      'dashboard', 'invoices', 'purchases', 'accounting', 'reports',
      'cheques', 'custody', 'pos', 'budget', 'taxes', 'trial_balance'
    },
    UserRole.hrManager: {
      'dashboard', 'hr', 'payroll', 'reports', 'attendance', 'leaves'
    },
    UserRole.employee: {
      'dashboard', 'my_profile', 'my_payslips', 'my_attendance', 'my_leaves', 'ai_chat', 'internal_chat'
    },
    UserRole.viewer: {
      'dashboard', 'reports',
    },
    UserRole.custom: {}, // relies entirely on JSON
  };

  /// Main granular permission check
  bool hasPermission(String module, {String action = 'view'}) {
    if (_currentRole == UserRole.admin) return true;

    // Check custom JSON permissions first
    if (_customPermissions.containsKey(module)) {
      final modulePerms = _customPermissions[module]!;
      // If action is specified, check it. Otherwise, if the module exists, assume 'view' is allowed if any action is allowed.
      if (modulePerms.containsKey(action)) {
        return modulePerms[action] == true;
      }
    }

    // Fallback to role-based logic if no custom JSON defines this module
    final perms = _defaultPermissions[_currentRole] ?? {};
    if (perms.contains('*') || perms.contains(module)) {
      if (action == 'view') return true;
      if (action == 'create' || action == 'edit') return canEditFallback();
      if (action == 'delete') return canDeleteFallback();
      if (action == 'approve') return _currentRole == UserRole.manager;
    }

    return false;
  }

  /// Legacy backward compatibility
  bool canEditFallback() => _currentRole != UserRole.viewer;
  bool canDeleteFallback() => _currentRole == UserRole.admin || _currentRole == UserRole.manager;
  
  bool canEdit() => canEditFallback();
  bool canDelete() => canDeleteFallback();

  /// Check if a sidebar/hub item should be visible
  bool isVisible(String module) => hasPermission(module, action: 'view');

  /// Branch isolation logic
  bool canAccessBranch(String targetBranchId) {
    if (_currentRole == UserRole.admin || _currentRole == UserRole.manager) return true;
    if (_currentBranchId == null || _currentBranchId!.isEmpty) return true; // Global user
    return _currentBranchId == targetBranchId;
  }
}
