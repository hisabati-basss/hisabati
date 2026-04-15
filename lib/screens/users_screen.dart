import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme_extension.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _selectedTab = 0; // 0 = Users, 1 = Branches

  // Dummy internal state for toggling permissions
  final Map<String, bool> _permissions = {
    tr('users.permissions.add_entries'): true,
    tr('users.permissions.edit_invoices'): false,
    tr('users.permissions.export_reports'): true,
    tr('users.permissions.manage_hr'): false,
  };

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('users.central_system'),
                      style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 1), // 📉 Reduced from 13
                    ),
                    const SizedBox(height: 2), // 📉 Reduced from 4
                    Text(
                      tr('users.title'),
                      style: TextStyle(
                        fontSize: context.headerSize, // 📉 Reduced from 32
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildTabs(context, isMobile),
              ],
            ),
          ),
          const SizedBox(height: 16), // 📉 Reduced from 32

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _selectedTab == 0
                ? _buildUsersTab(context, isMobile)
                : _buildBranchesTab(context, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(2), // 📉 Reduced from 4
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(
            context,
            tr('users.tabs.users'),
            0,
            Icons.people,
            isMobile,
          ),
          _buildTabButton(context, tr('users.tabs.branches'), 1, Icons.domain, isMobile),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String title,
    int index,
    IconData icon,
    bool isMobile,
  ) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 8, // 📉 Reduced
          vertical: 2, // 📉 Reduced
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(4), // 📉 Sharper
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.iconSize - 10, // 📉 Reduced
              color: isSelected ? Colors.black87 : context.mutedText,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black87 : context.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: context.bodySize - 4, // 📉 Reduced
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, bool isMobile) {
    return Column(
      key: const ValueKey("users"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('users.managers_label'), // 📉 Shortened
              style: TextStyle(
                fontSize: context.subHeaderSize, // 📉 Reduced from 18
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildCapsuleButton(
              context,
              icon: Icons.person_add,
              label: tr('users.add_user_btn'),
              isPrimary: true,
            ),
          ],
        ),
        const SizedBox(height: 12), // 📉 Reduced from 16
        Container(
          padding: const EdgeInsets.all(8), // 📉 Reduced from cardPadding
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4), // 📉 Sharper
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserItem(
                context,
                "سارة أحمد",
                tr('users.roles.accountant'), // 📉 Shortened
                "sara@co.com", // 📉 Shortened
                tr('common.active'),
                const Color(0xFF00F260),
                isMobile,
              ),
              const SizedBox(height: 4), // 📉 Reduced
              _buildUserItem(
                context,
                "محمد عبدالله",
                tr('users.roles.auditor'), // 📉 Shortened
                "m@co.com", // 📉 Shortened
                tr('common.locked'),
                Colors.redAccent,
                isMobile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // 📉 Reduced from 32
        Text(
          tr('users.permissions_label'), // 📉 Shortened
          style: TextStyle(
            fontSize: context.subHeaderSize, // 📉 Reduced from 18
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12), // 📉 Reduced from 16
        Container(
          padding: EdgeInsets.all(context.cardPadding), // 📉 Reduced from 16/24
          decoration: BoxDecoration(
            color: const Color(0xFF9A66FF).withValues(alpha: 0.04), // Purple tint
            borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 24
            border: Border.all(color: const Color(0xFF9A66FF).withValues(alpha: 0.1)),
          ),
          child: Column(
            children: _permissions.entries
                .map((e) => _buildPermissionToggle(context, e.key, e.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionToggle(
    BuildContext context,
    String feature,
    bool isGranted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // 📉 Reduced
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                size: context.iconSize - 10, // 📉 Reduced
                color: isGranted ? const Color(0xFF9800E5) : context.mutedText.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                feature,
                style: TextStyle(
                  color: isGranted ? context.textColor : context.mutedText,
                  fontSize: context.bodySize - 3, // 📉 Reduced
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _permissions[feature] = !isGranted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, // 📉 Reduced
              height: 12, // 📉 Reduced
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFF9800E5) : context.cardBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4), // 📉 Sharper
              ),
              alignment: isGranted ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 9, // 📉 Reduced
                height: 9, // 📉 Reduced
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesTab(BuildContext context, bool isMobile) {
    return Column(
      key: const ValueKey("branches"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('users.branch_management'), // 📉 Shortened
              style: TextStyle(
                fontSize: context.subHeaderSize, // 📉 Reduced from 18
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildCapsuleButton(
              context,
              icon: Icons.add,
              label: tr('users.new_branch_btn'),
              isPrimary: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBranchCard(
          context,
          "المركز الرئيسي (الرياض)",
          "السعودية - منطقة الرياض",
          "45 ${tr('users.user_count_label')}",
          tr('common.online'),
          Colors.greenAccent,
          isMobile,
        ),
        const SizedBox(height: 8), // 📉 Reduced from 12
        _buildBranchCard(
          context,
          "فرع الخليج التجاري (دبي)",
          "الإمارات العربية المتحدة - دبي",
          "12 ${tr('users.user_count_label')}",
          tr('common.online'),
          Colors.greenAccent,
          isMobile,
        ),
        const SizedBox(height: 8), // 📉 Reduced from 12
        _buildBranchCard(
          context,
          "فرع المهندسين (القاهرة)",
          "مصر - الجيزة",
          "8 ${tr('users.user_count_label')}",
          tr('common.syncing'),
          Colors.orangeAccent,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildUserItem(
    BuildContext context,
    String name,
    String role,
    String email,
    String status,
    Color statusColor,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 📉 Reduced
      decoration: BoxDecoration(
        color: context.cardSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2), // 📉 Sharper
        border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: context.textColor, size: context.iconSize - 6), // 📉 Reduced
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodySize - 2), // 📉 Reduced
                ),
                Text(
                  email,
                  style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 5), // 📉 Reduced
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 📉 Reduced
              decoration: BoxDecoration(
                color: context.badgeSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2), // 📉 Sharper
              ),
              child: Text(
                role,
                style: TextStyle(color: context.mutedText, fontSize: context.bodySize - 5), // 📉 Reduced
              ),
            ),
            const SizedBox(width: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // 📉 Reduced
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4), // 📉 Sharper
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: context.bodySize - 6, // 📉 Reduced
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(
    BuildContext context,
    String name,
    String location,
    String users,
    String status,
    Color statusColor,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(8), // 📉 Reduced from 16/20
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.02), // 📉 Lighter
        borderRadius: BorderRadius.circular(4), // 📉 Sharper
        border: Border.all(color: statusColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_city,
                color: statusColor.withValues(alpha: 0.6),
                size: context.iconSize - 8, // 📉 Reduced
              ),
              const SizedBox(width: 8), // 📉 Reduced from 16
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.bodySize - 2, // 📉 Reduced
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.map, size: 8, color: context.mutedText.withValues(alpha: 0.5)), // 📉 Reduced
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          color: context.mutedText,
                          fontSize: context.bodySize - 5, // 📉 Reduced
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                users,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.bodySize - 3, // 📉 Reduced
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 📉 Reduced
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4), // 📉 Sharper
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: context.bodySize - 6, // 📉 Reduced
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 100
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 📉 Reduced blur
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 📉 Reduced from 16/10
          decoration: BoxDecoration(
            color: isPrimary ? primaryOrange : primaryOrange.withValues(alpha: 0.05),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(context.cardRadius), // 📉 Reduced from 100
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14, // 📉 Reduced from 16
                color: isPrimary ? Colors.black87 : context.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.black87 : context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // 📉 Reduced from 12
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
