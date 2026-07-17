import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

class FilterChipOption {
  final String key;
  final String label;
  const FilterChipOption({required this.key, required this.label});
}

class FilterChipsBar extends StatelessWidget {
  final List<FilterChipOption> options;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const FilterChipsBar({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final option = options[i];
          final selected = option.key == selectedKey;

          return GestureDetector(
            onTap: () => onSelected(selected ? null : option.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surfaceVariant(isDark),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: AppText(
                option.label,
                fontSize: AppFontSizes.fz06,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.textOnDarkButton : AppColors.textSecondary(isDark),
              ),
            ),
          );
        },
      ),
    );
  }
}
