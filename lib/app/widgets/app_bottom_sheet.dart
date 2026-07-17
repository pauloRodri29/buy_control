import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;

  const AppBottomSheet({super.key, required this.child, this.height});

  /// Abre o bottom sheet padronizado: rolagem quando o teclado abre e área
  /// segura para a barra de navegação do dispositivo.
  static Future<T?> show<T>(BuildContext context, {required Widget child, double? height}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(height: height, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: height ?? mediaQuery.size.height * 0.92),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: AppSpacing.lg + mediaQuery.padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.border(isDark),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
