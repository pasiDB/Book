import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? svgAsset;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.svgAsset,
    this.icon,
    this.color,
    this.onTap,
    this.isSelected = false,
  }) : assert(svgAsset != null || icon != null,
            'Either svgAsset or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardColor = color ?? colorScheme.surfaceVariant;
    final iconColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: AppTheme.durationShort,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or SVG
                if (svgAsset != null)
                  SvgPicture.asset(
                    svgAsset!,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                else if (icon != null)
                  Icon(
                    icon!,
                    size: 32,
                    color: iconColor,
                  ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Subtitle
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final List<CategoryCard> categories;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const CategoryList({
    super.key,
    required this.categories,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: padding,
      crossAxisCount: 3,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: categories,
    );
  }
}
