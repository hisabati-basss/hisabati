# المرحلة 14: الأمان والصلاحيات والنسخ الاحتياطي

## الأولوية: 🟠 عالية

## السياق
النظام حالياً لا يملك أي نظام صلاحيات. أي مستخدم يمكنه الوصول لأي شيء. كذلك لا يوجد نسخ احتياطي محلي.

## المهام

### 14.1 نظام الصلاحيات (RBAC)
**ملف جديد:** `lib/services/permission_service.dart`

```dart
enum UserRole { admin, manager, accountant, hrManager, employee, viewer }

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  UserRole _currentRole = UserRole.admin;
  UserRole get currentRole => _currentRole;

  void setRole(UserRole role) => _currentRole = role;

  // صلاحيات كل دور
  static const Map<UserRole, Set<String>> _permissions = {
    UserRole.admin: {'*'}, // كل شيء
    UserRole.manager: {
      'dashboard', 'invoices', 'purchases', 'inventory', 'hr', 'payroll',
      'reports', 'accounting', 'projects', 'assets', 'cheques', 'custody',
      'pos', 'warehouse', 'manufacturing', 'investments', 'realEstate',
      'commissions', 'audit_view',
    },
    UserRole.accountant: {
      'dashboard', 'invoices', 'purchases', 'accounting', 'reports',
      'cheques', 'custody', 'pos', 'budget', 'taxes',
    },
    UserRole.hrManager: {
      'dashboard', 'hr', 'payroll', 'reports',
    },
    UserRole.employee: {
      'dashboard', 'my_profile', 'my_payslips', 'my_attendance', 'my_leaves',
    },
    UserRole.viewer: {
      'dashboard', 'reports',
    },
  };

  bool hasPermission(String module) {
    final perms = _permissions[_currentRole] ?? {};
    return perms.contains('*') || perms.contains(module);
  }

  bool canEdit() => _currentRole != UserRole.viewer;
  bool canDelete() => _currentRole == UserRole.admin || _currentRole == UserRole.manager;
}
```

**التكامل:**
كل شاشة تتحقق من الصلاحية:
```dart
if (!PermissionService().hasPermission('invoices')) {
  return Center(child: Text('ليس لديك صلاحية لهذه الشاشة'));
}
```

في القائمة الجانبية (`main.dart`): إخفاء العناصر غير المصرح بها.

### 14.2 سجل التدقيق المركزي (Audit Service)
**ملف جديد:** `lib/services/audit_service.dart`

```dart
class AuditService {
  static Future<void> log({
    required String action,     // 'create', 'update', 'delete', 'login', 'export'
    required String entityType, // 'invoice', 'employee', 'payment', etc.
    String? entityId,
    String? oldValue,           // JSON string
    String? newValue,           // JSON string
    bool isCritical = false,
  }) async {
    final db = await DatabaseHelper().database;
    await db.insert('security_audit', {
      'id': Uuid().v4(),
      'action_type': action,
      'description': '$action on $entityType ${entityId ?? ""}',
      'is_critical': isCritical ? 1 : 0,
      'sync_status': 0,
      'updated_at': DateTime.now().toIso8601String(),
      'device_id': await DatabaseHelper().getDeviceFingerprint(),
    });
  }
}
```

**التكامل:** يُستدعى عند كل عملية حذف، تعديل رواتب، تغيير صلاحيات، تسجيل دخول.

### 14.3 النسخ الاحتياطي
**ملف جديد:** `lib/services/backup_service.dart`

```dart
class BackupService {
  /// نسخ قاعدة البيانات إلى مجلد Documents/Hisabati_Backups/
  static Future<String?> createBackup() async {
    final dbPath = await DatabaseHelper().getDatabasePath();
    final backupDir = await _getBackupDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final backupPath = '${backupDir.path}/hisabati_backup_$timestamp.db';
    
    await File(dbPath).copy(backupPath);
    
    // الاحتفاظ بآخر 7 نسخ فقط
    await _cleanOldBackups(backupDir);
    
    return backupPath;
  }

  /// استعادة من نسخة احتياطية
  static Future<void> restoreBackup(String backupPath) async {
    final dbPath = await DatabaseHelper().getDatabasePath();
    await File(backupPath).copy(dbPath);
    // إعادة تهيئة DB
  }

  static Future<List<FileSystemEntity>> listBackups() async {
    final backupDir = await _getBackupDirectory();
    return backupDir.listSync().where((f) => f.path.endsWith('.db')).toList();
  }
}
```

### 14.4 إضافة `.env` إلى `.gitignore`
**ملف:** `.gitignore`

إضافة السطر التالي:
```
.env
```

### 14.5 إنشاء `.env.example`
**ملف جديد:** `.env.example`

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Google AI (Gemini)
GOOGLE_API_KEY=your-google-api-key-here

# SMTP (Email)
SMTP_EMAIL=your-email@domain.com
SMTP_PASSWORD=your-app-password-here
```

### 14.6 إصلاح مولد كلمة المرور
**ملف:** `lib/services/supabase_admin_service.dart`

البحث عن `_generateSecurePassword` واستبدال:
```dart
// قبل (معيب):
final random = [for (var i = 0; i < 10; i++) chars[(DateTime.now().microsecondsSinceEpoch % chars.length).toInt()]].join();

// بعد (آمن):
import 'dart:math';
final rng = Random.secure();
final random = List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
```

### 14.7 SQL Indexes للأداء
**ملف:** `lib/services/database_helper.dart`

في `_onUpgrade` عند version 55:
```dart
if (oldVersion < 55) {
  await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(issue_date)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_client ON invoices(client_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_logs(date)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_items_sku ON items(sku)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_tx_item ON inventory_transactions(item_id)');
}
```

## معايير القبول
- [ ] مستخدم `employee` لا يرى شاشة المحاسبة
- [ ] مستخدم `viewer` لا يستطيع إضافة أي شيء
- [ ] حذف سجل → يظهر في `security_audit`
- [ ] إنشاء نسخة احتياطية → ملف `.db` في مجلد `Documents`
- [ ] استعادة نسخة → البيانات ترجع
- [ ] `.env` ليست في git
- [ ] كلمات المرور المولدة عشوائية فعلاً
