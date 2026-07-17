import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectableListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool selected;
  final VoidCallback onTap;

  const SelectableListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surfaceVariant(isDark),
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textSecondary(isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(title, fontWeight: FontWeight.w600),
                    if (subtitle != null)
                      AppText(
                        subtitle!,
                        fontSize: AppFontSizes.fz05,
                        color: AppColors.textSecondary(isDark),
                      ),
                  ],
                ),
              ),
              if (trailingText != null)
                AppText(trailingText!, fontSize: AppFontSizes.fz06, color: AppColors.textSecondary(isDark)),
            ],
          ),
        ),
      ),
    );
  }
}
