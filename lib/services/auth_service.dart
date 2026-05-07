import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseOAuthArgs extends ProviderArgs {
  final String supabaseHost;
  final String supabasePath;
  final Map<String, String> queryParams;
  @override
  final String redirectUri;

  String? lastCapturedUrl;

  SupabaseOAuthArgs({
    required this.supabaseHost,
    required this.supabasePath,
    required this.queryParams,
    required this.redirectUri,
  });

  @override
  String get host => supabaseHost;

  @override
  String get path => supabasePath;

  @override
  Map<String, String> buildQueryParameters() => queryParams;

  @override
  Future<AuthResult?> authorizeFromCallback(String callbackUrl) async {
    debugPrint('🔄 تم استلام رابط العودة: $callbackUrl');
    lastCapturedUrl = callbackUrl;
    final uri = Uri.parse(callbackUrl);
    
    if (uri.queryParameters.containsKey('error')) {
       final error = uri.queryParameters['error'];
       throw 'خطأ في المصادقة: $error';
    }

    final String source = uri.fragment.isEmpty ? uri.query : uri.fragment;
    final params = Uri.splitQueryString(source);
    
    // إذا وجدنا الكود (PKCE) أو المفتاح (Implicit)
    if (params.containsKey('access_token') || params.containsKey('code')) {
      debugPrint('✅ تم العثور على بيانات تسجيل الدخول!');
      return AuthResult(
        accessToken: params['access_token'] ?? 'pkce_flow',
        idToken: params['id_token'], 
      );
    }
    
    return null;
  }
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Performs Google Sign-In using the best method for each platform.
  Future<void> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

      // 1. Web
      if (kIsWeb) {
        final currentOrigin = Uri.base.origin;
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: currentOrigin,
          queryParams: {'prompt': 'select_account'},
        );
        return;
      }

      // 2. Desktop (Windows / Linux / macOS) 🚀
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        const redirectUrl = 'http://localhost:3000';

        debugPrint('🌐 طلب الرابط الرسمي من Supabase SDK...');
        
        final response = await _supabase.auth.getOAuthSignInUrl(
          provider: OAuthProvider.google,
          redirectTo: redirectUrl,
          queryParams: {'prompt': 'select_account', 'hl': 'ar'},
        );

        // استخراج الكود من الرابط المرتجع
        final oauthUri = Uri.parse(response.url);
        final args = SupabaseOAuthArgs(
          supabaseHost: oauthUri.host,
          supabasePath: oauthUri.path,
          queryParams: oauthUri.queryParameters,
          redirectUri: redirectUrl,
        );

        final result = await DesktopWebviewAuth.signIn(args, width: 600, height: 800);

        if (result == null) {
          throw 'تم إلغاء تسجيل الدخول.';
        }

        // 🚀 الخطوة المفقودة: تبديل الكود بجلسة دخول حقيقية
        final callbackUri = Uri.parse(args.lastCapturedUrl ?? '');
        final queryParams = callbackUri.queryParameters;
        final fragmentParams = Uri.splitQueryString(callbackUri.fragment);
        
        final code = queryParams['code'] ?? fragmentParams['code'];
        final accessToken = queryParams['access_token'] ?? fragmentParams['access_token'];

        if (code != null) {
          debugPrint('🚀 جارٍ استبدال الكود بجلسة دخول...');
          await _supabase.auth.exchangeCodeForSession(code);
        } else if (accessToken != null) {
          debugPrint('🚀 جارٍ تهيئة الجلسة عبر المفتاح...');
          await _supabase.auth.setSession(accessToken);
        }

        debugPrint('🎉 تم تسجيل الدخول بنجاح تام! سيتم فتح البرنامج الآن.');
        return;
      }

      // 3. Mobile (Android/iOS)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'تم إلغاء عملية تسجيل الدخول.';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'فشل الحصول على رمز الهوية (ID Token).';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('خطأ في المصادقة: $e');
      rethrow;
    }
  }

  /// Performs Email & Password Sign-In for Employees (Virtual Accounts)
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password, {String? tenantId}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Email Auth Error: $e');
      rethrow;
    }
  }

  /// Updates the user's password and removes the force_reset flag
  Future<void> updatePasswordAndClearResetFlag(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
          data: {'is_force_reset': false},
        ),
      );
    } catch (e) {
      debugPrint('Update Password Error: $e');
      rethrow;
    }
  }

  /// Signs the user out of both Supabase and Google.
  Future<void> signOut() async {
    // Only call GoogleSignIn().signOut() on platforms where it's supported/used
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try { await GoogleSignIn().signOut(); } catch (_) {}
    }
    
    // Clear local session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('user_id');
    await prefs.remove('company_id');
    await prefs.remove('user_role');
    
    await _supabase.auth.signOut();
  }

  /// Gets the current authenticated user.
  User? get currentUser => _supabase.auth.currentUser;

  /// Exchanges a code from an OAuth flow for a Supabase session manually.
  Future<void> exchangeCodeForSession(String code) async {
    try {
      await _supabase.auth.exchangeCodeForSession(code);
    } catch (e) {
      debugPrint('Manual Code Exchange Error: $e');
      rethrow;
    }
  }

  /// Stream of Auth State changes.
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Sends a password reset email to the user
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }
}
