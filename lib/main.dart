import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hisabati_app/core/config/module_definitions.dart';
import 'package:hisabati_app/services/module_config_service.dart';
import 'package:hisabati_app/services/subscription_service.dart';
import 'screens/modules/unified_vertical_module_screen.dart';
import 'core/config/module_schemas.dart';
import 'package:hisabati_app/services/industry_provider.dart';
import 'package:hisabati_app/services/ai_chat_controller.dart';
import 'package:hisabati_app/services/sync_service.dart';
import 'package:hisabati_app/services/sync_engine.dart';
import 'package:hisabati_app/services/notification_service.dart';
import 'package:hisabati_app/services/performance_manager.dart';
import 'package:hisabati_app/widgets/conflict_dialog.dart';
import 'package:hisabati_app/services/update_service.dart';
import 'package:hisabati_app/services/auth_service.dart';
import 'package:hisabati_app/services/hr_pro_service.dart';
import 'package:hisabati_app/core/config/app_constants.dart';
import 'package:hisabati_app/screens/taxes_screen.dart';
import 'package:hisabati_app/screens/auditing_screen.dart';
import 'package:hisabati_app/screens/hr_screen.dart';
import 'package:hisabati_app/services/permission_service.dart';
import 'package:hisabati_app/services/audit_service.dart';
import 'package:hisabati_app/services/backup_service.dart';
import 'package:hisabati_app/screens/trial_balance_screen.dart';
import 'package:hisabati_app/screens/feasibility_study_screen.dart';
import 'package:hisabati_app/screens/users_screen.dart';
import 'package:hisabati_app/screens/user_management_screen.dart';
import 'package:hisabati_app/screens/login_screen.dart';
import 'package:hisabati_app/screens/affiliate_screen.dart';
import 'package:hisabati_app/screens/inventory_screen.dart';
import 'screens/assets_professional_screen.dart';
import 'screens/manufacturing_professional_screen.dart';
import 'screens/real_estate_professional_screen.dart';
import 'screens/investments_professional_screen.dart';
import 'screens/projects_professional_screen.dart';
import 'screens/ecommerce_professional_screen.dart';
import 'screens/hr_professional_screen.dart';
import 'screens/hub_screen.dart';
import 'package:hisabati_app/screens/settings_screen.dart';
import 'package:hisabati_app/screens/credit_statement_screen.dart';
import 'package:hisabati_app/screens/assets_screen.dart';
import 'screens/accounting_operations_screen.dart';
import 'screens/internal_hub_screen.dart';
import 'screens/purchase_invoice_screen.dart';
import 'screens/suppliers_directory_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/financial_reports_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/ceo_dashboard_screen.dart';
import 'services/database_helper.dart';
import 'widgets/ai_agent_hud.dart';
import 'widgets/live_dashboard_charts.dart';
import 'widgets/apple_entrance.dart';
import 'widgets/robot_avatar.dart';
import 'widgets/splash_screen_widget.dart';
import 'widgets/sidebar_widget.dart';
import 'widgets/top_bar_widget.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/ai_chat_widgets.dart';
import 'theme/app_theme_extension.dart';
import 'screens/ai_home_screen.dart';
import 'screens/onboarding_modules_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/commercial_hub_screen.dart';
import 'screens/sales_commissions_screen.dart';
import 'screens/expiry_dashboard_screen.dart';
import 'screens/employee_chat_screen.dart';
import 'screens/pos_screen.dart';
import 'widgets/theme_toggle_capsule.dart';
import 'widgets/language_toggle_capsule.dart';
import 'widgets/desktop_menu_bar.dart';
import 'widgets/desktop_status_bar.dart';
import 'screens/warehouse_screen.dart';
import 'widgets/shortcut_handler.dart';
import 'screens/cloud_inbox_screen.dart';
import 'screens/budget_setup_screen.dart';
import 'screens/budget_monitoring_screen.dart';
import 'screens/bi_dashboard_screen.dart';
import 'screens/manufacturing_screen.dart';
import 'screens/cheques_screen.dart';
import 'screens/custody_screen.dart';
import 'screens/security_audit_screen.dart';
import 'screens/real_estate_screen.dart';
import 'screens/finance/revenue_professional_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/bom_setup_screen.dart';
import 'screens/credit_note_screen.dart';
import 'screens/debit_note_screen.dart';
import 'screens/accounting/budgeting_screen.dart';
import 'screens/accounting/consolidated_financials_screen.dart';
import 'screens/purchase_order_screen.dart';
import 'screens/recurring_invoices_screen.dart';
import 'screens/aging_report_screen.dart';
import 'screens/fiscal_year_screen.dart';
import 'package:hisabati_app/screens/monitoring_control_screen.dart';
import 'package:hisabati_app/screens/invoice_audit_screen.dart';
import 'package:hisabati_app/screens/cash_flow_statement_screen.dart';
import 'package:hisabati_app/screens/quick_statements_screen.dart';
import 'package:hisabati_app/screens/joint_ventures_screen.dart';
import 'package:hisabati_app/screens/expense_management_screen.dart';
import 'package:hisabati_app/screens/cost_accounting_screen.dart';
import 'package:hisabati_app/screens/subscriptions_screen.dart';
import 'screens/bank_reconciliation_screen.dart';
import 'screens/currency_center_screen.dart';
import 'screens/recurring_transactions_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/liquidation_screen.dart';
import 'screens/invoices_list_screen.dart';
import 'screens/invoice_entry_screen.dart';
import 'screens/manual_journal_screen.dart';
import 'screens/payment_voucher_screen.dart';
import 'screens/receipt_voucher_screen.dart';
import 'screens/quotation_screen.dart';
import 'screens/supplier_details_screen.dart';
import 'package:hisabati_app/screens/ai_insights_screen.dart';
import 'package:hisabati_app/screens/ai_core_screen.dart';
import 'package:hisabati_app/screens/file_manager_screen.dart';
import 'package:hisabati_app/screens/sales/sales_dashboard_screen.dart';
import 'package:hisabati_app/screens/purchases/purchases_dashboard_screen.dart';
import 'package:hisabati_app/screens/inventory/inventory_dashboard_screen.dart';
import 'package:hisabati_app/screens/accounting/accounting_dashboard_screen.dart';
import 'screens/accounting/tax_zakat_report_screen.dart';
import 'screens/accounting/zakat_estimate_screen.dart';
import 'screens/approval_center_screen.dart';
import 'screens/branch_professional_screen.dart';
import 'screens/fleet_professional_screen.dart';
import 'package:hisabati_app/ui/screens/generic_module_screen.dart';
import 'screens/accounting/balance_sheet_screen.dart';
import 'screens/accounting/income_statement_screen.dart';
import 'screens/accounting/account_ledger_screen.dart';
import 'screens/customers_professional_screen.dart';
import 'screens/contracts_professional_screen.dart';
import 'screens/compliance_governance_screen.dart';
import 'screens/customers_crm_screen.dart';
import 'screens/industrial_costing_screen.dart';
import 'screens/taxes_global_screen.dart';
import 'screens/risk_management_screen.dart';
import 'screens/payroll_professional_screen.dart';
import 'screens/accounting/zatca_integration_screen.dart';
import 'screens/contracting/contracting_professional_screen.dart';
import 'screens/hospitality/hotel_mgmt_screen.dart';
import 'screens/medical/medical_professional_screen.dart';
import 'screens/industries/pharmacy_professional_screen.dart';
import 'screens/industries/car_trading_professional_screen.dart';
import 'screens/industries/gas_station_professional_screen.dart';
import 'screens/industries/agriculture_professional_screen.dart';
import 'screens/industries/furniture_professional_screen.dart';
import 'screens/industries/electronics_professional_screen.dart';
import 'screens/industries/cleaning_materials_professional_screen.dart';
import 'screens/industries/sanitary_ware_professional_screen.dart';
import 'screens/industries/office_services_professional_screen.dart';
import 'screens/entities/branch_chains_screen.dart';
import 'screens/entities/holding_groups_screen.dart';
import 'screens/entities/digital_ecommerce_screen.dart';
import 'screens/entities/supply_chain_screen.dart';
import 'screens/operations/trade_contracts_screen.dart';
import 'screens/operations/stock_waste_screen.dart';
import 'screens/operations/barcode_mgmt_screen.dart';
import 'screens/entities/delivery_professional_screen.dart';
import 'screens/entities/general_companies_professional_screen.dart';
import 'screens/entities/holding_groups_professional_screen.dart';
import 'screens/entities/branch_chains_professional_screen.dart';
import 'screens/support/support_tickets_screen.dart';
import 'screens/support/meeting_mgmt_screen.dart';
import 'screens/support/workflow_mgmt_screen.dart';
import 'screens/support/task_kanban_screen.dart';
import 'screens/support/approval_system_screen.dart';
import 'screens/support/audit_trail_screen.dart';
import 'screens/support/kpi_management_screen.dart';
import 'screens/logistics/shipping_logistics_screen.dart';
import 'screens/hr/recruitment_screen.dart';
import 'screens/hr/performance_appraisal_screen.dart';
import 'screens/crm/crm_leads_screen.dart';
import 'screens/crm/crm_dashboard_screen.dart';
import 'screens/support/legal_affairs_screen.dart';
import 'screens/industries/quality_mgmt_screen.dart';
import 'screens/industries/periodic_maintenance_screen.dart';
import 'screens/industries/laboratories_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Color(0xFF0F0F12),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  try {
    await dotenv.load(fileName: ".env");
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } else {
      debugPrint("⚠️ Supabase credentials missing in .env. Running in offline mode.");
    }
  } catch (e) {
    debugPrint("❌ Supabase Initialization Error: $e");
  }

  try {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      debugPrint("Stripe is not supported natively on Desktop. Skipping initialization.");
    } else {
      final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
      if (stripeKey.isNotEmpty) {
        Stripe.publishableKey = stripeKey;
        await Stripe.instance.applySettings();
      }
    }
  } catch (e) {
    debugPrint("❌ Stripe Initialization Error: $e");
  }

  await ModuleConfigService().init();
  await SubscriptionService().init();

  await EasyLocalization.ensureInitialized();

  await PerformanceManager.optimizeForDevice();

  HRProService().runAutoChecks().catchError((e) => debugPrint("HR Pro Check Error: $e"));

  await NotificationService().loadFromStorage();
  await UpdateService().checkForUpdate();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AiChatController()),
          ChangeNotifierProvider(create: (_) => IndustryProvider()),
          ChangeNotifierProvider(create: (_) => SyncService()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
          ChangeNotifierProvider.value(value: SubscriptionService()),
          ChangeNotifierProvider.value(value: ModuleConfigService()),
        ],
        child: const HisabatiApp(),
      ),
    ),
  );
}

