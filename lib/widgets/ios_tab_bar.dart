import 'package:flutter/material.dart';
import 'package:life_app/design/ui_tokens.dart';

/// Bottom tab shell tuned for clarity over decoration.
class IOSTabBar extends StatelessWidget {
  const IOSTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IOSTabItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shellColor =
        isDark ? const Color(0xFF171C26) : const Color(0xFFFEFDFC);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : UiBorders.subtle;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Align(
        alignment: Alignment.center,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: shellColor,
              borderRadius: BorderRadius.circular(UiRadii.lg),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: _TabButton(
                        item: items[index],
                        isActive: index == currentIndex,
                        onTap: () => onTap(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final IOSTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = item.color;
    final selectedColor = isDark
        ? activeColor
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.42),
            activeColor,
          );
    final inactiveColor =
        isDark ? const Color(0xFFAAB4C5) : const Color(0xFF4F5B6D);

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(UiRadii.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: isDark ? 0.24 : 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(UiRadii.md),
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: isDark ? 0.40 : 0.28)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 20 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(UiRadii.pill),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    item.icon,
                    size: 22,
                    color: isActive ? selectedColor : inactiveColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? selectedColor : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IOSTabItem {
  const IOSTabItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}
