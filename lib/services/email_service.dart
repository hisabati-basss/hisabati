import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Last error message for UI display
  String? lastError;

  /// Retrieves the current SMTP configuration
  Future<Map<String, String>> getSmtpConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String pass = prefs.getString('smtp_password') ?? dotenv.env['SMTP_PASSWORD'] ?? '';
    // Clean spaces from password (common for Google App Passwords copy-paste)
    pass = pass.replaceAll(' ', '');
    
    return {
      'host': prefs.getString('smtp_host') ?? dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com',
      'port': prefs.getString('smtp_port') ?? dotenv.env['SMTP_PORT'] ?? '465',
      'email': prefs.getString('smtp_email') ?? dotenv.env['SMTP_EMAIL'] ?? '',
      'password': pass,
      'sender_name': prefs.getString('smtp_sender_name') ?? 'حساباتي Hisabati',
    };
  }

  /// Saves new SMTP configuration
  Future<void> saveSmtpConfig(String host, String port, String email, String password, {String? senderName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smtp_host', host);
    await prefs.setString('smtp_port', port);
    await prefs.setString('smtp_email', email);
    await prefs.setString('smtp_password', password);
    if (senderName != null) await prefs.setString('smtp_sender_name', senderName);
  }

  /// Clears custom SMTP configuration to restore defaults
  Future<void> resetSmtpConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('smtp_host');
    await prefs.remove('smtp_port');
    await prefs.remove('smtp_email');
    await prefs.remove('smtp_password');
    await prefs.remove('smtp_sender_name');
  }

  /// Validate SMTP credentials are configured
  Future<bool> isSmtpConfigured() async {
    final config = await getSmtpConfig();
    return config['email']!.isNotEmpty && 
           config['password']!.isNotEmpty && 
           config['password'] != 'your_app_password_here' &&
           config['email']!.contains('@');
  }

  /// Test SMTP connection without sending
  Future<Map<String, dynamic>> testSmtpConnection({
    String? host,
    String? port,
    String? email,
    String? password,
  }) async {
    final sHost = host ?? (await getSmtpConfig())['host']!;
    final sPort = int.tryParse(port ?? (await getSmtpConfig())['port']!) ?? 465;
    final sEmail = email ?? (await getSmtpConfig())['email']!;
    final sPass = password ?? (await getSmtpConfig())['password']!;

    if (sEmail.isEmpty || sPass.isEmpty) {
      return {'success': false, 'error': 'البريد أو كلمة المرور مفقودة'};
    }
    
    try {
      SmtpServer smtpServer;
      final isGmail = sHost.toLowerCase().contains('gmail');
      
      if (isGmail && (sPort == 465 || sPort == 587)) {
        // Gmail helper handles authentication and port defaults efficiently
        smtpServer = gmail(sEmail, sPass);
      } else {
        smtpServer = SmtpServer(sHost, port: sPort, username: sEmail, password: sPass, ssl: sPort == 465);
      }

      final message = Message()
        ..from = Address(sEmail, 'حساباتي Hisabati')
        ..recipients.add(sEmail)
        ..subject = 'Hisabati ERP - SMTP Test'
        ..text = 'تهانينا! المزامنة تعمل بنجاح.';
      
      await send(message, smtpServer);
      return {'success': true, 'error': null};
    } on MailerException catch (e) {
      String errorDetails = e.problems.map((p) => '${p.code}: ${p.msg}').join('\n');
      if (errorDetails.isEmpty) errorDetails = e.message ?? 'Unknown SMTP error';
      
      if (errorDetails.contains('535')) {
        return {
          'success': false, 
          'error': 'فشل التحقق (535):\nيجب أن يكون "البريد الإلكتروني" هو نفسه البريد الذي استخرجت له "كلمة مرور التطبيق" من جوجل.'
        };
      }
      return {'success': false, 'error': 'خطأ SMTP:\n$errorDetails'};
    } catch (e) {
      return {'success': false, 'error': 'خطأ اتصال: $e'};
    }
  }

  /// إرسال إيميل احترافي (HTML) مع إعادة المحاولة
  Future<bool> sendWelcomeEmail({
    required String targetEmail,
    required String employeeName,
    required String companyName,
    required String virtualEmail,
    required String password,
    int maxRetries = 3,
  }) async {
    lastError = null;
    
    if (!await isSmtpConfigured()) {
      lastError = 'إعدادات البريد غير مهيأة - توجه للإعدادات لضبط SMTP';
      debugPrint('❌ $lastError');
      return false;
    }
    
    if (!targetEmail.contains('@') || !targetEmail.contains('.')) {
      lastError = 'البريد الإلكتروني "$targetEmail" غير صالح';
      debugPrint('❌ $lastError');
      return false;
    }

    final config = await getSmtpConfig();
    final sHost = config['host']!;
    final sPort = int.tryParse(config['port']!) ?? 465;
    final sEmail = config['email']!;
    final sPass = config['password']!;

    SmtpServer smtpServer;
    if (sHost.contains('gmail')) {
      smtpServer = gmail(sEmail, sPass);
    } else {
      smtpServer = SmtpServer(sHost, port: sPort, username: sEmail, password: sPass, ssl: sPort == 465);
    }

    String htmlContent = _buildHtmlTemplate(employeeName, companyName, virtualEmail, password);

    // Load logo attachment
    File? logoFile;
    try {
      final tempDir = await getTemporaryDirectory();
      logoFile = File('${tempDir.path}/HBASSS.png');
      if (!await logoFile.exists()) {
        final byteData = await rootBundle.load('assets/image/HBASSS.png');
        await logoFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
    } catch (e) {
      debugPrint('⚠️ Logo asset not found (email will send without logo): $e');
      logoFile = null;
    }

    final message = Message()
      ..from = Address(sEmail, config['sender_name'] ?? companyName)
      ..recipients.add(targetEmail)
      ..subject = 'مرحباً بك في $companyName - تفاصيل حسابك الوظيفي'
      ..html = htmlContent;

    if (logoFile != null && await logoFile.exists()) {
      final attachment = FileAttachment(logoFile)
        ..location = Location.inline
        ..cid = '<hbasss_logo>';
      message.attachments.add(attachment);
    }

    // Retry mechanism
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('📧 Attempt $attempt/$maxRetries: Sending email to $targetEmail...');
        final sendReport = await send(message, smtpServer);
        debugPrint('✅ Email sent successfully: $sendReport');
        lastError = null;
        return true;
      } on MailerException catch (e) {
        lastError = 'خطأ في إرسال البريد: ${e.problems.map((p) => p.msg).join(', ')}';
        debugPrint('❌ Attempt $attempt failed - $lastError');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        lastError = 'خطأ غير متوقع أثناء إرسال البريد: $e';
        debugPrint('❌ Attempt $attempt failed - $lastError');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    
    debugPrint('❌ All $maxRetries attempts failed for $targetEmail');
    return false;
  }

  String _buildHtmlTemplate(String empName, String companyName, String email, String password) {
    return '''
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f8; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.05); overflow: hidden; }
        .header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); padding: 30px 20px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 24px; font-weight: 600; }
        .logo { width: 80px; height: 80px; margin-bottom: 10px; }
        .content { padding: 30px; line-height: 1.6; }
        .content h2 { color: #1e3c72; margin-top: 0; }
        .credentials { background: #f8f9fa; border-left: 4px solid #ff9800; padding: 20px; border-radius: 4px; margin: 20px 0; font-family: monospace; font-size: 16px; }
        .cred-row { margin-bottom: 10px; display: flex; justify-content: space-between; border-bottom: 1px dashed #ddd; padding-bottom: 5px; }
        .cred-label { font-weight: bold; color: #555; }
        .cred-value { color: #2a5298; font-weight: bold; }
        .btn { display: inline-block; padding: 12px 24px; background-color: #ff9800; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; margin-top: 20px; }
        .footer { background: #eeeeee; text-align: center; padding: 15px; font-size: 12px; color: #777; }
        .footer strong { color: #555; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <img src="cid:hbasss_logo" alt="HBASSS" class="logo">
          <h1>أهلاً بك في $companyName</h1>
        </div>
        <div class="content">
          <h2>مرحباً $empName،</h2>
          <p>يسعدنا انضمامك إلى فريق عملنا الرائع. تم إنشاء حساب وظيفي خاص بك لتتمكن من الوصول إلى المنصة الداخلية (Hisabati ERP) والتواصل عبر الشات الداخلي.</p>
          
          <p>إليك تفاصيل الدخول الخاصة بك:</p>
          
          <div class="credentials">
            <div class="cred-row">
              <span class="cred-label">البريد الوظيفي (Login ID):</span>
              <span class="cred-value">$email</span>
            </div>
            <div class="cred-row">
              <span class="cred-label">كلمة المرور المؤقتة:</span>
              <span class="cred-value">$password</span>
            </div>
          </div>
          
          <p style="color: #d32f2f; font-size: 13px;">⚠️ ملاحظة هامة: لأسباب أمنية، سيُطلب منك تغيير كلمة المرور هذه عند تسجيل دخولك لأول مرة.</p>
          
        </div>
        <div class="footer">
          <p>هذه الرسالة تم توليدها تلقائياً من نظام <strong>حساباتي ERP (Enterprise)</strong></p>
          <p>Powered by <strong>Bassem Sabri</strong> | للتواصل مع المطور: <a href="mailto:bassemsabri@outlook.sa" style="color: #2a5298;">bassemsabri@outlook.sa</a></p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
