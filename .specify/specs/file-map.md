# خريطة الملفات الكاملة - نظام حساباتي ERP
## آخر تحديث: 2026-04-12

## الهيكل الحالي

```
lib/
├── main.dart (3364 سطر) — الشاشة الرئيسية + الـ Navigation + القائمة الجانبية
│
├── core/
│   ├── accounting/
│   │   ├── accounting_engine.dart — محرك القيود التلقائية (يحتاج توسيع كبير)
│   │   ├── coa_template.dart — قوالب شجرة الحسابات حسب القطاع
│   │   └── journal_dispatcher.dart — موزع القيود اليومية
│   ├── config/
│   │   └── app_constants.dart — ثوابت التطبيق
│   ├── database/ (فارغ — لم يُستخدم)
│   └── printing/
│       └── pdf_generator.dart — مولد PDF قديم (تم استبداله بـ pdf_service.dart)
│
├── features/
│   └── sales/
│       └── data/ (فارغ — لم يُستخدم)
│
├── screens/ (55 شاشة)
│   ├── login_screen.dart ✅
│   ├── onboarding_screen.dart ✅
│   ├── onboarding_modules_screen.dart ✅
│   ├── settings_screen.dart ✅
│   ├── hr_screen.dart ✅ (shell يوجه للمجلد)
│   ├── hr/ (مجلد الموارد البشرية المقسم)
│   ├── accounting_operations_screen.dart ✅
│   ├── taxes_screen.dart ✅
│   ├── auditing_screen.dart ✅
│   ├── inventory_screen.dart ✅
│   ├── pos_screen.dart ⚠️ لا يخصم من المخزون
│   ├── invoice_entry_screen.dart ✅
│   ├── invoices_list_screen.dart ✅
│   ├── purchase_invoice_screen.dart ✅
│   ├── quotation_screen.dart ✅
│   ├── receipt_voucher_screen.dart ✅
│   ├── payment_voucher_screen.dart ✅
│   ├── bank_reconciliation_screen.dart ✅
│   ├── manual_journal_screen.dart ✅
│   ├── trial_balance_screen.dart ✅
│   ├── financial_reports_screen.dart ✅
│   ├── reports_screen.dart ⚠️ يحتاج تقارير حقيقية
│   ├── credit_statement_screen.dart ✅
│   ├── suppliers_directory_screen.dart ✅
│   ├── supplier_details_screen.dart ✅
│   ├── assets_screen.dart ✅
│   ├── cheques_screen.dart ✅
│   ├── custody_screen.dart ✅
│   ├── wallet_screen.dart ✅
│   ├── warehouse_screen.dart ✅
│   ├── manufacturing_screen.dart ✅
│   ├── bom_setup_screen.dart ✅
│   ├── projects_screen.dart ✅
│   ├── budget_setup_screen.dart ✅
│   ├── budget_monitoring_screen.dart ✅
│   ├── ceo_dashboard_screen.dart ✅
│   ├── bi_dashboard_screen.dart ✅
│   ├── security_audit_screen.dart ✅
│   ├── users_screen.dart ✅
│   ├── maintenance_screen.dart ✅
│   ├── real_estate_screen.dart ✅
│   ├── investments_screen.dart ✅
│   ├── commercial_hub_screen.dart ✅
│   ├── cloud_inbox_screen.dart ✅
│   ├── affiliate_screen.dart ✅
│   ├── subscriptions_screen.dart ✅
│   ├── sales_commissions_screen.dart ✅
│   ├── expiry_dashboard_screen.dart ✅
│   ├── employee_chat_screen.dart ✅
│   ├── feasibility_study_screen.dart ✅
│   ├── hub_screen.dart ✅
│   ├── internal_hub_screen.dart ✅
│   ├── ai_core_screen.dart ✅
│   ├── ai_home_screen.dart ✅
│   ├── ai_insights_screen.dart ✅
│   └── (شاشات مفقودة في MISSING_SCREENS أدناه)
│
├── services/ (32 خدمة)
│   ├── database_helper.dart ✅ (5871 سطر, v54)
│   ├── ai_service.dart ✅ (REST API مع Gemini)
│   ├── ai_chat_controller.dart ✅ (Wavenet + flutter_tts)
│   ├── auth_service.dart ✅
│   ├── pdf_service.dart ✅ (فاتورة + عرض سعر + سند + مسير)
│   ├── payroll_service.dart ✅
│   ├── tax_engine.dart ✅
│   ├── tax_service.dart ✅
│   ├── reporting_service.dart ✅
│   ├── analytics_service.dart ✅
│   ├── export_service.dart ✅ (CSV تصدير)
│   ├── sync_service.dart ✅
│   ├── supabase_service.dart ✅
│   ├── cheque_service.dart ✅
│   ├── custody_service.dart ✅
│   ├── depreciation_service.dart ✅
│   ├── asset_service.dart ✅
│   ├── manufacturing_service.dart ✅
│   ├── cash_flow_service.dart ✅
│   ├── currency_service.dart ✅
│   ├── industry_provider.dart ✅ (7 قطاعات — يحتاج توسيع لـ 24)
│   ├── ocr_service.dart ✅
│   ├── qr_service.dart ✅
│   ├── email_service.dart ⚠️
│   ├── notification_service.dart ✅
│   └── (خدمات مفقودة في MISSING_SERVICES أدناه)
│
├── widgets/ (13 ودجت)
│   ├── glass_container.dart ⚠️ لا يراعي الوضع الليلي/الساطع
│   ├── ai_agent_hud.dart ✅
│   ├── ai_center_dock.dart ✅
│   └── ... (باقي الودجات ✅)
│
├── utils/
│   └── tafqeet.dart ✅ (تحويل أرقام لنصوص عربية)
│
└── theme/
    └── app_theme_extension.dart ✅ (نظام الثيم الكامل)
```

## MISSING_SCREENS (مطلوب إنشاؤها)
- `credit_note_screen.dart` — إشعارات دائنة (مرتجع مبيعات)
- `debit_note_screen.dart` — إشعارات مدينة (مرتجع مشتريات)
- `purchase_order_screen.dart` — أوامر الشراء
- `recurring_invoices_screen.dart` — الفواتير المتكررة
- `aging_report_screen.dart` — أعمار الديون
- `fiscal_year_screen.dart` — إدارة السنة المالية وإقفالها

## MISSING_SERVICES (مطلوب إنشاؤها)
- `permission_service.dart` — نظام الصلاحيات RBAC
- `audit_service.dart` — سجل التدقيق المركزي
- `backup_service.dart` — النسخ الاحتياطي
- `contract_service.dart` — إدارة العقود

## التقنيات المستخدمة
- **Framework**: Flutter 3.x / Dart
- **DB محلي**: SQLite via `sqflite` + `sqflite_common_ffi` (Desktop)
- **DB سحابي**: Supabase (PostgreSQL)
- **AI**: Gemini REST API (gemini-flash-latest)
- **TTS**: Google Cloud Wavenet + flutter_tts fallback
- **PDF**: `pdf` + `printing` packages
- **Theme**: Apple-inspired Glassmorphism with Orange (#FF6B00) primary
- **State**: Provider + ChangeNotifier
- **Localization**: easy_localization (ar.json + en.json)
- **Charts**: fl_chart

## ثوابت مهمة
- **اسم قاعدة البيانات**: `hisabati.db`
- **إصدار قاعدة البيانات**: 54
- **نظام الألوان الأساسي**: primaryOrange = `Color(0xFFFF6B00)`
- **الثيم**: Dark + Light via `themeNotifier` (ValueNotifier)
- **metadata لكل جدول SQLite**: `sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0`
