# خريطة الملفات الكاملة - نظام حساباتي ERP
## آخر تحديث: 2026-04-16

## الهيكل الحالي

```
lib/
├── main.dart (3329 سطر) — الشاشة الرئيسية + Navigation + القائمة الجانبية + TopBar
│
├── core/
│   ├── accounting/
│   │   ├── accounting_engine.dart — محرك القيود التلقائية
│   │   ├── coa_template.dart — قوالب شجرة الحسابات حسب القطاع
│   │   └── journal_dispatcher.dart — موزع القيود اليومية
│   ├── config/
│   │   └── app_constants.dart — ثوابت التطبيق
│   └── printing/
│       └── pdf_generator.dart — مولد PDF قديم
│
├── screens/ (55+ شاشة)
│   ├── login_screen.dart ✅
│   ├── onboarding_screen.dart ✅
│   ├── onboarding_modules_screen.dart ✅
│   ├── settings_screen.dart ✅
│   ├── hub_screen.dart ✅
│   ├── internal_hub_screen.dart ✅
│   ├── users_screen.dart ✅
│   │
│   ├── hr_screen.dart ✅ (shell يوجه للمجلد)
│   ├── hr/
│   │   ├── hr_root_screen.dart ✅ (6 tabs - لوحة تحكم + موظفين + حضور + اجازات + رواتب + توظيف)
│   │   ├── attendance_tab.dart ✅
│   │   ├── payroll_tab.dart ✅
│   │   ├── leaves_tab.dart ✅
│   │   ├── employee_form.dart ✅
│   │   ├── employee_chat_screen.dart ✅
│   │   └── tabs/
│   │       ├── contracts_tab.dart ✅ (يعمل لكن غير مربوط بالـ root screen)
│   │       ├── custody_tab.dart ✅ (يعمل لكن غير مربوط)
│   │       ├── documents_tab.dart ✅ (يعمل لكن غير مربوط)
│   │       └── performance_tab.dart ✅ (يعمل لكن غير مربوط)
│   │
│   ├── accounting_operations_screen.dart ✅
│   ├── taxes_screen.dart ✅
│   ├── auditing_screen.dart ✅
│   ├── inventory_screen.dart ✅
│   ├── pos_screen.dart ✅
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
│   ├── reports_screen.dart ✅
│   ├── credit_statement_screen.dart ✅
│   ├── credit_note_screen.dart ✅
│   ├── debit_note_screen.dart ✅
│   ├── purchase_order_screen.dart ✅
│   ├── recurring_invoices_screen.dart ✅
│   ├── aging_report_screen.dart ✅
│   ├── fiscal_year_screen.dart ✅
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
│   ├── maintenance_screen.dart ✅
│   ├── real_estate_screen.dart ✅
│   ├── investments_screen.dart ✅
│   ├── commercial_hub_screen.dart ✅
│   ├── cloud_inbox_screen.dart ✅
│   ├── affiliate_screen.dart ✅
│   ├── subscriptions_screen.dart ✅
│   ├── sales_commissions_screen.dart ✅
│   ├── expiry_dashboard_screen.dart ✅
│   ├── feasibility_study_screen.dart ✅
│   ├── ai_core_screen.dart ✅
│   ├── ai_home_screen.dart ✅
│   ├── ai_insights_screen.dart ✅
│   ├── monitoring_control_screen.dart ✅ (Phase 23)
│   ├── invoice_audit_screen.dart ✅ (Phase 23)
│   ├── cash_flow_statement_screen.dart ✅ (Phase 24)
│   ├── quick_statements_screen.dart ✅ (Phase 24)
│   ├── joint_ventures_screen.dart ✅ (Phase 24)
│   ├── expense_management_screen.dart ✅ (Phase 25)
│   └── cost_accounting_screen.dart ✅ (Phase 25)
│
├── services/ (32+ خدمة)
│   ├── database_helper.dart ✅ (6274 سطر, v59 → v60 بعد Phase 28)
│   ├── ai_service.dart ✅ (REST API مع Gemini)
│   ├── ai_chat_controller.dart ✅
│   ├── auth_service.dart ✅
│   ├── pdf_service.dart ✅
│   ├── payroll_service.dart ✅ (333 سطر — Saudi + Egypt + UAE + Jordan)
│   ├── tax_engine.dart ✅
│   ├── tax_service.dart ✅
│   ├── reporting_service.dart ✅
│   ├── analytics_service.dart ✅
│   ├── export_service.dart ✅
│   ├── sync_service.dart ✅
│   ├── supabase_service.dart ✅
│   ├── cheque_service.dart ✅
│   ├── custody_service.dart ✅
│   ├── depreciation_service.dart ✅
│   ├── asset_service.dart ✅
│   ├── manufacturing_service.dart ✅
│   ├── cash_flow_service.dart ✅
│   ├── currency_service.dart ✅
│   ├── industry_provider.dart ✅ (7 قطاعات — يحتاج توسيع ل 27)
│   ├── ocr_service.dart ✅
│   ├── qr_service.dart ✅
│   ├── email_service.dart ✅
│   ├── notification_service.dart ✅
│   ├── permission_service.dart ✅ (بسيط — يحتاج RBAC كامل)
│   ├── audit_service.dart ✅
│   └── backup_service.dart ✅
│
├── widgets/
│   ├── glass_container.dart ✅
│   ├── ai_agent_hud.dart ✅
│   ├── ai_center_dock.dart ✅
│   └── ... (باقي الودجات)
│
├── utils/
│   └── tafqeet.dart ✅
│
└── theme/
    └── app_theme_extension.dart ✅
```

## الثوابت الحالية
- **اسم قاعدة البيانات**: `hisabati_offline.db` (Windows) / `hisabati.db` (Mobile)
- **إصدار قاعدة البيانات**: 59 (سيصبح 60 بعد Phase 28)
- **نظام الألوان الأساسي**: primaryOrange = `Color(0xFFFF6B00)`
- **الثيم**: Dark + Light via `themeNotifier` (ValueNotifier)
- **metadata لكل جدول SQLite**: `sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0`

## المشاكل المعروفة (ستعالج في Phase 28-31)
- `_onCreate` مفقودة من database_helper.dart
- `getDeviceFingerprint` اسمها مشوه ل `getDeviceFingerdebugPrint`
- attendance_logs columns mismatch (check_in vs check_in_time)
- HR tabs في `tabs/` غير مربوطة ب hr_root_screen.dart
- 50+ withOpacity deprecated calls
