# المرحلة 1: إصلاح الأخطاء الحرجة

## الأولوية: 🔴 حرجة - يجب تنفيذها أولاً

## المهام

### 1.1 إصلاح إرسال البريد (email_service.dart)
**الملف:** `lib/services/email_service.dart`
- [ ] استبدال مولد كلمة المرور بـ `Random.secure()` من `dart:math`
- [ ] إضافة try-catch يرجع رسالة خطأ واضحة للمستخدم
- [ ] إضافة log مفصل لكل خطوة من عملية الإرسال
- [ ] اختبار SMTP credentials قبل محاولة الإرسال

### 1.2 إصلاح مولد كلمة المرور (supabase_admin_service.dart)
**الملف:** `lib/services/supabase_admin_service.dart`
- [ ] استبدال الكود في `_generateSecurePassword()`:
```dart
// قبل (معطل - ينتج نفس الحرف):
final random = [for (var i = 0; i < 10; i++) chars[(DateTime.now().microsecondsSinceEpoch % chars.length).toInt()]].join();

// بعد (عشوائي حقيقي):
final rng = Random.secure();
final random = List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
```
- [ ] تغيير البريد الوظيفي حسب نطاق الشركة أو `@hisabati.app`

### 1.3 إصلاح الذكاء الاصطناعي (ai_chat_controller.dart)
**الملف:** `lib/services/ai_chat_controller.dart`
- [ ] نقل مفتاح ElevenLabs من السطر 346 إلى `.env`:
```
ELEVENLABS_API_KEY=sk_08b95b78...
ELEVENLABS_VOICE_ID=EXAVITQu4vr4xnSDxMaL
```
- [ ] إضافة في `.env` ثم قراءته: `dotenv.env['ELEVENLABS_API_KEY']`
- [ ] إضافة fallback لـ `flutter_tts` عند فشل ElevenLabs
- [ ] إضافة Platform check قبل استخدام `AudioRecorder`
- [ ] إضافة وضع أوفلاين مع رسائل محلية ذكية

### 1.4 إصلاح خدمة AI (ai_service.dart)
**الملف:** `lib/services/ai_service.dart`
- [ ] إضافة fallback model: gemini-2.0-flash → gemini-1.5-flash-latest
- [ ] إضافة timeout (30 ثانية) للطلبات
- [ ] معالجة أخطاء API rate limit
- [ ] ربط System Prompt ببيانات حقيقية من DB

### 1.5 إصلاح شاشة الدخول (login_screen.dart) 
**الملف:** `lib/screens/login_screen.dart`
- [ ] استبدال Google Logo من URL بصورة محلية في `assets/image/`
- [ ] تفعيل زر "نسيت كلمة المرور" → إرسال بريد إعادة تعيين
- [ ] ضمان عمل admin/admin دائماً حتى بدون Supabase

### 1.6 إصلاح قاعدة البيانات (database_helper.dart)
**الملف:** `lib/services/database_helper.dart`
- [ ] إضافة migrations v48, v49 (حالياً فارغة)
- [ ] إنشاء جدول `system_users` في `_onCreate`
- [ ] إنشاء جدول `tasks` المفقود
- [ ] توحيد `sync_status` كـ INTEGER في كل مكان
- [ ] دمج/توحيد `asset_custody_log` و `asset_custody_logs`

### 1.7 إصلاح الشاشة الرئيسية (main.dart)
**الملف:** `lib/main.dart`
- [ ] إزالة `SystemChrome.setEnabledSystemUIMode` على Desktop
- [ ] إزالة أو تفعيل FAB المعطل
- [ ] إضافة Platform check لـ mobile-only APIs

### 1.8 تفعيل الأزرار المعطلة
- [ ] `login_screen.dart` سطر 207: تفعيل "نسيت كلمة المرور"
- [ ] `settings_screen.dart` سطر 227: تفعيل "تغيير كلمة المرور"
- [ ] `hr_screen.dart`: تفعيل تاب المستندات والعهد

## معايير القبول
- `flutter analyze` بدون أخطاء
- `flutter build windows` ناجح
- تسجيل موظف جديد → وصول إيميل حقيقي
- AI يرد بدون crash على Desktop
- كل الأزرار المذكورة تعمل
