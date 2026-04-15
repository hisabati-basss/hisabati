import 'package:flutter/material.dart';

class ContextMenuAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  ContextMenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class ContextMenuWrapper extends StatelessWidget {
  final Widget child;
  final List<ContextMenuAction> actions;

  const ContextMenuWrapper({
    super.key,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    if (overlay == null) return;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40), // smaller rect, the touch area
        Offset.zero & overlay.semanticBounds.size,
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12, width: 1),
      ),
      elevation: 10,
      items: actions.map((action) {
        return PopupMenuItem(
          onTap: action.onTap,
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: isDark ? Colors.white70 : Colors.black87),
              const SizedBox(width: 12),
              Text(
                action.title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
