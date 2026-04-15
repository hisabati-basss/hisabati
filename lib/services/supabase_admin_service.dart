import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'email_service.dart';

class SupabaseAdminService {
  SupabaseClient? _adminClient;

  static final SupabaseAdminService _instance = SupabaseAdminService._internal();
  factory SupabaseAdminService() => _instance;

  SupabaseAdminService._internal() {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

    if (url.isNotEmpty && serviceRoleKey.isNotEmpty) {
      _adminClient = SupabaseClient(url, serviceRoleKey);
    } else {
      debugPrint("Warning: SUPABASE_SERVICE_ROLE_KEY missing, Admin APIs won't work.");
    }
  }

  /// Generates a cryptographically secure random password
  String _generateSecurePassword() {
    final rng = Random.secure();
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const special = '!@#\&*';
    const all = '$lower$upper$digits$special';
    
    // Ensure at least one of each type
    final pwd = StringBuffer()
      ..write(lower[rng.nextInt(lower.length)])
      ..write(upper[rng.nextInt(upper.length)])
      ..write(digits[rng.nextInt(digits.length)])
      ..write(special[rng.nextInt(special.length)]);
    
    // Fill remaining 8 characters randomly
    for (var i = 0; i < 8; i++) {
      pwd.write(all[rng.nextInt(all.length)]);
    }
    
    // Shuffle the result
    final chars = pwd.toString().split('');
    chars.shuffle(rng);
    return 'Hsb${chars.join()}';
  }

  /// Transliterate Arabic characters to Latin equivalents for email generation
  String _arabicToLatin(String text) {
    const Map<String, String> map = {
      'ا': 'a', 'أ': 'a', 'إ': 'e', 'آ': 'a', 'ب': 'b', 'ت': 't', 'ث': 'th',
      'ج': 'j', 'ح': 'h', 'خ': 'kh', 'د': 'd', 'ذ': 'th', 'ر': 'r', 'ز': 'z',
      'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': 'a',
      'غ': 'gh', 'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n',
      'ه': 'h', 'و': 'w', 'ي': 'y', 'ى': 'a', 'ة': 'h', 'ء': 'a',
      'ئ': 'e', 'ؤ': 'o', 'ّ': '', 'َ': '', 'ُ': '', 'ِ': '', 'ً': '', 'ٌ': '', 'ٍ': '',
    };
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }

  /// Removes spaces and special chars, makes it lowercase, and prefixes first name
  /// Now handles Arabic names by transliterating to Latin equivalents
  String _generateVirtualEmail(String fullName) {
    if (fullName.isEmpty) return 'emp_${DateTime.now().millisecondsSinceEpoch}@hisabati.local';
    
    // Transliterate Arabic to Latin for email generation
    String latinized = _arabicToLatin(fullName.trim());
    
    var parts = latinized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim().split(RegExp(r'\s+'));
    parts.removeWhere((p) => p.isEmpty);
    
    String first = parts.isNotEmpty ? parts[0] : 'emp';
    String last = parts.length > 1 ? parts.last : '${DateTime.now().millisecondsSinceEpoch % 1000}';
    
    return '$first.$last@hisabati.local';
  }

  /// Create a system user tied to HR, send them an email, and return the virtual email + password
  Future<Map<String, String>?> provisionEmployeeAccess({
    required String fullName,
    required String jobTitle,
    required String personalEmail,
    required String companyName,
  }) async {
    if (_adminClient == null) {
      debugPrint("Admin client not initialized. Cannot provision employee.");
      return null;
    }

    try {
      final virtualEmail = _generateVirtualEmail(fullName);
      final generatedPassword = _generateSecurePassword();

      debugPrint('🔑 Provisioning: $fullName → $virtualEmail');

      // 1. Create Auth User in Supabase
      final authResponse = await _adminClient!.auth.admin.createUser(
        AdminUserAttributes(
          email: virtualEmail,
          password: generatedPassword,
          emailConfirm: true,
          userMetadata: {
            'full_name': fullName,
            'job_title': jobTitle,
            'role': 'employee',
            'is_force_reset': true,
          }
        )
      );

      final user = authResponse.user;
      if (user != null) {
        debugPrint('✅ Supabase user created: ${user.id}');

        // 2. Add to public.system_users table
        try {
          await _adminClient!.from('system_users').insert({
            'id': user.id,
            'name': fullName,
            'email': virtualEmail,
            'password': generatedPassword,
            'role': 'employee',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('⚠️ system_users insert failed (table may not exist): $e');
          // Don't block — the auth user is still created
        }

        // 3. Send the Welcome Email 
        if (personalEmail.isNotEmpty && personalEmail.contains('@')) {
          debugPrint('📧 Sending welcome email to: $personalEmail');
          final sent = await EmailService().sendWelcomeEmail(
            targetEmail: personalEmail,
            employeeName: fullName,
            companyName: companyName,
            virtualEmail: virtualEmail,
            password: generatedPassword,
          );
          debugPrint(sent ? '✅ Email sent successfully!' : '❌ Email sending failed.');
        } else {
          debugPrint('⚠️ No valid personal email provided, skipping welcome email.');
        }

        return {
          'virtual_email': virtualEmail,
          'password': generatedPassword,
          'uid': user.id
        };
      }
      debugPrint('❌ Supabase createUser returned null user.');
      return null;
    } catch (e) {
      debugPrint("❌ Error provisioning auth user: $e");
      return null;
    }
  }
}
