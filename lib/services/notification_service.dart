import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

// الأنواع الموجودة + إضافات
enum NotificationType { info, warning, security, success, update, task, payment, inventory, system }

enum NotificationPriority { low, normal, high, critical }

class AppAlert {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? moduleId;       // ربط بالمديول المصدر
  final String? actionRoute;    // رقم الصفحة للتنقل عند الضغط
  final bool isRead;
  final Map<String, dynamic>? metadata;

  AppAlert({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.priority = NotificationPriority.normal,
    DateTime? timestamp,
    this.moduleId,
    this.actionRoute,
    this.isRead = false,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  AppAlert copyWith({bool? isRead}) => AppAlert(
    id: id, title: title, message: message, type: type,
    priority: priority, timestamp: timestamp, moduleId: moduleId,
    actionRoute: actionRoute, isRead: isRead ?? this.isRead,
    metadata: metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'message': message,
    'type': type.index, 'priority': priority.index,
    'timestamp': timestamp.toIso8601String(),
    'moduleId': moduleId, 'actionRoute': actionRoute,
    'isRead': isRead, 'metadata': metadata,
  };

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
    id: json['id'], title: json['title'], message: json['message'],
    type: NotificationType.values[json['type'] ?? 0],
    priority: NotificationPriority.values[json['priority'] ?? 1],
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    moduleId: json['moduleId'], actionRoute: json['actionRoute'],
    isRead: json['isRead'] ?? false,
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
  );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final List<AppAlert> _notifications = [];
  final ValueNotifier<AppAlert?> _latestAlert = ValueNotifier(null);

  List<AppAlert> get notifications => List.unmodifiable(_notifications);
  List<AppAlert> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  ValueNotifier<AppAlert?> get latestAlert => _latestAlert;

  // تصفية حسب النوع
  List<AppAlert> getByType(NotificationType type) =>
    _notifications.where((n) => n.type == type).toList();

  // تصفية حسب المديول
  List<AppAlert> getByModule(String moduleId) =>
    _notifications.where((n) => n.moduleId == moduleId).toList();

  // إضافة إشعار جديد
  void addNotification(AppAlert alert) {
    _notifications.insert(0, alert);
    _latestAlert.value = alert;
    _saveToStorage();
    notifyListeners();

    // إزالة تلقائية بعد 10 ثواني للـ snackbar
    Future.delayed(const Duration(seconds: 10), () {
      if (_latestAlert.value?.id == alert.id) {
        _latestAlert.value = null;
      }
    });
  }

  // إشعار سريع (shortcut)
  void pushAlert(String title, String message, {
    NotificationType type = NotificationType.info,
    String? moduleId,
    String? actionRoute,
  }) {
    addNotification(AppAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, message: message, type: type,
      moduleId: moduleId, actionRoute: actionRoute,
    ));
  }

  // تعليم كمقروء
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _saveToStorage();
      notifyListeners();
    }
  }

  // تعليم الكل كمقروء
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _saveToStorage();
    notifyListeners();
  }

  // مسح إشعار
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // مسح الكل
  void clearAll() {
    _notifications.clear();
    _latestAlert.value = null;
    _saveToStorage();
    notifyListeners();
  }

  void clearAlert() {
    _latestAlert.value = null;
  }

  // --- BACKWARD COMPATIBILITY WRAPPERS ---

  /// التنبيه التقليدي (Legacy Support)
  void notify({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) {
    pushAlert(title, message, type: type);
  }

  /// التنبيه عن عمليات حساسة (Legacy Support)
  void notifySensitiveAction(String action, String details) {
    pushAlert(
      "⚠️ تنبيه أمني: $action",
      details,
      type: NotificationType.security,
    );
  }

  // حفظ في SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications_v2', jsonEncode(json));
  }

  // تحميل من SharedPreferences
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications_v2');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _notifications.clear();
        _notifications.addAll(list.map((e) => AppAlert.fromJson(e)));
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading notifications: $e");
      }
    }
  }

  /// Checks for system events and creates notifications automatically
  /// IMPORTANT: Column names MUST match actual SQLite schema:
  /// - invoices: status (NOT payment_status)
  /// - items: min_stock_level (NOT min_quantity)
  /// - real_estate_contracts: annual_rent (NOT rent_amount)
  Future<void> checkSystemAlerts() async {
    try {
      final db = await DatabaseHelper().database;

      // 1. Overdue Invoices — invoices.status column
      try {
        final overdueInvoices = await db.rawQuery(
          "SELECT COUNT(*) as c FROM invoices WHERE status != 'paid' AND due_date < ? AND is_deleted = 0",
          [DateTime.now().toIso8601String().split('T')[0]]
        );
        final overdueCount = overdueInvoices.first['c'] as int? ?? 0;
        if (overdueCount > 0) {
          pushAlert('فواتير متأخرة', 'يوجد $overdueCount فاتورة متأخرة السداد تحتاج للمتابعة', type: NotificationType.warning);
        }
      } catch (e) {
        debugPrint("Alert check (invoices): $e");
      }

      // 2. Low Stock — items.min_stock_level column
      try {
        final lowStock = await db.rawQuery(
          'SELECT COUNT(*) as c FROM items WHERE quantity <= min_stock_level AND min_stock_level > 0 AND is_deleted = 0'
        );
        final lowCount = lowStock.first['c'] as int? ?? 0;
        if (lowCount > 0) {
          pushAlert('مخزون منخفض', '$lowCount صنف وصل للحد الأدنى للمخزون', type: NotificationType.inventory);
        }
      } catch (e) {
        debugPrint("Alert check (items): $e");
      }

      // 3. Due Cheques
      try {
        final dueChecks = await db.rawQuery(
          "SELECT COUNT(*) as c FROM cheques WHERE due_date = ? AND status = 'pending' AND is_deleted = 0",
          [DateTime.now().toIso8601String().split('T')[0]]
        );
        final checkCount = dueChecks.first['c'] as int? ?? 0;
        if (checkCount > 0) {
          pushAlert('شيكات مستحقة اليوم', '$checkCount شيك يستحق الصرف اليوم', type: NotificationType.payment);
        }
      } catch (e) {
        debugPrint("Alert check (cheques): $e");
      }

      // 4. Expiring Real Estate Contracts — annual_rent column
      try {
        final expiringContracts = await db.rawQuery(
          "SELECT COUNT(*) as c FROM real_estate_contracts WHERE end_date BETWEEN ? AND ? AND is_deleted = 0",
          [
            DateTime.now().toIso8601String().split('T')[0],
            DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
          ]
        );
        final contractCount = expiringContracts.first['c'] as int? ?? 0;
        if (contractCount > 0) {
          pushAlert('عقود تنتهي قريباً', '$contractCount عقد ينتهي خلال 30 يوم', type: NotificationType.warning);
        }
      } catch (_) {} // Might fail if table not exists yet

    } catch (e) {
      debugPrint("Error checking system alerts: $e");
    }
  }
}
