import 'package:flutter/material.dart';

enum NotificationType { info, warning, security, success }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// تريجر لإظهار تنبيه فوري في الواجهة
  final ValueNotifier<AppNotification?> latestAlert = ValueNotifier(null);

  void notify({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    if (_notifications.length > 50) _notifications.removeLast();

    // تفعيل التنبيه اللحظي في الواجهة
    latestAlert.value = notification;
    
    notifyListeners();
    debugPrint("🔔 Notification: [${type.name}] $title - $message");
  }

  /// التنبيه عن عمليات حساسة (اللمسة الهندسية للمدير)
  void notifySensitiveAction(String action, String details) {
    notify(
      title: "⚠️ تنبيه أمني: $action",
      message: details,
      type: NotificationType.security,
    );
  }

  void clearAlert() {
    latestAlert.value = null;
  }
}
