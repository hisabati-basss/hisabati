import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/industry_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';

class HubScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const HubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    final industryProvider = Provider.of<IndustryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Apple feel
        padding: EdgeInsets.fromLTRB(
          context.sectionPadding,
          context.sectionPadding,
          context.sectionPadding,
          100,
        ), // Extra bottom padding for Dock
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isMobile, industryProvider),
            const SizedBox(height: 16), // 📉 Reduced from 20

            _buildCategory(context, tr('hub.categories.smart_assets'), [
              if (PermissionService().isVisible('warehouse')) _buildHubTile(context, 19, tr('hub.tiles.warehouse'), Icons.warehouse_rounded, Colors.orangeAccent, isFeatured: true),
              if (PermissionService().isVisible('cloud_inbox')) _buildHubTile(context, 20, tr('hub.tiles.cloud_inbox'), Icons.cloud_download_rounded, Colors.blueAccent, isFeatured: true),
              if (PermissionService().isVisible('tools')) _buildHubTile(context, 14, tr('hub.tiles.tools'), Icons.handyman_rounded, Colors.redAccent, isFeatured: true),
              if (PermissionService().isVisible('pos')) _buildHubTile(context, 21, tr('hub.tiles.pos'), Icons.point_of_sale, Colors.greenAccent, isFeatured: true),
            ], isMobile),

            const SizedBox(height: 16),

            _buildCategory(context, tr('hub.categories.manufacturing'), [
              if (PermissionService().isVisible('manufacturing')) _buildHubTile(context, 26, tr('hub.tiles.bom'), Icons.precision_manufacturing, Colors.deepPurpleAccent, isFeatured: true),
              if (PermissionService().isVisible('manufacturing')) _buildHubTile(context, 25, tr('hub.tiles.manufacturing'), Icons.factory_rounded, Colors.brown, isFeatured: true),
            ], isMobile),

            const SizedBox(height: 16),

            _buildCategory(context, tr('hub.categories.admin'), [
              if (PermissionService().isVisible('bi')) _buildHubTile(context, 24, tr('hub.tiles.bi'), Icons.dashboard_customize_rounded, Colors.purpleAccent, isFeatured: true),
              if (PermissionService().isVisible('hr')) _buildHubTile(context, 4, tr('hub.tiles.hr'), Icons.people, Colors.blue),
              if (PermissionService().isVisible('custody')) _buildHubTile(context, 28, tr('hub.tiles.custody'), Icons.work_history_outlined, Colors.indigoAccent, isFeatured: true),
              if (PermissionService().isVisible('feasibility')) _buildHubTile(context, 5, tr('hub.tiles.feasibility'), Icons.lightbulb, Colors.yellow),
              if (PermissionService().isVisible('users')) _buildHubTile(context, 6, tr('hub.tiles.users'), Icons.group_work, Colors.teal),
              if (PermissionService().isVisible('projects')) _buildHubTile(context, 11, tr('hub.tiles.projects'), Icons.assignment, Colors.cyan),
            ], isMobile),

            const SizedBox(height: 16), // Reduced from 32

            _buildCategory(context, tr('hub.categories.growth'), [
              if (PermissionService().isVisible('marketing')) _buildHubTile(context, 7, tr('hub.tiles.marketing'), Icons.monetization_on, Colors.purple),
              if (PermissionService().isVisible('subscriptions')) _buildHubTile(context, 8, tr('hub.tiles.subscriptions'), Icons.card_membership, Colors.indigo),
              if (PermissionService().isVisible('cheques')) _buildHubTile(context, 27, tr('hub.tiles.cheques'), Icons.account_balance_wallet, Colors.greenAccent, isFeatured: true),
              if (PermissionService().isVisible('accounting')) _buildHubTile(context, 35, tr('hub.tiles.trial_balance'), Icons.balance, Colors.amberAccent, isFeatured: true),
            ], isMobile),

            const SizedBox(height: 16),

            _buildCategory(context, tr('hub.categories.ai'), [
              if (PermissionService().isVisible('ai_chat')) _buildHubTile(context, 0, tr('hub.tiles.ai_chat'), Icons.chat_bubble_rounded, primaryOrange, isFeatured: true),
              if (PermissionService().isVisible('internal_chat')) _buildHubTile(context, 40, "شات الموظفين الداخلي", Icons.forum_rounded, Colors.tealAccent, isFeatured: true),
            ], isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, IndustryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: primaryOrange),
              const SizedBox(width: 4),
              Text(
                provider.industryName,
                style: const TextStyle(color: primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        Text(
          tr('hub.header.app_center'),
          style: TextStyle(
            fontSize: context.headerSize, // 📉 Reduced from 28
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String title,
    List<Widget> items,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.bodySize - 1, // 📉 Reduced from 14
            color: context.textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8), // 📉 Reduced from 12
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, // 📉 Reduced from 12
          mainAxisSpacing: 8, // 📉 Reduced from 12
          childAspectRatio: isMobile ? 1.2 : 1.4, // More compact aspect ratio
          children: items,
        ),
      ],
    );
  }

  Widget _buildHubTile(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    Color color, {
    bool isFeatured = false,
  }) {
    return _HubTile(
      index: index,
      label: label,
      icon: icon,
      color: color,
      isFeatured: isFeatured,
      onTap: () => onNavigate(index),
    );
  }
}

class _HubTile extends StatefulWidget {
  final int index;
  final String label;
  final IconData icon;
  final Color color;
  final bool isFeatured;
  final VoidCallback onTap;

  const _HubTile({
    required this.index,
    required this.label,
    required this.icon,
    required this.color,
    required this.isFeatured,
    required this.onTap,
  });

  @override
  State<_HubTile> createState() => _HubTileState();
}

class _HubTileState extends State<_HubTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Container(
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
              border: Border.all(
                color: widget.isFeatured ? widget.color.withValues(alpha: 0.4) : context.cardBorder,
                width: 1, // 📉 Normalized
              ),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // 📉 Reduced from 5
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // 📉 Reduced from 12
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: context.iconSize), // 📉 Reduced from 22
                      ),
                      const SizedBox(height: 4), // 📉 Reduced from 8
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.bodySize, // 📉 Reduced from 12
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
    );
  }
}
