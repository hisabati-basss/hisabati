# المرحلة 2: تحسين نسخة سطح المكتب

## الأولوية: 🟠 عالية

## السياق
التطبيق مصمم أساساً للموبايل مع بعض التكييفات لسطح المكتب. الهدف هو جعل تجربة Desktop احترافية مثل QuickBooks Desktop.

## المهام

### 2.1 قائمة علوية (Menu Bar) لسطح المكتب
**ملف جديد:** `lib/widgets/desktop_menu_bar.dart`
- [ ] إنشاء MenuBar باستخدام Flutter's `MenuBar` widget
- [ ] الأقسام: ملف | تحرير | عرض | معاملات | تقارير | مساعدة
- [ ] اختصارات لوحة المفاتيح:
  - `Ctrl+N` = فاتورة جديدة
  - `Ctrl+P` = طباعة
  - `Ctrl+S` = حفظ/مزامنة
  - `Ctrl+E` = تصدير Excel
  - `Ctrl+F` = بحث شامل
  - `Ctrl+,` = الإعدادات
  - `F5` = تحديث البيانات
- [ ] إظهار فقط على `Platform.isWindows || Platform.isLinux || Platform.isMacOS`

### 2.2 شريط حالة سفلي (Status Bar)
**ملف جديد:** `lib/widgets/desktop_status_bar.dart`
- [ ] يعرض من اليمين لليسار:
  - اسم المستخدم الحالي ودوره
  - اسم الشركة النشطة
  - العملة المستخدمة
  - نسبة الضريبة
  - حالة الاتصال (🟢 متصل / 🔴 غير متصل)
  - آخر مزامنة
  - إصدار التطبيق
- [ ] ارتفاع 28px فقط، خلفية داكنة
- [ ] إظهار فقط على Desktop

### 2.3 تحسين Sidebar
**ملف:** `lib/main.dart` - SidebarWidget
- [ ] إضافة زر طي/توسيع (Collapse/Expand)
- [ ] في الوضع المطوي: أيقونات فقط (60px عرض)
- [ ] في الوضع الموسع: أيقونات + نص (220px عرض)
- [ ] حفظ حالة الطي في SharedPreferences
- [ ] تجميع العناصر في أقسام (محاسبة، HR، مخزون، تقارير، إعدادات)
- [ ] إضافة شريط بحث سريع في أعلى Sidebar

### 2.4 إصلاح APIs خاصة بالموبايل
**ملف:** `lib/main.dart`
- [ ] لف `SystemChrome.setEnabledSystemUIMode` بـ `if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))`
- [ ] التأكد من عدم استدعاء `mobile_scanner` على Desktop
- [ ] استخدام `TextField` كبديل لمسح الباركود على Desktop

### 2.5 Context Menu (كليك يمين)
**ملف جديد:** `lib/widgets/context_menu_wrapper.dart`
- [ ] عند الكليك يمين على عنصر في قائمة (فاتورة، موظف، صنف):
  - عرض | تعديل | حذف | طباعة | نسخ
- [ ] استخدام Flutter's `ContextMenuRegion` أو custom implementation

### 2.6 دعم السحب والإفلات (Drag & Drop)
- [ ] سحب ملفات PDF/صور إلى Cloud Inbox
- [ ] سحب ملفات Excel لاستيراد بيانات

## التحقق
- [ ] التطبيق يعمل بسلاسة على Windows 10/11
- [ ] كل الاختصارات تعمل
- [ ] Sidebar يطوي ويتوسع بسلاسة
- [ ] لا أخطاء Platform-specific
