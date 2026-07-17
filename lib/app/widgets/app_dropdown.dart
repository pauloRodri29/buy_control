import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  final T value;
  final String label;
  const AppDropdownOption({required this.value, required this.label});
}

class AppDropdown<T> extends StatelessWidget {
  final List<AppDropdownOption<T>> options;
  final T? value;
  final String? hint;
  final String? label;
  final String? errorText;
  final ValueChanged<T?> onChanged;

  const AppDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.label,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          AppText(label!, fontSize: AppFontSizes.fz06, color: AppColors.textSecondary(isDark)),
          const SizedBox(height: AppSpacing.xs),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant(isDark),
          style: TextStyle(fontSize: AppFontSizes.fz08, color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant(isDark),
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            errorText: hasError ? errorText : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.border(isDark)),
            ),
          ),
          items: options
              .map((o) => DropdownMenuItem<T>(value: o.value, child: Text(o.label)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
