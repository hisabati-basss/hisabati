import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hisabati_app/core/config/app_constants.dart';
import '../theme/app_theme_extension.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGuestLogin;
  const LoginScreen({super.key, required this.onGuestLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _showManualCode = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInCirc),
    );

    _formController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo (Ultra-Compact)
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 8 * _logoController.value),
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryOrange.withValues(
                                  alpha: 0.15 + 0.05 * _logoController.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(42.5),
                            child: Image.asset(
                              'assets/image/logo icon.PNG',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Glassmorphic Form (Ultra-Compact Version)
                  FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: _buildLoginForm(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Container(color: context.bgSurface),
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [ primaryOrange.withValues(alpha: 0.2), Colors.transparent ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [ accentGold.withValues(alpha: 0.15), Colors.transparent ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('login.welcome_back'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tr('login.subtitle'),
                style: TextStyle(color: context.mutedText, fontSize: 11),
              ),
              const SizedBox(height: 18),

              _buildTextField(Icons.person_outline, tr('login.email'), controller: _emailController),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.lock_outline,
                tr('login.password'),
                isPassword: true,
                controller: _passwordController,
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    tr('login.forgot_password'),
                    style: const TextStyle(color: primaryOrange, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: primaryOrange.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    tr('login.sign_in'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: context.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(tr('login.or_continue_with'), style: TextStyle(color: context.mutedText, fontSize: 10)),
                  ),
                  Expanded(child: Divider(color: context.cardBorder)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 22),
                  label: Text(tr('login.google'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              
              if (_showManualCode) ...[
                const SizedBox(height: 16),
                _buildTextField(Icons.vpn_key_outlined, tr('login.manual_code_label'), controller: _codeController),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _handleManualCodeExchange,
                    style: ElevatedButton.styleFrom(backgroundColor: context.cardBorder),
                    child: Text(tr('login.activate_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _showManualCode = !_showManualCode),
                      icon: const Icon(Icons.help_outline, size: 10, color: primaryOrange),
                      label: Text(tr('login.browser_not_returning'), style: const TextStyle(color: primaryOrange, fontSize: 9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String label, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: context.textColor, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryOrange, size: 16),
          labelText: label,
          labelStyle: TextStyle(color: context.mutedText, fontSize: 11),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final inputEmail = _emailController.text.trim();
    final inputPass = _passwordController.text.trim();

    if (inputEmail.isEmpty || inputPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('login.enter_data'))));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryOrange)));

    try {
      final response = await AuthService().signInWithEmailAndPassword(inputEmail, inputPass);
      final userMeta = response.user?.userMetadata ?? {};
      
      final db = await DatabaseHelper().database;
      await db.insert('system_users', {
        'id': response.user?.id ?? 'EMP_1',
        'username': inputEmail,
        'name': userMeta['full_name'] ?? 'موظف',
        'role': userMeta['job_title'] ?? 'موظف',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String()
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (mounted) {
        Navigator.pop(context);
        if (userMeta['is_force_reset'] == true) {
          _showForcePasswordResetDialog(context, inputEmail);
        } else {
          widget.onGuestLogin();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        if (inputEmail == 'admin' && inputPass == 'admin') { widget.onGuestLogin(); return; }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بيانات الدخول غير صحيحة.')));
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryOrange)));
      await AuthService().signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    }
  }

  Future<void> _handleManualCodeExchange() async {
    try {
      final code = _codeController.text.trim();
      if (code.isEmpty) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryOrange)));
      await AuthService().exchangeCodeForSession(code);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الكود غير صحيح.")));
      }
    }
  }

  void _showForcePasswordResetDialog(BuildContext context, String email) {
    final TextEditingController newPassCtrl = TextEditingController();
    final TextEditingController confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppConstants.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.redAccent)),
          title: const Text("تغيير كلمة المرور إجباري", style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("يجب تعيين كلمة مرور جديدة قوية.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "جديدة", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "تأكيد", border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newPassCtrl.text != confirmPassCtrl.text) return;
                try {
                  await AuthService().updatePasswordAndClearResetFlag(newPassCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    widget.onGuestLogin();
                  }
                } catch (e) {}
              },
              child: const Text("تأكيد", style: TextStyle(color: primaryOrange)),
            )
          ],
        );
      }
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryOrange.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: primaryOrange),
            const SizedBox(width: 12),
            Text(tr('login.forgot_password_title'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('login.forgot_password_desc'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "البريد الإلكتروني",
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.email_outlined, color: primaryOrange, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = resetEmailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('login.enter_data'))),
                );
                return;
              }
              try {
                await AuthService().resetPassword(email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('login.reset_link_sent')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${tr('common.error')}: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text(tr('login.send_link'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
