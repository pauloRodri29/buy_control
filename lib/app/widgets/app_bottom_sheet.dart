import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Conteúdo padrão de bottom sheet: margens do app, rolagem quando o
/// teclado abre e área segura da barra de navegação do aparelho. Cor,
/// cantos e alça vêm do `bottomSheetTheme` nativo.
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;

  const AppBottomSheet({super.key, required this.child, this.height});

  /// Abre um [showModalBottomSheet] nativo com a alça de arrastar.
  static Future<T?> show<T>(BuildContext context, {required Widget child, double? height}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AppBottomSheet(height: height, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height ?? mediaQuery.size.height * 0.85),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg + mediaQuery.padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Flexible(child: child)],
          ),
        ),
      ),
    );
  }
}
