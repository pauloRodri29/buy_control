import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  final T value;
  final String label;
  const AppDropdownOption({required this.value, required this.label});
}

/// [DropdownButtonFormField] nativo com rótulo acima, no mesmo visual do
/// `AppTextField` (decoração vinda do `inputDecorationTheme`).
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
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: context.colors.surface,
          borderRadius: AppRadius.borderMd,
          style: context.text.bodyLarge,
          decoration: InputDecoration(hintText: hint, errorText: hasError ? errorText : null),
          items: options.map((o) => DropdownMenuItem<T>(value: o.value, child: Text(o.label))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
