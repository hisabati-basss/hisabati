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
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hisabati_app/services/module_config_service.dart';
import 'package:hisabati_app/services/industry_provider.dart';
import 'package:hisabati_app/services/ai_chat_controller.dart';
import 'package:hisabati_app/services/sync_service.dart';
import 'package:hisabati_app/services/notification_service.dart';
import 'package:hisabati_app/services/performance_manager.dart';
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
import 'package:hisabati_app/screens/login_screen.dart';
import 'package:hisabati_app/screens/affiliate_screen.dart';
import 'package:hisabati_app/screens/inventory_screen.dart';
import 'package:hisabati_app/screens/projects_screen.dart';
import 'package:hisabati_app/screens/hub_screen.dart';
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
import 'screens/cloud_inbox_screen.dart';
import 'screens/budget_setup_screen.dart';
import 'screens/budget_monitoring_screen.dart';
import 'screens/bi_dashboard_screen.dart';
import 'screens/manufacturing_screen.dart';
import 'screens/cheques_screen.dart';
import 'screens/custody_screen.dart';
import 'screens/security_audit_screen.dart';
import 'screens/real_estate_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/bom_setup_screen.dart';
import 'screens/credit_note_screen.dart';
import 'screens/debit_note_screen.dart';
import 'screens/purchase_order_screen.dart';
import 'screens/recurring_invoices_screen.dart';
import 'screens/aging_report_screen.dart';
import 'screens/fiscal_year_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  // Initialize Supabase (v2.x uses PKCE by default for optimal Desktop/Web OAuth)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Module Config (Fixes repeating onboarding)
  await ModuleConfigService().init();

  // Initialize EasyLocalization (Multi-language)
  await EasyLocalization.ensureInitialized();

  // Perform Hardware Detection & Performance Optimization (Smart Hub)
  await PerformanceManager.optimizeForDevice();

  // Initialize HR Pro background checks
  HRProService().runAutoChecks().catchError((e) => debugPrint("HR Pro Check Error: $e"));

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

  @override
  void initState() {
    super.initState();
    _checkOnboarding();

    // 🛡️ Auto-Entry Booster: Re-check onboarding whenever auth state changes
    AuthService().onAuthStateChange.listen((data) {
      if (data.session != null && !_isOnboarded) {
        _checkOnboarding();
      }
      // 🚪 Reset dev bypass on sign-out so login screen shows again
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
            final bool isLoggedIn = session != null || _devBypassLogin;

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
                                          onLogout: () => setState(() => _devBypassLogin = false),
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
    
    // 🛡️ Phase 14: Security & RBAC Initialization
    final user = AuthService().currentUser;
    if (user != null) {
      final roleStr = user.userMetadata?['role']?.toString() ?? 'admin';
      UserRole role = UserRole.admin;
      try {
        role = UserRole.values.firstWhere((e) => e.name == roleStr);
      } catch (_) {
        role = UserRole.admin; // Default to admin for now
      }
      PermissionService().setRole(role);
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

    // Check if we need to show the Smart Performance Alert
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
            _isAiCapsuleExpanded = false; // Auto-collapse HUD
          });
          aiController.clearMessages(); // Hide conversation bubbles
        }
      };
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _globalAiController.dispose();
    super.dispose();
  }

  Widget _buildCurrentScreen(bool isMobile) {
    switch (_selectedIndex) {
      case 0:
        return AiHomeScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return CEODashboardScreen(isMobile: isMobile);
      case 40:
        final uMeta = AuthService().currentUser?.userMetadata ?? {};
        final cName = uMeta['full_name'] ?? 'مدير النظام';
        final cTitle = uMeta['job_title'] ?? 'إدارة عليا';
        return EmployeeChatScreen(
          currentUserId: AuthService().currentUser?.id ?? 'EMP_LOCAL',
          currentUserName: '$cName - $cTitle',
        );
      case 2:
        return const AccountingOperationsScreen();
      case 3:
        return const TaxesScreen();
      case 4:
        return const HrScreen();
      case 5:
        return const AuditingScreen();
      case 6:
        return const FeasibilityStudyScreen();
      case 7:
        return const UsersScreen();
      case 8:
        return const AffiliateScreen();
      case 9:
        return const FinancialReportsScreen();
      case 10:
        return const InventoryScreen();
      case 11:
        return const ProjectsScreen();
      case 12:
        return SettingsScreen(onLogout: widget.onLogout);
      case 13:
        return const CreditStatementScreen();
      case 14:
        return const AssetsScreen();
      case 15:
        return const InternalHubScreen();
      case 16:
        return const PurchaseInvoiceScreen();
      case 17:
        return const SuppliersDirectoryScreen();
      case 18:
        return const WalletScreen();
      case 19:
        return WarehouseScreen(isMobile: isMobile);
      case 20:
        return CloudInboxScreen(isMobile: isMobile);
      case 21:
        return PosScreen(isMobile: isMobile);
      case 22:
        return const BudgetSetupScreen();
      case 23:
        return const BudgetMonitoringScreen();
      case 24:
        return const BIDashboardScreen();
      case 25:
        return const ManufacturingScreen();
      case 26:
        return const BomSetupScreen();
      case 27:
        return const ChequesScreen();
      case 28:
        return CustodyScreen(isMobile: isMobile);
      case 29:
        return const SecurityAuditScreen();
      case 31:
        return const RealEstateScreen();
      case 32:
        return const InvestmentsScreen();
      case 33:
        return const CommercialHubScreen();
      case 35:
        return const TrialBalanceScreen();
      case 36:
        return const MaintenanceScreen();
      case 37:
        return const SalesCommissionsScreen();
      case 38:
        return const ExpiryDashboardScreen();
      case 41:
        return const CreditNoteScreen();
      case 42:
        return const DebitNoteScreen();
      case 43:
        return const PurchaseOrderScreen();
      case 44:
        return const RecurringInvoicesScreen();
      case 45:
        return const AgingReportScreen();
      case 46:
        return const FiscalYearScreen();
      case 100:
        return HubScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      default:
        return AiHomeScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopMenuBar(
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
                          orangeColor: primaryOrange,
                          goldColor: accentGold,
                          purpleColor: const Color(0xFF6A11CB),
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
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOutCubic,
                                      width: _isSidebarExpanded ? 240 : 90,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 75),
                                          Expanded(
                                            child: SidebarWidget(
                                              selectedIndex: _selectedIndex,
                                              isExpanded: _isSidebarExpanded,
                                              onToggle: () {
                                                setState(() {
                                                  _isSidebarExpanded = !_isSidebarExpanded;
                                                });
                                              },
                                              onItemSelected: (index) {
                                                setState(
                                                  () => _selectedIndex = index,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
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
                                            90,
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

                      // 🛡️ DISMISS LAYER: sits BETWEEN content and TopBar
                      // Only appears when menu is open. Clicking it closes the menu.
                      // TopBar sits ABOVE this, so menu item taps work perfectly.
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
                        bottom: _activeHeaderMenuIndex != null ? 0 : null,
                        child: AppleEntrance(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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

                      // Phase 4: Floating Notification Overlay (CEO Alerts)
                      _buildNotificationOverlay(),
                    ],
                  ),
                ),
              ],
            );
        },
      ),
    ),
    );
  }

  Widget _buildNotificationOverlay() {
    return ValueListenableBuilder<AppNotification?>(
      valueListenable: NotificationService().latestAlert,
      builder: (context, alert, child) {
        if (alert == null) return const SizedBox.shrink();

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
                      NotificationService().clearAlert();
                      setState(
                        () => _selectedIndex = 29,
                      ); // tr('actions.goto_security')
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3),
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
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              alert.type == NotificationType.security
                                  ? Icons.security
                                  : Icons.info,
                              color: Colors.redAccent,
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

                final robotLeft = aiController.messages.isEmpty
                    ? (capsuleCenter - 90)
                    : (capsuleCenter - 298);
                final chatLeft = robotLeft + 196;

                final isExpanded = isAiPage || _isAiCapsuleExpanded;
                
                // Reverted to sitting above the Capsule->Suggestions column
                // Baseline bottom is back to 20. Total column height is ~260.
                final robotBottomFinal = kb + (isAiPage ? 330 : (isExpanded ? 110 : 85));
                final chatBottomFinal = kb + (isAiPage ? 320 : (isExpanded ? 100 : 75));
                final robotSizeFinal = isAiPage ? 180.0 : 90.0; // Shrink robot on sub-pages

                double robotLeftFinal;
                if (isAiPage) {
                  robotLeftFinal = aiController.messages.isEmpty
                      ? (capsuleCenter - 90)
                      : (capsuleCenter - 298);
                } else {
                  // Beside capsule on wide screens, centered otherwise
                  if (sw > 1000) {
                     robotLeftFinal = capsuleCenter - 620; 
                  } else {
                     robotLeftFinal = capsuleCenter - 90;
                  }
                }

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutQuart,
                      bottom: robotBottomFinal,
                      left: robotLeftFinal,
                      child: RobotAvatar(
                        state: aiController.robotState,
                        size: robotSizeFinal,
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutQuart,
                      bottom: chatBottomFinal,
                      left: aiController.messages.isEmpty ? sw + 600 : chatLeft,
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
                      ((_selectedIndex == 0 || _isAiCapsuleExpanded) ? 20 : 10),
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
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 800),
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
                    1,
                    Icons.document_scanner,
                    tr('sidebar.purchases'),
                  ),
                if (PermissionService().isVisible('taxes'))
                  _buildAnimatedNavItem(
                    2,
                    Icons.receipt_long,
                    tr('sidebar.taxes'),
                  ),
                if (PermissionService().isVisible('hr'))
                  _buildAnimatedNavItem(3, Icons.people, tr('sidebar.hr')),
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
            size: 28, // Improved for better visibility on tablets
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryOrange : context.mutedText,
              fontSize: 12, // Increased from 10
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
        final double blur = showBlur ? 40 : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: Column(
            children: [
              // 🤖 AI Floating Orb tightly coupled to Capsule
              GestureDetector(
                onTap: () => onItemSelected(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  width: isExpanded ? 220 : 76,
                  height: 76,
                  margin: const EdgeInsets.only(top: 8, bottom: 24),
                  decoration: BoxDecoration(
                    color: selectedIndex == 0
                        ? primaryOrange
                        : (isDark ? Colors.white10 : Colors.black12),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      if (selectedIndex == 0)
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                    ],
                    border: Border.all(
                      color: selectedIndex == 0
                          ? primaryOrange.withValues(alpha: 0.8)
                          : context.cardBorder.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: isExpanded ? 24 : 0),
                        child: Icon(
                          Icons.auto_awesome,
                          color: selectedIndex == 0
                              ? Colors.black87
                              : (isDark ? Colors.white70 : Colors.black87),
                          size: 28,
                        ),
                      ),
                      if (isExpanded)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AnimatedOpacity(
                              opacity: isExpanded ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                "الذكاء Мالي (HBASSS)",
                                style: TextStyle(
                                  color: selectedIndex == 0 ? Colors.black87 : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      width: isExpanded ? 220 : 76, // Apple-style fluid expansion while maintaining capsule
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        border: Border.all(
                          color: context.cardBorder.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Toggle and Search Area
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24 : 0),
                            child: isExpanded
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: TextField(
                                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: "بحث...",
                                              hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)),
                                              prefixIcon: const Icon(Icons.search, size: 18, color: AppConstants.primaryOrange),
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.keyboard_double_arrow_right, color: Colors.white54, size: 20),
                                        onPressed: onToggle,
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.menu, color: Colors.white54),
                                    onPressed: onToggle,
                                  ),
                          ),
                          if (isExpanded) const Divider(color: Colors.white12, height: 24, indent: 24, endIndent: 24),
                          
                          // Scrollable Items
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              child: Column(children: _buildSidebarItems(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    final cfg = ModuleConfigService();
    List<Widget> items = [];

    // 1️⃣ MAIN / الرئيسية
    items.add(_buildSectionHeader(tr('sidebar.group.main')));
    items.add(
      _buildAnimatedNavItem(
        context,
        1,
        Icons.dashboard_rounded,
        tr('sidebar.dashboard'),
      ),
    );

    // 2️⃣ FINANCE & ACCOUNTING / المالية والمحاسبة
    if (cfg.isModuleActive('accounting')) {
      items.add(_buildSectionHeader(tr('sidebar.group.finance')));
      items.add(
        _buildAnimatedNavItem(context, 2, Icons.account_balance_wallet, tr('sidebar.accounts')),
      );
      items.add(
        _buildAnimatedNavItem(context, 3, Icons.calculate, tr('sidebar.taxes_short')),
      );
      items.add(
        _buildAnimatedNavItem(context, 5, Icons.fact_check, tr('sidebar.financial_audit')),
      );
      items.add(
        _buildAnimatedNavItem(context, 32, Icons.trending_up, tr('sidebar.investments')),
      );
      if (cfg.isModuleActive('financial_reports')) {
        items.add(
          _buildAnimatedNavItem(context, 9, Icons.bar_chart, tr('sidebar.financial_reports')),
        );
      }
      if (cfg.isModuleActive('trial_balance')) {
        items.add(
          _buildAnimatedNavItem(context, 35, Icons.balance, tr('sidebar.trial_balance')),
        );
      }
    }

    // 3️⃣ SALES & PURCHASES / المبيعات والمشتريات
    if (cfg.isModuleActive('hub_commercial') || cfg.isModuleActive('sales_purchase') || cfg.isModuleActive('purchases')) {
      items.add(_buildSectionHeader(tr('sidebar.group.sales')));
      if (cfg.isModuleActive('hub_commercial')) {
        items.add(_buildAnimatedNavItem(context, 33, Icons.storefront, tr('sidebar.commercial')));
        items.add(_buildAnimatedNavItem(context, 21, Icons.point_of_sale, tr('sidebar.pos')));
      }
      if (cfg.isModuleActive('purchases')) {
        items.add(_buildAnimatedNavItem(context, 16, Icons.shopping_basket, tr('sidebar.purchases')));
        items.add(_buildAnimatedNavItem(context, 17, Icons.business, tr('sidebar.suppliers')));
        items.add(_buildAnimatedNavItem(context, 43, Icons.shopping_cart_checkout, tr('sidebar.purchase_orders')));
      }
      if (cfg.isModuleActive('accounting')) {
        items.add(_buildAnimatedNavItem(context, 41, Icons.assignment_return, tr('sidebar.credit_returns')));
        items.add(_buildAnimatedNavItem(context, 42, Icons.outbox_rounded, tr('sidebar.debit_returns')));
        items.add(_buildAnimatedNavItem(context, 44, Icons.autorenew, tr('sidebar.recurring_invoices')));
        items.add(_buildAnimatedNavItem(context, 45, Icons.timer_outlined, tr('sidebar.aging_report')));
      }
    }

    // 4️⃣ INVENTORY & WAREHOUSES / المخازن والمستودعات
    if (cfg.isModuleActive('inventory') || cfg.isModuleActive('erp_management')) {
      items.add(_buildSectionHeader(tr('sidebar.group.inventory')));
      items.add(_buildAnimatedNavItem(context, 10, Icons.inventory_2, tr('sidebar.inventory')));
      items.add(_buildAnimatedNavItem(context, 19, Icons.warehouse, tr('sidebar.warehouses')));
      if (cfg.isModuleActive('expiry_control') || cfg.isModuleActive('expiry')) {
        items.add(_buildAnimatedNavItem(context, 38, Icons.event_busy, tr('sidebar.expiry')));
      }
    }

    // 5️⃣ HUMAN RESOURCES / الموارد البشرية
    if (cfg.isModuleActive('hr') || cfg.isModuleActive('hr_payroll')) {
      items.add(_buildSectionHeader(tr('sidebar.group.hr')));
      items.add(_buildAnimatedNavItem(context, 4, Icons.people, tr('sidebar.hr')));
      items.add(_buildAnimatedNavItem(context, 40, Icons.forum, tr('sidebar.team_chat')));
    }

    // 6️⃣ OPERATIONS / إدارة العمليات
    if (cfg.isModuleActive('projects') || cfg.isModuleActive('budgeting') || cfg.isModuleActive('real_estate') || cfg.isModuleActive('maintenance')) {
      items.add(_buildSectionHeader(tr('sidebar.group.operations')));
      if (cfg.isModuleActive('projects')) {
        items.add(_buildAnimatedNavItem(context, 11, Icons.assignment, tr('sidebar.projects')));
      }
      if (cfg.isModuleActive('budgeting')) {
        items.add(_buildAnimatedNavItem(context, 22, Icons.pie_chart, tr('sidebar.budget_setup')));
        items.add(_buildAnimatedNavItem(context, 23, Icons.insights, tr('sidebar.budget_monitor')));
      }
      if (cfg.isModuleActive('real_estate')) {
        items.add(_buildAnimatedNavItem(context, 31, Icons.domain, tr('sidebar.real_estate')));
      }
      if (cfg.isModuleActive('maintenance')) {
        items.add(_buildAnimatedNavItem(context, 36, Icons.build, tr('sidebar.maintenance')));
      }
    }

    // 7️⃣ PRODUCTION & MANUFACTURING / الإنتاج والتصنيع
    if (cfg.isModuleActive('hub_industrial')) {
      items.add(_buildSectionHeader(tr('sidebar.group.manufacturing')));
      items.add(_buildAnimatedNavItem(context, 15, Icons.hub, tr('sidebar.industrial_hub')));
      items.add(_buildAnimatedNavItem(context, 25, Icons.precision_manufacturing, tr('sidebar.manufacturing')));
      items.add(_buildAnimatedNavItem(context, 26, Icons.build_circle, tr('sidebar.bom')));
    }

    // 8️⃣ ADVANCED FINANCE / المالية المتقدمة
    if (cfg.isModuleActive('accounting')) {
      items.add(_buildSectionHeader(tr('sidebar.group.advanced_finance')));
      items.add(_buildAnimatedNavItem(context, 18, Icons.account_balance, tr('sidebar.banks_vaults')));
      items.add(_buildAnimatedNavItem(context, 27, Icons.payments, tr('sidebar.cheques')));
      if (cfg.isModuleActive('sales_commissions')) {
        items.add(_buildAnimatedNavItem(context, 37, Icons.monetization_on, tr('sidebar.commissions')));
      }
      if (cfg.isModuleActive('accounting')) {
        items.add(_buildAnimatedNavItem(context, 6, Icons.analytics, tr('sidebar.feasibility')));
        items.add(_buildAnimatedNavItem(context, 46, Icons.calendar_month, tr('sidebar.fiscal_year')));
      }
    }

    // 9️⃣ SYSTEM / النظام
    items.add(_buildSectionHeader(tr('sidebar.group.system')));
    if (cfg.isModuleActive('cloud_inbox') || cfg.isModuleActive('purchases')) {
      items.add(_buildAnimatedNavItem(context, 20, Icons.cloud_queue, tr('sidebar.cloud_inbox')));
    }
    if (cfg.isModuleActive('auditing')) {
      items.add(_buildAnimatedNavItem(context, 29, Icons.security, tr('sidebar.security')));
    }
    items.add(_buildAnimatedNavItem(context, 100, Icons.apps, tr('sidebar.hub')));
    items.add(_buildAnimatedNavItem(context, 12, Icons.settings, tr('sidebar.settings_general')));

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  if (sync.pendingCount > 0 && !isSyncing) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${sync.pendingCount}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
    String tooltip,
  ) {
    bool isSelected = selectedIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            vertical: isSelected ? 4 : 2,
            horizontal: 4,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(
              isSelected ? 50 : 20,
            ), // Graceful transition avoiding Shape Box exception
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: primaryOrange.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isExpanded
                ? Row(
                    key: const ValueKey('expanded_row'),
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        size: isSelected ? 28 : 24,
                        color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tooltip,
                          style: TextStyle(
                            color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black54),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('collapsed_col'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: isSelected ? 28 : 24, // Optimized size for clarity
                        color: isSelected
                            ? Colors.black87
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),

                      // 🍎 Apple-style Dynamic Label Visibility on selection
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: isSelected && index != 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  tooltip,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10, // Increased for readability
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
  String selectedBranch = tr('branches.riyadh');
  final List<String> branches = [
    tr('branches.riyadh'),
    tr('branches.jeddah'),
    tr('branches.dubai'),
    tr('branches.cairo'),
    tr('branches.london'),
    tr('branches.new_york'),
    tr('branches.paris'),
    tr('branches.tokyo'),
    tr('branches.beijing'),
  ];
  String selectedCurrency = 'SAR';

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    color ??
                    (isDark
                        ? const Color(0xFF1A1A2E).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.70)),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: context.cardBorder.withValues(alpha: 0.15),
                ),
              ),
              child: image != null
                  ? Image.asset(image, width: 24, height: 24)
                  : child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      textDirection: ui.TextDirection.ltr, // Force Profile to far LEFT and Branch to far RIGHT
      children: [
        // 1. 👤 Profile Menu on the FAR LEFT
        StreamBuilder<AuthState>(
          stream: AuthService().onAuthStateChange,
          builder: (context, snapshot) {
            final user = snapshot.data?.session?.user ??
                Supabase.instance.client.auth.currentUser;
            final metadata = user?.userMetadata;
            final String? avatarUrl =
                metadata?['avatar_url'] ?? metadata?['picture'];
            final String displayName =
                metadata?['full_name']?.split(' ')[0] ??
                metadata?['name']?.split(' ')[0] ??
                'المدير';

            return _buildExpandingMenu(
              context,
              index: 2,
              width: 180,
              headerChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white12,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 14,
                            color: context.textColor,
                          )
                        : null,
                  ),
                  if (!widget.isMobile) ...[
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                  title: 'الملف الشخصي',
                  onTap: () {
                    widget.onActiveIndexChanged(null);
                    widget.onNavigate(100);
                  },
                ),
                _buildMenuActionItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'إعدادات الحساب',
                  onTap: () {
                    widget.onActiveIndexChanged(null);
                    widget.onNavigate(12);
                  },
                ),
                const Divider(color: Colors.white10),
                _buildMenuActionItem(
                  context,
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
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
                        title: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent),
                            SizedBox(width: 12),
                            Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: const Text(
                          'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟\nسيتم إغلاق جلستك وستحتاج لتسجيل الدخول مرة أخرى.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
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
        
        const SizedBox(width: 12),

        // 2. 🔔 Real Notifications List
        Consumer<NotificationService>(
          builder: (context, notifService, _) {
            final activeNotifs = notifService.notifications;
            return _buildExpandingMenu(
              context,
              index: 1,
              width: 320,
              headerChild: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.notifications_none,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                  if (activeNotifs.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.bgSurface, width: 2),
                        ),
                      ),
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
                                "لا توجد تنبيهات حالياً",
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

        const SizedBox(width: 12),

        // 3. 🛡️ Security Simulation
        _buildGlassButton(
          context,
          const Icon(Icons.security_outlined, size: 18, color: Colors.redAccent),
          borderRadius: 100,
          color: Colors.redAccent.withValues(alpha: 0.1),
          onTap: () => DatabaseHelper().logSecurityAlert(
            'تنبيه أمني فوري',
            'تم رصد نشاط دخول مريب من عنوان بروتوكول جديد.',
            isCritical: true,
          ),
        ),

        const SizedBox(width: 12),
        const LanguageToggleCapsule(),
        const SizedBox(width: 12),
        ThemeToggleCapsule(
          isDark: isDark,
          onToggle: () => themeNotifier.value = isDark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),

        const Spacer(),

        // 4. 🏢 Branch Switcher on the RIGHT
        if (!widget.isMobile)
          _buildGlassButton(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 15,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedBranch,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                      .map(
                        (b) => PopupMenuItem(
                          value: b,
                          child: Text(
                            b,
                            style: TextStyle(
                              color: b == selectedBranch
                                  ? primaryOrange
                                  : context.textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('header.change_branch'),
                        style: TextStyle(
                          color: context.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: context.mutedText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
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
  }) {
    bool isExpanded = widget.activeIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isNotif = index == 1;

    double baseWidth = isNotif ? 44 : width;
    double baseHeight = 44;

    return ValueListenableBuilder<bool>(
      valueListenable: perfShowBlur,
      builder: (context, showBlur, _) {
        final double blur = showBlur ? 50 : 0;
        final res = SizedBox(
          width: baseWidth,
          height: baseHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutQuart,
                  width: isNotif ? (isExpanded ? width : 44) : width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      isNotif
                          ? (isExpanded ? 24 : 100)
                          : (isExpanded ? 24 : 100),
                    ),
                    boxShadow: [
                      if (isExpanded)
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.15,
                          ),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      isNotif
                          ? (isExpanded ? 24 : 100)
                          : (isExpanded ? 24 : 100),
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNotif && !isExpanded ? 0 : 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(
                                  alpha: isExpanded ? 0.15 : 0.1,
                                )
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            isNotif
                                ? (isExpanded ? 24 : 100)
                                : (isExpanded ? 24 : 100),
                          ),
                          border: Border.all(
                            color: context.cardBorder.withValues(
                              alpha: isExpanded ? 0.3 : 0.15,
                            ),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🎯 Only the HEADER is tappable to toggle menu open/close
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  widget.onActiveIndexChanged(isExpanded ? null : index),
                              child: Container(
                                height: 32,
                                alignment: Alignment.center,
                                child:
                                    headerChild ??
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (label != null &&
                                            (!isNotif || isExpanded))
                                          Text(
                                            label,
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 13,
                                              fontWeight: isExpanded
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        if (label != null &&
                                            icon != null &&
                                            (!isNotif || isExpanded))
                                          const SizedBox(width: 4),
                                        if (icon != null)
                                          Icon(
                                            icon,
                                            size: 18,
                                            color: isExpanded
                                                ? primaryOrange
                                                : context.mutedText,
                                          ),
                                      ],
                                    ),
                              ),
                            ),
                            // 🎯 Menu items are separate — absorb taps so background closer doesn't fire
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {}, // Absorb tap — don't let it reach the background closer
                                behavior: HitTestBehavior.opaque,
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
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return res;
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
          // Animated Waveform simulation
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
  final Color orangeColor;
  final Color goldColor;
  final Color purpleColor;

  OrbBackgroundPainter({
    required this.animationValue,
    required this.orangeColor,
    required this.goldColor,
    required this.purpleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrb(
      canvas,
      Offset(
        size.width - 250 + (animationValue * 300),
        -50 + (animationValue * 200),
      ),
      400, // Increased radius
      orangeColor.withValues(alpha: 0.35), // Increased alpha
    );
    _drawOrb(
      canvas,
      Offset(
        -100 + ((1 - animationValue) * 350),
        size.height - 50 + (animationValue * 250),
      ),
      350, // Increased radius
      goldColor.withValues(alpha: 0.3), // Increased alpha
    );
    _drawOrb(
      canvas,
      Offset(300 + (animationValue * 300), 550),
      325, // Increased radius
      orangeColor.withValues(alpha: 0.25), // Increased alpha
    );
    _drawOrb(
      canvas,
      Offset(
        size.width - 100 + ((1 - animationValue) * 250),
        size.height - 250,
      ),
      275, // Increased radius
      purpleColor.withValues(alpha: 0.2), // Increased alpha
    );
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant OrbBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
