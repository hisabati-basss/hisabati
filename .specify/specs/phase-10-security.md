# المرحلة 10: الأمان والأداء والتثبيت النهائي

## الأولوية: 🟢 متوسطة (لكن ضرورية قبل الإطلاق)

## السياق
التطبيق يحتاج تأمين كامل للبيانات الحساسة، تحسين الأداء على الأجهزة الضعيفة، وإعداد مثبت Desktop احترافي.

## المهام

### 10.1 الأمان

#### أ. حماية المفاتيح
- [ ] نقل كل المفاتيح من الكود إلى `.env`:
  - `ELEVENLABS_API_KEY` (حالياً مكشوف في ai_chat_controller.dart)
  - `ELEVENLABS_VOICE_ID`
  - `GOOGLE_API_KEY`
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `SMTP_EMAIL`
  - `SMTP_PASSWORD`
- [ ] إضافة `.env` إلى `.gitignore` (تأكد أنه مضاف)
- [ ] إنشاء `.env.example` بدون القيم الحقيقية

#### ب. صلاحيات المستخدمين
**ملف جديد:** `lib/services/permission_service.dart`

الأدوار:
```
admin       → كل شيء
manager     → كل شيء ما عدا: حذف الشركة، إدارة المستخدمين
accountant  → محاسبة + تقارير + فواتير (لا HR ولا إعدادات)
hr_manager  → HR + رواتب (لا محاسبة)
employee    → حساباته فقط + طلب إجازة + حضور
viewer      → عرض فقط بدون تعديل
```

- [ ] كل شاشة تتحقق من صلاحية المستخدم الحالي
- [ ] إخفاء/تعطيل العناصر غير المصرح بها
- [ ] إدارة الأدوار في شاشة المستخدمين

#### ج. سجل التدقيق (Audit Trail)
**ملف جديد:** `lib/services/audit_service.dart`
- [ ] تسجيل كل عملية: من؟ ماذا؟ متى؟ القيمة القديمة/الجديدة
- [ ] عرض السجل في شاشة التدقيق الموجودة
- [ ] لا يمكن حذف سجل التدقيق

#### د. تشفير قاعدة البيانات
- [ ] استخدام `sqflite_sqlcipher` بدلاً من `sqflite_common_ffi`
- [ ] أو استخدام تشفير AES على البيانات الحساسة فقط (كلمات مرور، أرقام هوية)
- [ ] مفتاح التشفير يُخزن في Secure Storage

#### هـ. النسخ الاحتياطي
**ملف جديد أو تحسين:** `lib/services/backup_service.dart`
- [ ] نسخ احتياطي يومي تلقائي لقاعدة البيانات
- [ ] حفظ في مجلد محلي + اختيار Google Drive
- [ ] استعادة من نسخة احتياطية
- [ ] الاحتفاظ بآخر 7 نسخ (حذف الأقدم)

### 10.2 الأداء

#### أ. تسريع بداية التطبيق
- [ ] Splash Screen خفيف (بدون animations ثقيلة)
- [ ] تحميل البيانات بعد عرض الواجهة (lazy loading)
- [ ] `DatabaseHelper.initialize()` في background isolate

#### ب. تحسين الذاكرة
- [ ] `ListView.builder` مع `itemExtent` لكل القوائم الطويلة
- [ ] `AutomaticKeepAliveClientMixin` فقط للتابات النشطة
- [ ] حذف controllers في `dispose()` لكل شاشة
- [ ] تقليل حجم الصور المخزنة

#### ج. تحسين قاعدة البيانات
- [ ] إضافة Indexes للأعمدة المستخدمة في WHERE:
```sql
CREATE INDEX idx_invoices_date ON invoices(issue_date);
CREATE INDEX idx_invoices_client ON invoices(client_id);
CREATE INDEX idx_journal_date ON journal_entries(date);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_attendance_date ON attendance_logs(date);
```
- [ ] استخدام `VACUUM` دوري لتنظيف DB
- [ ] Batch operations للعمليات الجماعية

#### د. اختبار على أجهزة ضعيفة
- [ ] اختبار على جهاز بـ 4GB RAM
- [ ] اختبار مع 10,000+ صف في المنتجات
- [ ] اختبار مع 500+ فاتورة
- [ ] قياس وقت تحميل كل شاشة (< 500ms)

### 10.3 التثبيت والتوزيع

#### أ. Windows Installer
- [ ] استخدام `msix` package أو InnoSetup
- [ ] أيقونة التطبيق (من `assets/image/logo.PNG`)
- [ ] اسم التطبيق: "حساباتي ERP" 
- [ ] اختيار مجلد التثبيت
- [ ] إنشاء اختصار على سطح المكتب و Start Menu
- [ ] ربط `.hisabati` extension بالتطبيق (للنسخ الاحتياطية)
- [ ] تحديث تلقائي (Auto-Update) أو يدوي

#### ب. macOS DMG
- [ ] `flutter build macos`
- [ ] تغليف في `.dmg` مع خلفية أنيقة
- [ ] توقيع رقمي (Apple Developer Certificate)
- [ ] Notarization

#### ج. Linux AppImage/DEB
- [ ] `flutter build linux`
- [ ] تغليف في `.AppImage` أو `.deb`
- [ ] إنشاء `.desktop` file

### 10.4 العلامة التجارية

#### شاشة "حول التطبيق"
- [ ] إضافة في الإعدادات: "حول حساباتي"
- [ ] تعرض: الإصدار، المطور، الرخصة
- [ ] رابط الموقع / الدعم
- [ ] زر "تحقق من التحديثات"

#### Splash Screen محسّن
- [ ] شعار الشركة مع animation خفيف
- [ ] شريط تحميل يعرض "جاري تحميل البيانات..."
- [ ] مدة < 3 ثواني

### 10.5 قائمة التحقق النهائية (Pre-Launch Checklist)

#### الكود:
- [ ] `flutter analyze` = 0 errors, 0 warnings
- [ ] `flutter build windows --release` = success
- [ ] حذف كل `debugPrint` أو تحويلها لـ logging framework
- [ ] حذف كل `TODO` و `FIXME` في الكود
- [ ] حذف كل كود معلّق (commented out)

#### الوظائف:
- [ ] كل زر يعمل (لا يوجد onPressed فارغ)
- [ ] كل شاشة تتحمل بشكل صحيح
- [ ] كل form validation يعمل
- [ ] كل dialog يفتح ويغلق بشكل صحيح
- [ ] الانتقال بين الشاشات سلس

#### البيانات:
- [ ] Fresh install → كل الجداول تنشأ
- [ ] Upgrade من نسخة قديمة → migrations تعمل
- [ ] إدخال بيانات → حفظ واسترجاع صحيح
- [ ] حذف بيانات → soft delete + audit trail

#### الأمان:
- [ ] `.env` في `.gitignore`
- [ ] لا مفاتيح API في الكود
- [ ] الصلاحيات تعمل
- [ ] Audit trail يسجل كل شيء

#### الأداء:
- [ ] First load < 3s
- [ ] شاشة أي < 500ms
- [ ] RAM usage < 300MB
- [ ] DB file < 50MB (لمشاريع متوسطة)

## معايير القبول النهائية
- [ ] تثبيت على جهاز Windows نظيف → يعمل من أول مرة
- [ ] مستخدم admin يرى كل شيء
- [ ] مستخدم employee يرى حسابه فقط
- [ ] نسخة احتياطية → استعادة ناجحة
- [ ] الأداء مقبول على أجهزة متوسطة
