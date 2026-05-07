# خريطة الملفات الكاملة - نظام حساباتي ERP
## آخر تحديث: 2026-04-19

## الهيكل الحالي

```
lib/
├── main.dart (3329 سطر) — الشاشة الرئيسية + Navigation + القائمة الجانبية + TopBar
│
├── core/
│   ├── accounting/
│   │   ├── accounting_engine.dart — محرك القيود التلقائية (processReceiptVoucher, processPaymentVoucher, etc.)
│   │   ├── coa_template.dart — قوالب شجرة الحسابات حسب القطاع
│   │   └── journal_dispatcher.dart — موزع القيود اليومية
│   ├── config/
│   │   └── app_constants.dart — ثوابت التطبيق
│   └── printing/
│       └── pdf_generator.dart — مولد PDF قديم
│
├── screens/ (71 شاشة)
│   ├── login_screen.dart ✅ ⚠️ (backdoor admin/admin يجب إزالته — المهمة 1.1)
│   ├── onboarding_screen.dart ✅
│   ├── onboarding_modules_screen.dart ✅
│   ├── settings_screen.dart ✅ ⚠️ (setCurrentCompany خاطئ — المهمة 1.3)
│   ├── hub_screen.dart ✅
│   ├── internal_hub_screen.dart ✅
│   ├── users_screen.dart ✅ ⚠️ (كلمات مرور plain text — المهمة 1.2)
│   │
│   ├── hr_screen.dart ✅ (shell يوجه للمجلد)
│   ├── hr/
│   │   ├── hr_root_screen.dart ✅ ⚠️ (6 tabs فقط — يجب أن تكون 10 — المهمة 4)
│   │   ├── hr_dashboard_tab.dart ✅
│   │   ├── employee_list_view.dart ✅
│   │   ├── employee_details_view.dart ✅
│   │   ├── attendance_tab.dart ✅
│   │   ├── payroll_tab.dart ✅ ⚠️ (نص ثابت — المهمة 5)
│   │   ├── leaves_tab.dart ✅
│   │   ├── employee_form.dart ✅
│   │   ├── recruitment_tab.dart ✅
│   │   └── tabs/
│   │       ├── contracts_tab.dart ✅ (جاهز — غير مربوط بـ root — المهمة 4)
│   │       ├── custody_tab.dart ✅ (جاهز — غير مربوط — المهمة 4)
│   │       ├── documents_tab.dart ✅ (جاهز — غير مربوط — المهمة 4)
│   │       └── performance_tab.dart ✅ (جاهز — غير مربوط — المهمة 4)
│   │
│   ├── accounting_operations_screen.dart ✅ ⚠️ (44 withOpacity — المهمة 3)
│   ├── taxes_screen.dart ✅
│   ├── auditing_screen.dart ✅
│   ├── inventory_screen.dart ✅
│   ├── pos_screen.dart ✅ ⚠️ (رقم ضريبي ثابت + RawKeyboardListener — المهمة 2.1 + 3.2)
│   ├── invoice_entry_screen.dart ✅ ⚠️ (رقم ضريبي ثابت — المهمة 2.2)
│   ├── invoices_list_screen.dart ✅
│   ├── purchase_invoice_screen.dart ✅
│   ├── quotation_screen.dart ✅
│   ├── receipt_voucher_screen.dart ✅ ⚠️ (نص ثابت — المهمة 5)
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
│   ├── recurring_transactions_screen.dart ✅
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
│   ├── fleet_screen.dart ✅
│   ├── real_estate_screen.dart ✅
│   ├── investments_screen.dart ✅
│   ├── commercial_hub_screen.dart ✅
│   ├── cloud_inbox_screen.dart ✅
│   ├── employee_chat_screen.dart ✅ ⚠️ (مستخدمين ثابتين + onTap فارغ — المهمة 2.3 + 2.5)
│   ├── affiliate_screen.dart ✅
│   ├── subscriptions_screen.dart ✅
│   ├── sales_commissions_screen.dart ✅
│   ├── expiry_dashboard_screen.dart ✅
│   ├── feasibility_study_screen.dart ✅
│   ├── liquidation_screen.dart ✅
│   ├── currency_center_screen.dart ✅
│   ├── ai_core_screen.dart ✅
│   ├── ai_home_screen.dart ✅
│   ├── ai_insights_screen.dart ✅
│   ├── monitoring_control_screen.dart ✅
│   ├── invoice_audit_screen.dart ✅
│   ├── cash_flow_statement_screen.dart ✅
│   ├── quick_statements_screen.dart ✅
│   ├── joint_ventures_screen.dart ✅
│   ├── expense_management_screen.dart ✅
│   ├── cost_accounting_screen.dart ✅
│   └── ... (71 شاشة إجمالاً)
│
├── services/ (40 خدمة)
│   ├── database_helper.dart ✅ (7844 سطر, v72)
│   ├── ai_service.dart ✅
│   ├── ai_chat_controller.dart ✅
│   ├── ai_forecasting_service.dart ✅
│   ├── auth_service.dart ✅
│   ├── pdf_service.dart ✅ (32KB)
│   ├── payroll_service.dart ✅ (333 سطر — Saudi + Egypt + UAE + Jordan)
│   ├── tax_engine.dart ✅
│   ├── tax_service.dart ✅
│   ├── reporting_service.dart ✅
│   ├── analytics_service.dart ✅
│   ├── export_service.dart ✅
│   ├── sync_service.dart ✅
│   ├── supabase_service.dart ✅
│   ├── supabase_admin_service.dart ✅
│   ├── backup_service.dart ✅
│   ├── cheque_service.dart ✅
│   ├── custody_service.dart ✅
│   ├── depreciation_service.dart ✅
│   ├── asset_service.dart ✅
│   ├── manufacturing_service.dart ✅
│   ├── cash_flow_service.dart ✅
│   ├── currency_service.dart ✅
│   ├── commercial_service.dart ✅
│   ├── industry_provider.dart ✅ (7 قطاعات)
│   ├── ocr_service.dart ✅
│   ├── qr_service.dart ✅
│   ├── email_service.dart ✅
│   ├── gmail_service.dart ✅
│   ├── chat_service.dart ✅
│   ├── storage_service.dart ✅
│   ├── notification_service.dart ✅
│   ├── permission_service.dart ✅
│   ├── audit_service.dart ✅
│   ├── hr_pro_service.dart ✅
│   ├── maintenance_service.dart ✅
│   ├── monitoring_service.dart ✅
│   ├── module_config_service.dart ✅
│   ├── payment_service.dart ✅
│   └── performance_manager.dart ✅
│
├── widgets/
│   ├── glass_container.dart ✅
│   ├── ai_chat_bubble.dart ✅ ⚠️ (طابع زمني وهمي — المهمة 2.4)
│   ├── ai_agent_hud.dart ✅
│   ├── ai_center_dock.dart ✅
│   └── ...
│
├── utils/
│   └── tafqeet.dart ✅
│
└── theme/
    └── app_theme_extension.dart ✅
```

## الثوابت الحالية
- **اسم قاعدة البيانات**: `hisabati_offline.db` (Windows) / `hisabati.db` (Mobile)
- **إصدار قاعدة البيانات**: **72** (لا تزده إلا عند إضافة جدول/عمود جديد)
- **نظام الألوان الأساسي**: primaryOrange = `Color(0xFFFF6B00)`
- **الثيم**: Dark + Light via `themeNotifier` (ValueNotifier)
- **metadata لكل جدول SQLite**: `sync_status INTEGER DEFAULT 0, updated_at TEXT, device_id TEXT, is_deleted INTEGER DEFAULT 0`

## المشاكل المعروفة
- جميع مشاكل Phase 32 تم حلها وإصلاحها بالكامل في جلسة سابقة (تم تأمين كلمات المرور، إزالة backdoor، ربط البيانات، إزالة withOpacity، إصلاح KeyboardListener).
- النظام الآن جاهز للـ Release و Packaging (Phase 18 / 19).
