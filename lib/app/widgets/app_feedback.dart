import 'package:buy_control/app/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Chave do [ScaffoldMessenger] raiz (registrada no `GetMaterialApp`), para
/// mostrar avisos também de fora da árvore de widgets (ex.: controllers).
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum _FeedbackKind { info, success, error }

/// Avisos rápidos ao usuário com o [SnackBar] nativo (estilo vindo do
/// `snackBarTheme`). Substitui o `Get.snackbar`.
class AppFeedback {
  AppFeedback._();

  static void info(String message, {String? title}) => _show(_FeedbackKind.info, message, title);

  static void success(String message, {String? title}) => _show(_FeedbackKind.success, message, title);

  static void error(String message, {String? title}) => _show(_FeedbackKind.error, message, title);

  static void _show(_FeedbackKind kind, String message, String? title) {
    final messenger = appScaffoldMessengerKey.currentState;
    final context = appScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>();
    final (icon, iconColor) = switch (kind) {
      _FeedbackKind.info => (Symbols.info, colors.inversePrimary),
      _FeedbackKind.success => (Symbols.check_circle, semantic?.success ?? colors.inversePrimary),
      _FeedbackKind.error => (Symbols.error, colors.error),
    };
    final textStyle = theme.snackBarTheme.contentTextStyle;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Text(title, style: textStyle?.copyWith(fontWeight: FontWeight.bold)),
                  Text(message, style: textStyle),
                ],
              ),
            ),
          ],
        ),
      ));
  }
}
