import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';
import '../services/ai_chat_controller.dart';

// --- ADVANCED SUGGESTIONS PANEL (REDESIGNED) ---
class AdvancedSuggestionsPanel extends StatefulWidget {
  final Function(int) onSuggestionTap;
  const AdvancedSuggestionsPanel({super.key, required this.onSuggestionTap});

  @override
  State<AdvancedSuggestionsPanel> createState() => _AdvancedSuggestionsPanelState();
}

class _AdvancedSuggestionsPanelState extends State<AdvancedSuggestionsPanel> with SingleTickerProviderStateMixin {
  int _selectedCategory = -1;
  late List<Map<String, dynamic>> _categories;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize categories here instead of didChangeDependencies for cleaner logic
    _categories = [
      {'name': 'المحاسبة', 'icon': Icons.account_balance_wallet_rounded, 'suggestions': ['إنشاء فاتورة مبيعات جديدة', 'تسجيل سند صرف لمورد', 'تحويل بين الخزائن']},
      {'name': 'الضرائب', 'icon': Icons.receipt_long_rounded, 'suggestions': ['تقرير ضريبة القيمة المضافة', 'فحص الإقرارات المعلقة', 'تحليل الوعاء الضريبي']},
      {'name': 'الموارد', 'icon': Icons.people_alt_rounded, 'suggestions': ['احتساب مسيرات الرواتب', 'طلب إجازة لموظف', 'مراجعة عهد الموظفين']},
      {'name': 'المخازن', 'icon': Icons.inventory_2_rounded, 'suggestions': ['جرد المستودع الحالي', 'تحويل أصناف بين الفروع', 'تنبيهات نقص الكميات']},
    ];
    _tabController = TabController(length: _categories.length + 1, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _tabController.index - 1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getSuggestionIcon(String text) {
    if (text.contains('فاتورة') || text.contains('صرف')) return Icons.payments_rounded;
    if (text.contains('ضريبة')) return Icons.gavel_rounded;
    if (text.contains('رواتب') || text.contains('إجازة')) return Icons.badge_rounded;
    if (text.contains('جرد') || text.contains('أصناف')) return Icons.inventory_rounded;
    if (text.contains('تحويل')) return Icons.swap_horiz_rounded;
    return Icons.auto_awesome;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    return Consumer<AiChatController>(
      builder: (context, aiController, _) {
        List<String> suggestions = _selectedCategory == -1 
            ? aiController.currentSuggestions 
            : (_categories[_selectedCategory]['suggestions'] as List<String>);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.obsidianGlass, 
            borderRadius: BorderRadius.circular(40), 
            border: Border.all(color: context.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 0),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: context.glassBlurLevel, sigmaY: context.glassBlurLevel),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. UPDATED HEADER: Premium Wide Sliding Capsule
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(color: primaryOrange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, size: 14),
                            const SizedBox(width: 4),
                            Text(tr('ai_hud.tab_activity')),
                          ],
                        ),
                      ),
                      ..._categories.map((cat) => Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'], size: 14),
                            const SizedBox(width: 4),
                            Text(cat['name']),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                
                // 2. SCROLLABLE SUGGESTIONS
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionCapsule(suggestions[index], aiController);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionCapsule(String text, AiChatController aiController) {
    final bool isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => aiController.sendTextMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? context.cardBorder.withValues(alpha: 0.08) : primaryOrange.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(_getSuggestionIcon(text), color: primaryOrange, size: 18),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500))),
              Icon(Icons.arrow_forward_ios_rounded, color: primaryOrange.withValues(alpha: 0.3), size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// --- AI AGENT INPUT CAPSULE (PREMIUM OVERHAUL) ---
class AiAgentInputCapsule extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback onAttachTap;
  final bool isListening;
  final int activePageIndex;
  final Function(bool)? onExpansionChanged;

  const AiAgentInputCapsule({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMicTap,
    required this.onAttachTap,
    required this.activePageIndex,
    this.onExpansionChanged,
    this.isListening = false,
  });

  @override
  State<AiAgentInputCapsule> createState() => _AiAgentInputCapsuleState();
}

class _AiAgentInputCapsuleState extends State<AiAgentInputCapsule> {
  bool _isAttachExpanded = false;
  bool _isManuallyExpanded = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    final bool isAiPage = widget.activePageIndex == 0;
    final bool isFullMode = isAiPage || _isManuallyExpanded;

