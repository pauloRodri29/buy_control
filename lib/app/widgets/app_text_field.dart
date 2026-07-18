import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
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
        TextField(
          controller: controller,
          readOnly: readOnly,
          autofocus: autofocus,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          style: TextStyle(fontSize: AppFontSizes.fz08, color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant(isDark),
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            errorText: hasError ? errorText : null,
            prefixIcon: prefix,
            suffixIcon: suffix,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