class HisabatiApp extends StatefulWidget {
  const HisabatiApp({super.key});

  @override
  State<HisabatiApp> createState() => _HisabatiAppState();
}

class _HisabatiAppState extends State<HisabatiApp> {
  bool _isOnboarded = false;
  bool _devBypassLogin = false;

  bool _localLoggedIn = false;

  @override
  void initState() {
    super.initState();
    
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _localLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        });
      }
    });

    _checkOnboarding();
    
    DatabaseHelper().processRecurringTransactions();

    AuthService().onAuthStateChange.listen((data) {
      if (data.session != null && !_isOnboarded) {
        _checkOnboarding();
      }
      if (data.session == null && _devBypassLogin) {
        if (mounted) {
          setState(() => _devBypassLogin = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return StreamBuilder<AuthState>(
          stream: AuthService().onAuthStateChange,
          builder: (context, snapshot) {
            final session = snapshot.data?.session;
            final bool isLoggedIn = session != null || _localLoggedIn || _devBypassLogin; 

            return MaterialApp(
              title: tr('app_name'),
              debugShowCheckedModeBanner: false,
              themeMode: currentMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: ThemeData.light().copyWith(
                scaffoldBackgroundColor: const Color(0xFFF3F4F6),
                textTheme: GoogleFonts.tajawalTextTheme(
                  ThemeData.light().textTheme,
                ),
                colorScheme: const ColorScheme.light(
                  primary: AppConstants.primaryOrange,
                  secondary: AppConstants.accentGold,
                  surface: Colors.white,
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: AppConstants.bgSurface,
                textTheme: GoogleFonts.tajawalTextTheme(
                  ThemeData.dark().textTheme,
                ),
                colorScheme: const ColorScheme.dark(
                  primary: AppConstants.primaryOrange,
                  secondary: AppConstants.accentGold,
                  surface: AppConstants.cardSurface,
                ),
              ),
              builder: (context, child) {
                return Directionality(
                  textDirection: context.locale.languageCode == 'ar'
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                  child: child!,
                );
              },
              home: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeInOutCubic,
                child:
                    snapshot.connectionState == ConnectionState.waiting ||
                        (isLoggedIn && !_isOnboarded && _isLoadingOnboarding)
                    ? const SplashScreenWidget()
                    : (!isLoggedIn
                          ? LoginScreen(
                              onGuestLogin: () =>
                                  setState(() => _devBypassLogin = true),
                            )
                          : (!_isOnboarded
                                ? OnboardingScreen(
                                    onComplete: () =>
                                        setState(() => _isOnboarded = true),
                                  )
                                : (!ModuleConfigService().setupCompleted
                                      ? OnboardingModulesScreen(
                                          onCompleted: () => setState(() {}),
                                        )
                                      : MainScreen(
                                          onLogout: () async {
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setBool('isLoggedIn', false);
                                            await prefs.remove('user_id');
                                            setState(() {
                                              _devBypassLogin = false;
                                              _localLoggedIn = false;
                                            });
                                          },
                                        )))),
              ),
            );
          },
        );
      },
    );
  }

  bool _isLoadingOnboarding = true;
  Future<void> _checkOnboarding() async {
    setState(() => _isLoadingOnboarding = true);
    final context = await DatabaseHelper().getCurrentCompanyContext();
    if (mounted) {
      setState(() {
        _isOnboarded = context['company_id'] != null;
        _isLoadingOnboarding = false;
      });
    }
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int? _activeHeaderMenuIndex;
  bool _isAiCapsuleExpanded = false;
  bool _isSidebarExpanded = false;
  late AnimationController _bgController;
  final TextEditingController _globalAiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    final user = AuthService().currentUser;
    if (user != null) {
      final roleStr = user.userMetadata?['role']?.toString() ?? 'admin';
      UserRole role = UserRole.admin;
      try {
        role = UserRole.values.firstWhere((e) => e.name == roleStr);
      } catch (_) {
        role = UserRole.admin;
      }
      PermissionService().setUserContext(
        user.id,
        roleStr,
        user.userMetadata?['permissions']?.toString(),
        user.userMetadata?['branch_id']?.toString(),
      );
      AuditService.log(action: 'login', entityType: 'user', entityId: user.id);
    }
    
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    if (perfShowAnimations.value) _bgController.repeat();

    perfShowAnimations.addListener(() {
      if (perfShowAnimations.value) {
        _bgController.repeat();
      } else {
        _bgController.stop();
      }
    });

    NotificationService().checkSystemAlerts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (PerformanceManager.shouldShowAlert) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "تم ضبط إعدادات العرض تلقائياً لضمان أفضل سرعة على جهازك. يمكنك تغييرها من الإعدادات.",
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            backgroundColor: primaryOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        PerformanceManager.consumeAlert();
      }
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiController = Provider.of<AiChatController>(
        context,
        listen: false,
      );
      aiController.onNavigateRequested = (index) {
        if (mounted) {
          setState(() {
            _selectedIndex = index;
            _isAiCapsuleExpanded = false;
          });
          aiController.clearMessages();
        }
      };
    });

    SyncEngine().conflictStream.listen((event) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConflictDialog(
            event: event,
            onResolve: (mergedData) {
              SyncEngine().resolveConflict(
                queueId: event.queueId,
                table: event.table,
                recordId: event.recordId,
                mergedData: mergedData,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _globalAiController.dispose();
    super.dispose();
  }

  Widget _buildCurrentScreen(bool isMobile) {
    final module = AppModules.allModules.firstWhere(
      (m) => m.index == _selectedIndex,
      orElse: () => AppModules.allModules.first,
    );

    if (_selectedIndex == 100) {
      return HubScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
    }

    switch (_selectedIndex) {
      case 0:
        return AiHomeScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return CEODashboardScreen(isMobile: isMobile);
      case 2:
        return const AccountingDashboardScreen();
      case 3: return const TaxZakatReportScreen();
      case 4: return const HRProfessionalScreen();
      case 5: return const AuditingScreen();
      case 6: return const FeasibilityStudyScreen();
      case 7: return const UserManagementScreen();
      case 8: return const AffiliateScreen();
      case 9: return const FinancialReportsScreen();
      case 10: return const InventoryDashboardScreen();
      case 11: return const ProjectsProfessionalScreen();
      case 12:
        return SettingsScreen(onLogout: widget.onLogout);
      case 13: return const CreditStatementScreen();
      case 14: return const AssetsProfessionalScreen();
      case 15: return const RevenueProfessionalScreen();
      case 16:
        return const PurchasesDashboardScreen();
      case 17: return const SuppliersDirectoryScreen();
      case 18: return const WalletScreen();
      case 19: return WarehouseScreen(isMobile: isMobile);
      case 20: return CloudInboxScreen(isMobile: isMobile);
      case 21: return PosScreen(isMobile: isMobile);
      case 22: return const BudgetingScreen();
      case 23: return const BudgetMonitoringScreen();
      case 24: return const BIDashboardScreen();
      case 25: return const ManufacturingProfessionalScreen();
      case 26: return const BomSetupScreen();
      case 27: return const ChequesScreen();
      case 28: return const CustodyScreen();
      case 29: return const AuditingScreen();
      case 30: return const SubscriptionsScreen();
      case 31: return const RealEstateProfessionalScreen();
      case 32: return const InvestmentsProfessionalScreen();
      case 33: return const CommercialHubScreen();
      case 35: return const TrialBalanceScreen();
      case 36: return const MaintenanceScreen();
      case 37: return const SalesCommissionsScreen();
      case 38: return const ExpiryDashboardScreen();
      case 40:
        final uMeta = AuthService().currentUser?.userMetadata ?? {};
        return EmployeeChatScreen(
          currentUserId: AuthService().currentUser?.id ?? 'EMP_LOCAL',
          currentUserName: '${uMeta['full_name'] ?? 'مدير النظام'} - ${uMeta['job_title'] ?? 'إدارة عليا'}',
        );
      case 41: return const CreditNoteScreen();
      case 42: return const DebitNoteScreen();
      case 43: return const PurchaseOrderScreen();
      case 44: return const RecurringInvoicesScreen();
      case 45: return const AgingReportScreen();
      case 46: return const FiscalYearScreen();
      case 47: return const MonitoringControlScreen();
      case 48: return const InvoiceAuditScreen();
      case 49: return const CashFlowStatementScreen();
      case 120: return const EcommerceProfessionalScreen();
      case 50: return const QuickStatementsScreen();
      case 51: return const JointVenturesScreen();
      case 52: return const ExpenseManagementScreen();
      case 53: return const CostAccountingScreen();
      case 54: return const BankReconciliationScreen();
      case 55: return const CurrencyCenterScreen();
      case 56: return const ContractsProfessionalScreen();
      case 59: return const CustomersProfessionalScreen();
      case 121: return const CRMDashboardScreen();
      case 101: return const ComplianceGovernanceScreen();
      case 102: return const RiskManagementScreen();
      case 158: return const TaxesGlobalScreen();
      case 159: return const PayrollProfessionalScreen();
      case 60:
        return const SalesDashboardScreen();
      case 65: return const AiInsightsScreen();
      case 67: return const SecurityAuditScreen();
      case 72: return const FileManagerScreen();
      case 106: return const WorkflowMgmtScreen();
      case 160: return const BranchProfessionalScreen();
      case 164: return const ApprovalCenterScreen();
      case 165: return const ZakatEstimateScreen();
      case 166: return const ZatcaIntegrationScreen();
      case 167: return const LegalAffairsScreen();
      case 168: return const ConsolidatedFinancialsScreen();
      case 169: return const BalanceSheetScreen();
      case 170: return const IncomeStatementScreen();
      case 143: return const HotelMgmtScreen();
      case 144: return const MedicalProfessionalScreen();
      case 139: return const ContractingProfessionalScreen();
      case 103: return const SupportTicketsScreen();
      case 105: return const MeetingMgmtScreen();
      case 107: return const TaskKanbanScreen();
      case 110: return const ApprovalSystemScreen();
      case 111: return const AuditTrailScreen();
      case 112: return const KPIManagementScreen();
      case 133: return const ShippingLogisticsScreen();
      case 171: return const FleetProfessionalScreen();
      case 146: return const PharmacyProfessionalScreen();
      case 149: return const CarTradingProfessionalScreen();
      case 147: return const GasStationProfessionalScreen();
      case 145: return const AgricultureProfessionalScreen();
      case 135: return const DigitalEcommerceScreen();
      case 124: return const SupplyChainScreen();
      case 150: return const FurnitureProfessionalScreen();
      case 151: return const ElectronicsProfessionalScreen();
      case 152: return const CleaningMaterialsProfessionalScreen();
      case 153: return const SanitaryWareProfessionalScreen();
      case 154: return const OfficeServicesProfessionalScreen();
      case 130: return const BranchChainsScreen();
      case 131: return const HoldingGroupsScreen();
      case 125: return const TradeContractsScreen();
      case 123: return const StockWasteScreen();
      case 122: return const BarcodeMgmtScreen();
      case 115: return const RecruitmentScreen();
      case 116: return const PerformanceAppraisalScreen();
      case 141: return const QualityMgmtScreen();
      case 142: return const PeriodicMaintenanceScreen();
      case 131: return const HoldingGroupsProfessionalScreen();
      case 130: return const BranchChainsProfessionalScreen();
      case 134: return const DeliveryProfessionalScreen();
      case 127: return const GeneralCompaniesProfessionalScreen();
      case 148: return const LaboratoriesScreen();
    }

    final modDefForRouting = AppModules.allModules.cast<ModuleDef?>().firstWhere(
      (m) => m?.index == _selectedIndex,
      orElse: () => null,
    );

    if (modDefForRouting != null && ModuleSchemas.all.containsKey(modDefForRouting.id)) {
      return UnifiedVerticalModuleScreen(moduleId: modDefForRouting.id);
    }
    
    return GenericModuleScreen(moduleId: module.id);
  }


  @override
  Widget build(BuildContext context) {
    return GlobalShortcutHandler(
      onNewInvoice: () {
        setState(() => _selectedIndex = 2);
      },
      onSave: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ (Ctrl+S)')));
      },
      child: DesktopMenuBar(
        child: Scaffold(
        body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;

          return Stack(
              children: [
                Container(color: context.bgSurface),

                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: OrbBackgroundPainter(
                          animationValue: _bgController.value,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          orangeColor: primaryOrange,
                          goldColor: accentGold,
                        ),
                      );
                    },
                  ),
                ),

                Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (!isMobile)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOutCubic,
                                      width: _isSidebarExpanded ? 310 : 100,
                                      child: SidebarWidget(
                                        selectedIndex: _selectedIndex,
                                        isExpanded: _isSidebarExpanded,
                                        onToggle: () {
                                          setState(() {
                                            _isSidebarExpanded = !_isSidebarExpanded;
                                          });
                                        },
                                        onItemSelected: (index) {
                                          setState(() {
                                            _selectedIndex = index;
                                            _activeHeaderMenuIndex = null; 
                                          });
                                        },
                                      ),
                                    ),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        AnimatedPadding(
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          padding: EdgeInsets.fromLTRB(
                                            12,
                                            58,
                                            isMobile ? 12 : 12,
                                            isMobile ? 12 : 12, 
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            switchInCurve:
                                                Curves.easeInOutCubic,
                                            switchOutCurve:
                                                Curves.easeInOutCubic,
                                            transitionBuilder:
                                                (
                                                  child,
                                                  animation,
                                                ) => FadeTransition(
                                                  opacity: animation,
                                                  child: ScaleTransition(
                                                    scale:
                                                        Tween<double>(
                                                          begin: 0.98,
                                                          end: 1.0,
                                                        ).animate(
                                                          CurvedAnimation(
                                                            parent: animation,
                                                            curve: Curves
                                                                .easeOutBack,
                                                          ),
                                                        ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      child: child,
                                                    ),
                                                  ),
                                                ),
                                            key: ValueKey(_selectedIndex),
                                            child: _buildCurrentScreen(
                                              isMobile,
                                            ),
                                          ),
                                        ),
                                        _buildGlobalAiHUD(isMobile),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMobile) _buildMobileBottomNav(),
                            if (!isMobile && !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) 
                              const DesktopStatusBar(),
                          ],
                        ),
                      ),

                      if (_activeHeaderMenuIndex != null)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeHeaderMenuIndex = null),
                            behavior: HitTestBehavior.opaque,
                            child: const ColoredBox(color: Colors.transparent),
                          ),
                        ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AppleEntrance(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: TopBarWidget(
                              isMobile: isMobile,
                              isHUD: _selectedIndex == 0,
                              activeIndex: _activeHeaderMenuIndex,
                              onActiveIndexChanged: (index) => setState(
                                () => _activeHeaderMenuIndex = index,
                              ),
                              onNavigate: (index) =>
                                  setState(() => _selectedIndex = index),
                              onLogout: widget.onLogout,
                            ),
                          ),
                        ),
                      ),

                      _buildNotificationOverlay(),
                    ],
                  ),
                ),
              ],
            );
        },
      ),
    ),
    ),
    );
  }

  Widget _buildNotificationOverlay() {
    return ValueListenableBuilder<AppAlert?>(
      valueListenable: NotificationService().latestAlert,
      builder: (context, alert, child) {
        if (alert == null) return const SizedBox.shrink();

        Color typeColor;
        IconData typeIcon;
        switch (alert.type) {
          case NotificationType.security:
            typeColor = Colors.redAccent;
            typeIcon = Icons.security;
            break;
          case NotificationType.update:
            typeColor = AppConstants.primaryOrange;
            typeIcon = Icons.rocket_launch_rounded;
            break;
          case NotificationType.success:
            typeColor = Colors.greenAccent;
            typeIcon = Icons.check_circle_outline;
            break;
          case NotificationType.warning:
            typeColor = Colors.orangeAccent;
            typeIcon = Icons.warning_amber_rounded;
            break;
          default:
            typeColor = AppConstants.primaryOrange;
            typeIcon = Icons.notifications_none_rounded;
        }

        return Positioned(
          top: 80,
          left: 24,
          right: 24,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: GestureDetector(
                    onTap: () {
                      if (alert.actionRoute != null) {
                        final index = int.tryParse(alert.actionRoute!);
                        if (index != null) setState(() => _selectedIndex = index);
                      }
                      NotificationService().clearAlert();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              typeIcon,
                              color: typeColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  alert.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  alert.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.mutedText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => NotificationService().clearAlert(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGlobalAiHUD(bool isMobile) {
    return Consumer<AiChatController>(
      builder: (context, aiController, _) {
        return Stack(
          children: [
            Builder(
              builder: (context) {
                final sw = MediaQuery.of(context).size.width;
                final kb = MediaQuery.of(context).viewInsets.bottom;
                final capsuleCenter = sw / 2 - 50;
                final isAiPage = _selectedIndex == 0;

                final isExpanded = isAiPage || _isAiCapsuleExpanded;
                
                final robotBottomFinal = kb + (isAiPage ? 350 : (isExpanded ? 130 : 95));
                final chatBottomFinal = kb + (isAiPage ? 345 : (isExpanded ? 120 : 85));
                final robotSizeFinal = isAiPage ? 180.0 : 90.0;

                double robotLeftFinal;
                
                if (isAiPage) {
                  robotLeftFinal = aiController.messages.isEmpty
                      ? (capsuleCenter - 160)
                      : (capsuleCenter - 368);
                } else {
                  if (sw > 1000) {
                     robotLeftFinal = capsuleCenter - 620; 
                  } else {
                     robotLeftFinal = capsuleCenter - 90;
                  }
                }

                final chatLeftFinal = robotLeftFinal + 196;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutQuart,
                      bottom: robotBottomFinal,
                      left: robotLeftFinal,
                      child: isAiPage 
                          ? RobotAvatar(
                              state: aiController.robotState,
                              size: robotSizeFinal,
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutQuart,
                      bottom: chatBottomFinal,
                      left: aiController.messages.isEmpty ? sw + 600 : chatLeftFinal,
                      child: isAiPage 
                          ? AiFloatingChatHistory(
                              messages: aiController.messages,
                              isThinking: aiController.isThinking,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),

            AnimatedAlign(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.fastLinearToSlowEaseIn,
              alignment: (_selectedIndex == 0 || _isAiCapsuleExpanded) 
                  ? Alignment.bottomCenter 
                  : Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      ((_selectedIndex == 0 || _isAiCapsuleExpanded) ? 20 : 5),
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: (_selectedIndex == 0 || _isAiCapsuleExpanded)
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.end,
                  children: [
                    AiAgentInputCapsule(
                      controller: _globalAiController,
                      activePageIndex: _selectedIndex,
                      onExpansionChanged: (expanded) {
                        setState(() => _isAiCapsuleExpanded = expanded);
                      },
                      isListening: aiController.isListening,
                      onSend: () {
                        if (_globalAiController.text.trim().isNotEmpty) {
                          aiController.sendTextMessage(_globalAiController.text);
                          _globalAiController.clear();
                        }
                      },
                      onMicTap: () => aiController.toggleListening(),
                      onAttachTap: () => aiController.pickFile(),
                    ),
                    if (_selectedIndex == 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 92), 
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 858),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 600),
                                opacity: (_selectedIndex == 0) ? 1.0 : 0.0,
                                child: AdvancedSuggestionsPanel(
                                  onSuggestionTap: (index) {
                                    setState(() => _selectedIndex = index);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: context.bgSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (PermissionService().isVisible('ai_chat'))
                  _buildAnimatedNavItem(
                    0,
                    Icons.auto_awesome,
                    tr('sidebar.ai_chat'),
                  ),
                if (PermissionService().isVisible('purchases'))
                  _buildAnimatedNavItem(
                    16,
                    Icons.document_scanner,
                    tr('sidebar.purchases'),
                  ),
                if (PermissionService().isVisible('taxes'))
                  _buildAnimatedNavItem(
                    3,
                    Icons.receipt_long,
                    tr('sidebar.taxes'),
                  ),
                if (PermissionService().isVisible('hr'))
                  _buildAnimatedNavItem(4, Icons.people, tr('sidebar.hr')),
                _buildAnimatedNavItem(
                  100,
                  Icons.apps,
                  tr('hub.header.app_center'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryOrange : context.mutedText,
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryOrange : context.mutedText,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class AiFloatingChatHistory extends StatefulWidget {
  final List<Message> messages;
  final bool isThinking;

  const AiFloatingChatHistory({
    super.key,
    required this.messages,
    this.isThinking = false,
  });

  @override
  State<AiFloatingChatHistory> createState() => _AiFloatingChatHistoryState();
}

class _AiFloatingChatHistoryState extends State<AiFloatingChatHistory> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant AiFloatingChatHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        widget.isThinking != oldWidget.isThinking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isThinking)
      return const SizedBox.shrink();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 350,
        child: ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.messages.length + (widget.isThinking ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.isThinking && index == 0) {
              return _buildThinkingBubble(isDark);
            }

            final messageIndex = widget.isThinking ? index - 1 : index;
            if (messageIndex < 0 || messageIndex >= widget.messages.length)
              return const SizedBox.shrink();

            final msg = widget.messages[messageIndex];
            return _buildBubble(msg.text, msg.isUser, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryOrange.withValues(alpha: 0.85)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                textDirection: context.locale.languageCode == 'ar'
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                style: TextStyle(
                  color: isUser
                      ? Colors.black87
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.4)),
          ),
          child: Text(
            tr('common.thinking'),
            style: const TextStyle(
              color: primaryOrange,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCapsule extends StatelessWidget {
  final Widget child;
  final bool active;
  final VoidCallback? onTap;

  const GlassCapsule({
    super.key,
    required this.child,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, child) {
        final double blur = showBlur ? 40 : 0;
        final res = GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? primaryOrange : context.cardSurface,
                  border: Border.all(color: context.cardBorder),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: child,
              ),
            ),
          ),
        );
        return res;
      },
      child: child,
    );
  }
}

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, _) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(25, 45, 10, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: showBlur ? 40 : 0, sigmaY: showBlur ? 40 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  width: isExpanded ? 310 : 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(45),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 50,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 14 : 0),
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isExpanded
                                ? FittedBox(
                                    fit: BoxFit.none,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Row(
                                      key: const ValueKey('expanded'),
                                      children: [
                                        SizedBox(
                                          width: 210,
                                          child: SizedBox(
                                            height: 38,
                                          child: TextField(
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "بحث...",
                                              hintStyle: TextStyle(
                                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
                                              ),
                                              prefixIcon: const Icon(Icons.search, size: 16, color: AppConstants.primaryOrange),
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_double_arrow_right,
                                            color: AppConstants.primaryOrange, size: 20),
                                        onPressed: onToggle,
                                      ),
                                    ],
                                  ),
                                )
                                : IconButton(
                                    key: const ValueKey('collapsed'),
                                    icon: const Icon(Icons.menu, color: AppConstants.primaryOrange, size: 22),
                                    onPressed: onToggle,
                                  ),
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Divider(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          height: 20,
                          indent: 20,
                          endIndent: 20,
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Consumer2<SubscriptionService, ModuleConfigService>(
                            builder: (context, subSvc, modCfg, _) {
                              return Column(children: _buildSidebarItems(context));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    if (!isExpanded) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: primaryOrange.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: primaryOrange.withValues(alpha: 0.1), height: 1),
        ],
      ),
    );
  }

  List<Widget> _buildSidebarItems(BuildContext context) {
    List<Widget> items = [];
    final perm = PermissionService();

    Map<ModuleCategory, List<ModuleDef>> groupedModules = {};
    for (var module in AppModules.allModules) {
      if (perm.isVisible(module.id)) {
        groupedModules.putIfAbsent(module.category, () => []).add(module);
      }
    }

    final categories = [
      ModuleCategory.core,
      ModuleCategory.finance,
      ModuleCategory.support,
      ModuleCategory.hr,
      ModuleCategory.operations,
      ModuleCategory.entities,
      ModuleCategory.industries,
      ModuleCategory.extensions,
    ];

    final categoryNames = {
      ModuleCategory.core: 'الأنظمة الرئيسية',
      ModuleCategory.finance: 'المالية والمحاسبية',
      ModuleCategory.support: 'الدعم والرقابة',
      ModuleCategory.hr: 'الموارد البشرية',
      ModuleCategory.operations: 'العمليات والتجارة',
      ModuleCategory.entities: 'القطاعات والكيانات',
      ModuleCategory.industries: 'الصناعة والخدمات',
      ModuleCategory.extensions: 'الإضافات الذكية',
    };

    for (var cat in categories) {
      final mods = groupedModules[cat];
      if (mods != null && mods.isNotEmpty) {
        items.add(_buildSectionHeader(categoryNames[cat]!));
        for (var mod in mods) {
          if (!mod.showInSidebar) continue;
          items.add(_buildAnimatedNavItem(
            context,
            mod.index,
            mod.icon,
            mod.localizedName,
            moduleId: mod.id,
          ));
        }
      }
    }

    items.add(_buildSectionHeader('إدارة النظام'));
    items.add(_buildAnimatedNavItem(context, 72, Icons.folder_shared, 'مدير الملفات', moduleId: 'file_manager'));
    items.add(_buildAnimatedNavItem(context, 30, Icons.subscriptions, 'الاشتراكات', moduleId: 'subscriptions'));
    if (perm.isVisible('settings')) {
      items.add(_buildAnimatedNavItem(context, 12, Icons.settings, 'الإعدادات', moduleId: 'settings'));
    }

    items.add(const SizedBox(height: 20));
    items.add(_buildSyncSidebarItem(context));

    return items;
  }

  Widget _buildSyncSidebarItem(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<SyncService>(
      builder: (context, sync, _) {
        bool isSyncing = sync.status == SyncStatus.syncing;
        return Tooltip(
          message: isSyncing
              ? "جاري المزامنة..."
              : (sync.pendingCount > 0
                    ? "يوجد ${sync.pendingCount} سجل معلق"
                    : "تمت المزامنة"),
          child: GestureDetector(
            onTap: () => sync.syncNow(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSyncing
                    ? primaryOrange.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSyncing
                        ? Icons.sync
                        : (sync.status == SyncStatus.error
                              ? Icons.cloud_off
                              : Icons.cloud_done),
                    size: 20,
                    color: isSyncing
                        ? primaryOrange
                        : (sync.status == SyncStatus.error
                              ? Colors.redAccent
                              : (isDark ? Colors.white38 : Colors.black26)),
                  ),
                  if (sync.pendingCount > 0 && !isSyncing)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          "${sync.pendingCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    {String? moduleId}
  ) {
    bool isLocked = false;
    Color moduleColor = AppConstants.primaryOrange;
    
    if (moduleId != null) {
      isLocked = ModuleConfigService().isModuleLockedBySubscription(moduleId);
      if (isLocked && !ModuleConfigService().showLockedModules) return const SizedBox.shrink();
      
      final def = AppModules.allModules.cast<ModuleDef?>().firstWhere((m) => m?.id == moduleId, orElse: () => null);
      if (def != null) {
        moduleColor = def.color;
      }
    }

    bool isSelected = selectedIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLocked) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذه الوحدة غير متاحة في باقتك الحالية')));
             return;
          }
          onItemSelected(index);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            vertical: isSelected ? 4 : 2,
            horizontal: 4,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? moduleColor : Colors.transparent,
            borderRadius: BorderRadius.circular(
              isSelected ? 50 : 20,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: moduleColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isExpanded
                ? ClipRect(
                    key: const ValueKey('expanded_row'),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                icon,
                                size: isSelected ? 28 : 24,
                                color: isSelected ? Colors.black87 : (isDark ? moduleColor.withValues(alpha: 0.8) : moduleColor),
                              ),
                              if (isLocked)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Icon(Icons.lock, size: 12, color: isDark ? Colors.white : Colors.black87),
                                ),
                            ],
                          ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black54),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  )
                : Column(
                    key: const ValueKey('collapsed_col'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Positioned(
                              left: -12,
                              child: Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10),
                                  ],
                                ),
                              ),
                            ),
                          Icon(
                            icon,
                            size: isSelected ? 28 : 24,
                            color: isSelected ? Colors.black87 : (isDark ? moduleColor.withValues(alpha: 0.8) : moduleColor),
                          ),
                          if (isLocked)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Icon(Icons.lock, size: 12, color: isDark ? Colors.white : Colors.black87),
                            ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: isSelected && index != 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class DashboardOverviewWidget extends StatelessWidget {
  final bool isMobile;
  const DashboardOverviewWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppleEntrance(
            delay: const Duration(milliseconds: 100),
            child: MinimalistDashboardWidget(isMobile: isMobile),
          ),
        ),
      ],
    );
  }
}

class TopBarWidget extends StatefulWidget {
  final bool isMobile;
  final bool isHUD;
  final int? activeIndex;
  final ValueChanged<int?> onActiveIndexChanged;
  final ValueChanged<int> onNavigate;
  final VoidCallback onLogout;
  
  const TopBarWidget({
    super.key,
    this.isMobile = false,
    this.isHUD = false,
    required this.activeIndex,
    required this.onActiveIndexChanged,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  String selectedBranch = '';
  List<String> branches = [];
  String selectedCurrency = 'SAR';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedBranch.isEmpty) {
      selectedBranch = tr('branches.main');
      branches = [tr('branches.main')];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final contextData = await DatabaseHelper().getCurrentCompanyContext();
      final companyName = contextData['company_name'] ?? tr('branches.main');
      
      final costCenters = await DatabaseHelper().getCostCenters();
      final branchNames = costCenters.map((cc) => cc['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
      
      if (mounted) {
        setState(() {
          selectedBranch = companyName.toString();
          branches = [companyName.toString(), ...branchNames];
        });
      }
    } catch (_) {}
  }

  Widget _buildGlassButton(
    BuildContext context,
    Widget? child, {
    String? image,
    VoidCallback? onTap,
    double borderRadius = 100,
    Color? color,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
              decoration: BoxDecoration(
                color:
                    color ??
                    (isDark
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
                        : const Color(0xFFF2F2F7).withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: context.cardBorder.withValues(alpha: 0.08),
                ),
              ),
              child: image != null
                  ? Image.asset(image, width: 18, height: 18)
                  : child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularControlButton(
    BuildContext context,
    Widget child, {
    required VoidCallback onTap,
    required Color color,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: color.withValues(alpha: 0.2),
            child: InkWell(
              onTap: onTap,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowControls(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircularControlButton(
          context,
          const Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
          onTap: () => windowManager.close(),
          color: Colors.redAccent,
        ),
        const SizedBox(width: 8),
        _buildCircularControlButton(
          context,
          const Icon(Icons.crop_square_rounded, size: 12, color: Colors.white70),
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          color: Colors.white24,
        ),
        const SizedBox(width: 8),
        _buildCircularControlButton(
          context,
          const Icon(Icons.minimize_rounded, size: 12, color: Colors.white70),
          onTap: () => windowManager.minimize(),
          color: Colors.white24,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DragToMoveArea(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            textDirection: ui.TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<AuthState>(
                stream: AuthService().onAuthStateChange,
                builder: (context, snapshot) {
                  final user = snapshot.data?.session?.user ?? Supabase.instance.client.auth.currentUser;
                  final metadata = user?.userMetadata;
                  final String? avatarUrl = metadata?['avatar_url'] ?? metadata?['picture'];
                  final String displayName = metadata?['full_name']?.split(' ')[0] ?? metadata?['name']?.split(' ')[0] ?? tr('topbar.default_name');

                  return _buildExpandingMenu(
                    context,
                    index: 2,
                    width: 160,
                    baseWidthOverride: widget.isMobile ? 40 : 130,
                    headerChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: ui.TextDirection.ltr,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryOrange.withValues(alpha: 0.3), width: 1),
                          ),
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.white12,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null ? Icon(Icons.person, size: 12, color: context.textColor) : null,
                          ),
                        ),
                        if (!widget.isMobile) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: context.mutedText.withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
                    items: [
                      _buildMenuActionItem(
                        context,
                        icon: Icons.person_outline,
                        title: context.tr('topbar.profile'),
                        onTap: () {
                          widget.onActiveIndexChanged(null);
                          widget.onNavigate(100);
                        },
                      ),
                      _buildMenuActionItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: context.tr('topbar.account_settings'),
                        onTap: () {
                          widget.onActiveIndexChanged(null);
                          widget.onNavigate(12);
                        },
                      ),
                      const Divider(color: Colors.white10),
                      _buildMenuActionItem(
                        context,
                        icon: Icons.logout,
                        title: context.tr('topbar.logout'),
                        color: Colors.redAccent,
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              title: Row(
                                children: [
                                  const Icon(Icons.logout, color: Colors.redAccent),
                                  const SizedBox(width: 12),
                                  Text(ctx.tr('topbar.logout'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: Text(
                                ctx.tr('topbar.logout_confirm'),
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(ctx.tr('common.cancel'), style: const TextStyle(color: Colors.white54)),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: Text(ctx.tr('topbar.logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          
                          widget.onActiveIndexChanged(null);
                          
                          if (confirmed == true) {
                            await AuthService().signOut();
                            widget.onLogout();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 10),

              Consumer<NotificationService>(
                builder: (context, notifService, _) {
                  final activeNotifs = notifService.notifications;
                  return _buildExpandingMenu(
                    context,
                    index: 1,
                    width: 320,
                    headerChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              size: 20,
                              color: Colors.white70,
                            ),
                            if (activeNotifs.isNotEmpty)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: primaryOrange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.bgSurface, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    items: activeNotifs.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications_off_outlined, color: context.mutedText, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      tr('topbar.no_notifications'),
                                      style: TextStyle(color: context.mutedText, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ]
                        : activeNotifs.map((n) {
                            IconData icon;
                            Color color;
                            switch (n.type) {
                              case NotificationType.warning:
                                icon = Icons.warning_amber;
                                color = Colors.orangeAccent;
                                break;
                              case NotificationType.security:
                                icon = Icons.security;
                                color = Colors.redAccent;
                                break;
                              case NotificationType.success:
                                icon = Icons.check_circle_outline;
                                color = Colors.greenAccent;
                                break;
                              default:
                                icon = Icons.info_outline;
                                color = Colors.blueAccent;
                            }
                            return _buildNotificationItem(
                              context,
                              icon,
                              n.title,
                              n.message,
                              color,
                            );
                          }).toList(),
                  );
                },
              ),

              const SizedBox(width: 10),
              const LanguageToggleCapsule(),
              const SizedBox(width: 10),
              ThemeToggleCapsule(
                isDark: isDark,
                onToggle: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
              ),

              const Spacer(),

              if (!widget.isMobile) _buildBranchSwitcher(context),

              if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
                const SizedBox(width: 12),
                Container(height: 24, width: 1, color: Colors.white12),
                const SizedBox(width: 4),
                _buildWindowControls(context),
              ],
            ],
          ),

          if (!widget.isMobile)
            _buildGlassButton(
              context,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/image/logo icon.PNG', width: 20, height: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              onTap: () => widget.onNavigate(0),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchSwitcher(BuildContext context) {
    return _buildGlassButton(
      context,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 12, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  selectedBranch,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: context.glassMenu,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.cardBorder),
            ),
            offset: const Offset(0, 40),
            onSelected: (val) => setState(() => selectedBranch = val),
            itemBuilder: (context) => branches
                .map((b) => PopupMenuItem(
                      value: b,
                      child: Text(
                        b,
                        style: TextStyle(
                          color: b == selectedBranch ? primaryOrange : context.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('header.change_branch'),
                  style: TextStyle(
                    color: context.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: context.mutedText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandingMenu(
    BuildContext context, {
    required int index,
    double width = 200,
    String? label,
    IconData? icon,
    Widget? headerChild,
    required List<Widget> items,
    double? baseWidthOverride,
  }) {
    bool isExpanded = widget.activeIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isNotif = index == 1;

    double baseWidth = baseWidthOverride ?? (isNotif ? 40 : width);

    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, _) {
        final double blur = showBlur ? 50 : 0;
        return AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart,
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutQuart,
            width: isExpanded ? width : baseWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 100),
              boxShadow: [
                if (isExpanded)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 100),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  width: isExpanded ? width : baseWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNotif && !isExpanded ? 0 : 14,
                    vertical: isExpanded ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E).withValues(alpha: 0.5)
                        : const Color(0xFFF2F2F7).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(isExpanded ? 24 : 100),
                        border: Border.all(
                          color: context.cardBorder.withValues(
                            alpha: isExpanded ? 0.3 : 0.08,
                          ),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                widget.onActiveIndexChanged(isExpanded ? null : index),
                            child: SizedBox(
                              height: 32,
                              child: Center(
                                child: headerChild ??
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (label != null && (!isNotif || isExpanded))
                                          Text(
                                            label,
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 11,
                                              fontWeight: isExpanded
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        if (label != null && icon != null && (!isNotif || isExpanded))
                                          const SizedBox(width: 4),
                                        if (icon != null)
                                          Icon(
                                            icon,
                                            size: 16,
                                            color: isExpanded
                                                ? primaryOrange
                                                : context.mutedText,
                                          ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {},
                              behavior: HitTestBehavior.opaque,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: width,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 400,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: items,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ),
            ),
          );
      },
    );
  }

  Widget _buildMenuActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? primaryOrange),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(color: color ?? context.textColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    Color color,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(color: context.mutedText, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title, value, diff;
  final IconData icon;
  final bool isPrimary;
  final Color? iconColor;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.diff,
    required this.icon,
    this.isPrimary = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: perfShowShadows,
          builder: (context, showShadows, _) {
            final double blur = showBlur ? 40 : 0;
            final res = LayoutBuilder(
              builder: (context, constraints) {
                final bool compact = constraints.maxWidth < 120;
                return AppleEntrance(
                  delay: Duration(milliseconds: isPrimary ? 400 : 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(compact ? 8 : 12),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? primaryOrange
                              : context.cardSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isPrimary
                                ? Colors.transparent
                                : context.cardBorder,
                          ),
                          boxShadow: !showShadows
                              ? []
                              : [
                                  if (isPrimary)
                                    BoxShadow(
                                      color: primaryOrange.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (iconColor ?? primaryOrange)
                                        .withValues(
                                          alpha: isPrimary ? 0.25 : 0.15,
                                        ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color:
                                        iconColor ??
                                        (isPrimary
                                            ? Colors.black87
                                            : primaryOrange),
                                    size: compact ? 16 : 20,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      size: 12,
                                      color: isPrimary
                                          ? Colors.black54
                                          : Colors.greenAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      diff,
                                      style: TextStyle(
                                        color: isPrimary
                                            ? Colors.black54
                                            : Colors.greenAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: isPrimary
                                        ? Colors.black54
                                        : context.mutedText,
                                    fontSize: compact ? 9 : 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: compact ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: isPrimary
                                        ? Colors.black87
                                        : context.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
            return res;
          },
        );
      },
    );
  }
}

class ChartsRowWidget extends StatefulWidget {
  final bool isMobile;
  const ChartsRowWidget({super.key, this.isMobile = false});

  @override
  State<ChartsRowWidget> createState() => _ChartsRowWidgetState();
}

class _ChartsRowWidgetState extends State<ChartsRowWidget> {
  int _activeBarIndex = 3;

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Column(
        children: [
          SizedBox(height: 250, child: _buildBarChart()),
          const SizedBox(height: 12),
          SizedBox(height: 250, child: _buildHeatmapChart()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 6, child: _buildBarChart()),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildHeatmapChart()),
      ],
    );
  }

  Widget _buildBarChart() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6A11CB,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bar_chart,
                          color: Color(0xFF6A11CB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "معدل الأرباح",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: context.cardBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryOrange,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: primaryOrange.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            tr('dashboard_labels.yearly'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            tr('dashboard_labels.monthly'),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildCustomBar(
                      0.4,
                      tr('months.jan'),
                      "1200",
                      _activeBarIndex == 0,
                      0,
                    ),
                    _buildCustomBar(
                      0.6,
                      tr('months.feb'),
                      "1800",
                      _activeBarIndex == 1,
                      1,
                    ),
                    _buildCustomBar(
                      0.5,
                      tr('months.mar'),
                      "1500",
                      _activeBarIndex == 2,
                      2,
                    ),
                    _buildCustomBar(
                      0.95,
                      tr('months.apr'),
                      "2800",
                      _activeBarIndex == 3,
                      3,
                    ),
                    _buildCustomBar(
                      0.7,
                      tr('months.may'),
                      "2100",
                      _activeBarIndex == 4,
                      4,
                    ),
                    _buildCustomBar(
                      0.8,
                      tr('months.jun'),
                      "2400",
                      _activeBarIndex == 5,
                      5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapChart() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: context.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00F260,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF00F260),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "نشاط فروع النظام",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.more_horiz, color: context.mutedText, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "2pm",
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                        Text(
                          "12pm",
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                        Text(
                          "10am",
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                        Text(
                          "8am",
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.8,
                            ),
                        itemCount: 49,
                        itemBuilder: (context, index) {
                          bool isActive = index % 5 == 0 || index % 7 == 2;
                          bool isPeak =
                              index == 16 || index == 24 || index == 32;
                          Color blockColor = context.textColor.withValues(
                            alpha: 0.05,
                          );
                          if (isPeak) {
                            blockColor = primaryOrange;
                          } else if (isActive)
                            blockColor = primaryOrange.withValues(alpha: 0.35);

                          return AppleEntrance(
                            delay: Duration(milliseconds: 400 + (index * 8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Tooltip(
                                message: isPeak
                                    ? "نشاط عالي جداً"
                                    : (isActive ? "نشاط متوسط" : "نشاط منخفض"),
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم تحديد فترة زمنية'),
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    color: blockColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    "منخفض",
                    context.textColor.withValues(alpha: 0.05),
                  ),
                  _buildLegendItem(
                    "متوسط",
                    primaryOrange.withValues(alpha: 0.35),
                  ),
                  _buildLegendItem("عالي", primaryOrange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBar(
    double percentage,
    String label,
    String value, [
    bool isActive = false,
    int index = 0,
  ]) {
    Color barColor = isActive
        ? primaryOrange
        : primaryOrange.withValues(alpha: 0.2);
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeBarIndex = index;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isActive)
              AppleEntrance(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: primaryOrange,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AppleEntrance(
                delay: Duration(milliseconds: 400 + (index * 120)),
                child: FractionallySizedBox(
                  heightFactor: percentage,
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    width: isActive ? 64 : 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [barColor, barColor.withValues(alpha: 0.5)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: primaryOrange.withValues(alpha: 0.45),
                            blurRadius: 25,
                            spreadRadius: -2,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isActive ? context.textColor : context.mutedText,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                fontFamily: 'Tajawal',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text.tr(),
          style: TextStyle(fontSize: 11, color: context.mutedText),
        ),
      ],
    );
  }
}

class MessagesWidget extends StatelessWidget {
  const MessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, color: primaryOrange, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    tr('ai.smart_assistant'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black87, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GlassCapsule(
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: context.mutedText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('ai.placeholder'),
                    style: TextStyle(color: context.mutedText, fontSize: 15),
                  ),
                ),
                const Icon(Icons.mic, color: primaryOrange, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setInternalState) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(15, (index) {
                      double height =
                          10 +
                          (15 *
                              (0.5 +
                                  0.5 * (index % 2 == 0 ? value : 1 - value)));
                      return Container(
                        width: 3,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: primaryOrange.withValues(
                            alpha: 0.2 + (0.3 * value),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  );
                },
                onEnd: () => setInternalState(() {}), // Trigger loop
              );
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildMessageItem(
                  context,
                  tr('ai.messages.accounting_name'),
                  tr('ai.messages.accounting_preview'),
                  "١٢:٠٠ م",
                  Icons.insights,
                  true,
                ),
                const SizedBox(height: 18),
                _buildMessageItem(
                  context,
                  tr('ai.messages.tax_name'),
                  tr('ai.messages.tax_preview'),
                  "أمس",
                  Icons.warning_amber,
                  false,
                ),
                const SizedBox(height: 18),
                _buildMessageItem(
                  context,
                  tr('ai.messages.audit_name'),
                  tr('ai.messages.audit_preview'),
                  "٢ سبتمبر",
                  Icons.fact_check,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    String name,
    String preview,
    String time,
    IconData icon,
    bool hasBadge,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryOrange, size: 22),
              ),
              if (hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.mutedText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrbBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final Color orangeColor;
  final Color goldColor;

  OrbBackgroundPainter({
    required this.animationValue,
    required this.isDark,
    required this.orangeColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right Orb (Primary)
    _drawOrb(
      canvas,
      Offset(
        size.width * (0.85 + (animationValue * 0.1)),
        size.height * (0.15 + (animationValue * 0.15)),
      ),
      size.width * 0.7,
      isDark 
        ? orangeColor.withValues(alpha: 0.18) 
        : orangeColor.withValues(alpha: 0.25), // ☀️ Higher clarity in light mode
    );

    // Bottom-left Orb (Accent)
    _drawOrb(
      canvas,
      Offset(
        size.width * (0.15 - (animationValue * 0.12)),
        size.height * (0.85 + (animationValue * 0.12)),
      ),
      size.width * 0.6,
      isDark 
        ? goldColor.withValues(alpha: 0.12) 
        : goldColor.withValues(alpha: 0.18), // ☀️ More visible gold
    );

    // Middle Soft Orb (Atmosphere - Cool)
    _drawOrb(
      canvas,
      Offset(
        size.width * 0.4,
        size.height * 0.3,
      ),
      size.width * 0.9,
      isDark 
        ? const Color(0xFF6A11CB).withValues(alpha: 0.08) 
        : const Color(0xFF5AC8FA).withValues(alpha: 0.12), // ☀️ Professional Blue/Cyan
    );

    // 🌟 NEW: Bottom-right Deep Orb (Stability)
    _drawOrb(
      canvas,
      Offset(
        size.width * (0.7 + (animationValue * 0.05)),
        size.height * (0.8 - (animationValue * 0.1)),
      ),
      size.width * 0.5,
      isDark 
        ? const Color(0xFF1E1E24).withValues(alpha: 0.1) 
        : const Color(0xFFE5E5EA).withValues(alpha: 0.3),
    );
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant OrbBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isDark != isDark;
  }
}
