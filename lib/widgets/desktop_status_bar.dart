import 'dart:async';
import 'package:flutter/material.dart';
import '../core/config/app_constants.dart';
import '../services/database_helper.dart';

class DesktopStatusBar extends StatefulWidget {
  const DesktopStatusBar({Key? key}) : super(key: key);

  @override
  State<DesktopStatusBar> createState() => _DesktopStatusBarState();
}

class _DesktopStatusBarState extends State<DesktopStatusBar> {
  String _companyName = 'جارٍ التحميل...';
  String _currency = '';
  String _taxRate = '';
  bool _isOnline = true; // Placeholder for actual online status
  String _userName = 'المسؤول';
  String _role = 'Admin';
  String _lastSync = 'مند 5 دقائق';

  @override
  void initState() {
    super.initState();
    _loadStatusData();
  }

  Future<void> _loadStatusData() async {
    try {
      final dbHelper = DatabaseHelper();
      final context = await dbHelper.getCurrentCompanyContext();
      
      if (mounted) {
        setState(() {
          _companyName = context['name'] ?? 'شركة غير محددة';
          _currency = context['currency'] ?? 'ريال';
          _taxRate = context['tax_rate'] != null ? '${context['tax_rate']}%' : '15%';
          
          // In real app, we fetch from AuthService and SyncService
          _userName = "مدير النظام"; // context['user_name'] ?? 
          _role = "Admin";
        });
      }
    } catch (e) {
      debugPrint("Status Bar Load Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF131317),
        border: Border(top: BorderSide(color: AppConstants.primaryOrange.withValues(alpha: 0.2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side (Arabic RTL) - App & User Info
          Row(
            children: [
              const Icon(Icons.domain, size: 14, color: AppConstants.primaryOrange),
              const SizedBox(width: 6),
              Text(
                "$_companyName | $_currency",
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 14, color: Colors.white24),
              const SizedBox(width: 16),
              const Icon(Icons.person_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                "$_userName ($_role)",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          
          // Left side - System Status
          Row(
            children: [
              const Text(
                "الضريبة:",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(width: 4),
              Text(
                _taxRate,
                style: const TextStyle(color: AppConstants.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 14, color: Colors.white24),
              const SizedBox(width: 16),
              Icon(
                _isOnline ? Icons.cloud_done_outlined : Icons.cloud_off, 
                size: 14, 
                color: _isOnline ? Colors.green : Colors.redAccent
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? "متصل ($_lastSync)" : "وضع الأوفلاين",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 14, color: Colors.white24),
              const SizedBox(width: 16),
              const Text(
                "حساباتي v1.2",
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
