import 'package:flutter/foundation.dart';

enum UserRole { admin, manager, accountant, hrManager, employee, viewer }

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  UserRole _currentRole = UserRole.admin;
  UserRole get currentRole => _currentRole;

  void setRole(UserRole role) {
    _currentRole = role;
    debugPrint("🛡️ Role Changed: $role");
  }

  // Permissions for each role
  static const Map<UserRole, Set<String>> _permissions = {
    UserRole.admin: {'*'}, // Everything
    UserRole.manager: {
      'dashboard', 'invoices', 'purchases', 'inventory', 'hr', 'payroll',
      'reports', 'accounting', 'projects', 'assets', 'cheques', 'custody',
      'pos', 'warehouse', 'manufacturing', 'investments', 'realEstate',
      'commissions', 'audit_view', 'ai_chat'
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
  };

  /// Main permission check
  bool hasPermission(String module) {
    final perms = _permissions[_currentRole] ?? {};
    return perms.contains('*') || perms.contains(module);
  }

  /// Ability to modify data
  bool canEdit() => _currentRole != UserRole.viewer;

  /// Ability to hard delete (archiving only for lower roles)
  bool canDelete() => _currentRole == UserRole.admin || _currentRole == UserRole.manager;
  
  /// Check if a sidebar/hub item should be visible
  bool isVisible(String module) => hasPermission(module);
}