    final double sw = MediaQuery.of(context).size.width;
    final double maxWidth = isFullMode ? (sw < 980 ? sw - 60 : 950) : 190;

    return TapRegion(
      onTapOutside: (event) {
        if (_isManuallyExpanded) {
          setState(() {
            _isManuallyExpanded = false;
            _isAttachExpanded = false;
          });
          if (widget.onExpansionChanged != null) {
            widget.onExpansionChanged!(false);
          }
          _focusNode.unfocus();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.fastLinearToSlowEaseIn,
        width: maxWidth, 
        child: Row(
          mainAxisAlignment: isFullMode ? MainAxisAlignment.center : MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: widget.onMicTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isFullMode ? 80 : 64, 
                    height: isFullMode ? 80 : 64,
                    decoration: BoxDecoration(
                      color: widget.isListening 
                          ? Colors.orange.withValues(alpha: 0.2) 
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.45)), // 🌟 Glassy white
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isListening 
                            ? Colors.orange.withValues(alpha: 0.5) 
                            : context.cardBorder.withValues(alpha: 0.2), 
                        width: 2
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.isListening ? Icons.stop_rounded : Icons.mic_none_rounded, 
                        color: widget.isListening ? Colors.orange : primaryOrange, 
                        size: isFullMode ? 36 : 28
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isFullMode) {
                    setState(() => _isManuallyExpanded = true);
                    if (widget.onExpansionChanged != null) {
                      widget.onExpansionChanged!(true);
                    }
                    _focusNode.requestFocus();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: context.glassBlurHigh, sigmaY: context.glassBlurHigh),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastLinearToSlowEaseIn,
                      height: isFullMode ? 75 : 60,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.45), // 🌟 High-glass white for Light Mode
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: context.cardBorder.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 30, spreadRadius: 0),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: isFullMode 
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(
                                key: const ValueKey('expanded_dock'),
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: primaryOrange, size: 28),
                                    onPressed: widget.onAttachTap,
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: sw < 980 ? sw - 200 : 700,
                                    child: TextField(
                                      controller: widget.controller,
                                      focusNode: _focusNode,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18),
                                      decoration: InputDecoration(
                                        hintText: tr('ai_hud.input_hint'),
                                        hintStyle: TextStyle(color: isDark ? context.mutedText.withValues(alpha: 0.5) : Colors.black45, fontSize: 16),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      onSubmitted: (val) {
                                        if (val.trim().isNotEmpty) {
                                          widget.onSend();
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send_rounded, color: primaryOrange, size: 30),
                                    onPressed: () {
                                      if (widget.controller.text.trim().isNotEmpty) {
                                        widget.onSend();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              key: const ValueKey('pill_mode'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: primaryOrange, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "مساعد حساباتي",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1.2
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionItem {
  final String title;
  final IconData icon;
  final int index;
  const SuggestionItem(this.title, this.icon, this.index);
}

class CompactSuggestionGrid extends StatelessWidget {
  final Function(int) onSuggestionTap;
  
  const CompactSuggestionGrid({super.key, required this.onSuggestionTap});

  List<SuggestionItem> get _suggestions => [
    SuggestionItem(tr('ai_hud.btn_invoices'), Icons.receipt_long_rounded, 2),
    SuggestionItem(tr('ai_hud.btn_taxes'), Icons.account_balance_rounded, 3),
    SuggestionItem(tr('ai_hud.btn_hr'), Icons.people_alt_rounded, 4),
    SuggestionItem(tr('ai_hud.btn_audit'), Icons.security_rounded, 5),
    SuggestionItem(tr('ai_hud.btn_projects'), Icons.business_center_rounded, 11),
    SuggestionItem(tr('ai_hud.btn_inventory'), Icons.inventory_2_rounded, 10),
    SuggestionItem(tr('ai_hud.btn_analytics'), Icons.analytics_rounded, 1),
    SuggestionItem(tr('ai_hud.btn_users'), Icons.manage_accounts_rounded, 7),
    SuggestionItem(tr('ai_hud.btn_fraud'), Icons.radar_rounded, 5),
    SuggestionItem(tr('ai_hud.btn_forecast'), Icons.psychology_rounded, 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _suggestions.map((item) => _buildSuggestionChip(context, item)).toList(),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, SuggestionItem item) {
    return GestureDetector(
      onTap: () => onSuggestionTap(item.index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cardBorder.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: accentGold.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    color: context.textColor.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
