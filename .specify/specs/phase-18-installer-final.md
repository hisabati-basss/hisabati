# المرحلة 18: التثبيت والتوزيع النهائي (Windows MSIX + About)

## الأولوية: 🟢 الأخيرة (بعد إكمال كل الوظائف)

## المهام

### 18.1 Windows MSIX Installer
**ملف:** `pubspec.yaml`

إضافة في `dev_dependencies`:
```yaml
msix: ^3.16.7
```

إضافة في نهاية `pubspec.yaml`:
```yaml
msix_config:
  display_name: Hisabati ERP
  publisher_display_name: Hisabati
  identity_name: com.hisabati.erp
  msix_version: 1.0.0.0
  logo_path: assets/image/logo icon.PNG
  capabilities: internetClient, removableStorage
  languages: ar, en
```

**لبناء الحزمة:**
```bash
flutter pub run msix:create
```

### 18.2 شاشة "حول التطبيق"
**ملف:** `lib/screens/settings_screen.dart`

إضافة قسم في الإعدادات:
```
حول حساباتي ERP
├── الإصدار: 1.0.0
├── المطور: [اسم الشركة]
├── الرخصة: تجارية
├── الموقع: [URL]
├── الدعم الفني: [email]
└── زر: "تحقق من التحديثات"
```

### 18.3 Splash Screen محسّن
تحسين شاشة البداية:
1. شعار الشركة مع animation خفيف (fade in + scale)
2. شريط تحميل يعرض "جاري تحميل البيانات..."
3. مدة < 3 ثواني
4. لا animations ثقيلة (لا Lottie كبيرة)

### 18.4 قائمة التحقق النهائية
قبل الإطلاق:
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter build windows --release` = success
- [ ] حذف كل `debugPrint` في production
- [ ] كل زر يعمل (لا يوجد onPressed فارغ)
- [ ] Fresh install → كل الجداول تنشأ
- [ ] `.env` ليست في git

## معايير القبول
- [ ] `flutter pub run msix:create` ينتج ملف `.msix` صالح
- [ ] التثبيت على Windows نظيف → يعمل من أول مرة
- [ ] شاشة "حول" تعرض المعلومات بشكل جميل
- [ ] Splash screen أقل من 3 ثواني
