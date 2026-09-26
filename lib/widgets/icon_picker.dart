import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'category_icon.dart';

class IconPickerGrid extends StatelessWidget {
  final List<CategoryIconItem> icons;
  final String? selectedIconKey;
  final ValueChanged<CategoryIconItem> onIconSelected;
  final Color accentColor;

  const IconPickerGrid({
    super.key,
    required this.icons,
    required this.selectedIconKey,
    required this.onIconSelected,
    this.accentColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkDividerColor : const Color(0xFFE2E8F0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final item = icons[index];
        final isSelected = selectedIconKey?.toLowerCase() == item.key.toLowerCase() ||
            selectedIconKey?.toLowerCase() == item.label.toLowerCase();

        return InkWell(
          onTap: () => onIconSelected(item),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withValues(alpha: 0.18) : cardBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accentColor : borderColor,
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(
                      item.iconData,
                      size: 26,
                      color: isSelected ? accentColor : primaryTextColor,
                    ),
                    if (isSelected)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? accentColor : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
