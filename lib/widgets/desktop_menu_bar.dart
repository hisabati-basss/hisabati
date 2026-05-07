import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_constants.dart';

class DesktopMenuBar extends StatelessWidget {
  final Widget child;

  const DesktopMenuBar({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return child; // Return just the child on Mobile/Web
    }

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'ملف',
          menus: [
            PlatformMenuItem(
              label: 'فاتورة جديدة',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
              onSelected: () {
                debugPrint('Trigger: New Invoice');
                // TODO: route to Create Invoice
              },
            ),
            PlatformMenuItem(
              label: 'حفظ / مزامنة',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
              onSelected: () {
                debugPrint('Trigger: Sync Data');
                // TODO: route to Sync logic
              },
            ),
            PlatformMenuItem(
              label: 'تصدير إلي تقرير إكسل',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, control: true),
              onSelected: () {},
            ),
            PlatformMenuItem(
              label: 'إغلاق البرنامج',
              shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              onSelected: () => exit(0),
            ),
          ],
        ),
        PlatformMenu(
          label: 'عرض',
          menus: [
            PlatformMenuItem(
              label: 'تحديث البيانات (Refresh)',
              shortcut: const SingleActivator(LogicalKeyboardKey.f5),
              onSelected: () {
                debugPrint('Trigger: Refresh View');
              },
            ),
          ],
        ),
        PlatformMenu(
          label: 'الكيانات',
          menus: [
            PlatformMenuItem(
              label: 'عميل جديد',
              onSelected: () {},
            ),
            PlatformMenuItem(
              label: 'مورد جديد',
              onSelected: () {},
            ),
            PlatformMenuItem(
              label: 'مادة/صنف جديد',
              onSelected: () {},
            ),
          ],
        ),
        PlatformMenu(
          label: 'إعدادات النظام',
          menus: [
            PlatformMenuItem(
              label: 'التفضيلات',
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, control: true),
              onSelected: () {
                debugPrint('Trigger: Settings');
              },
            ),
          ],
        ),
        PlatformMenu(
          label: 'مساعدة',
          menus: [
            PlatformMenuItem(
              label: 'الذكاء المالي (المساعد الذكي)',
              shortcut: const SingleActivator(LogicalKeyboardKey.space, control: true, shift: true),
              onSelected: () {},
            ),
            PlatformMenuItem(
              label: 'حول حساباتي ERP',
              onSelected: () {},
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
