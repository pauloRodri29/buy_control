import 'package:get/get.dart';
import 'dart:developer' as developer;

import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Tratamento global de erros com os ganchos nativos do Flutter:
///
/// - [FlutterError.onError]: erros do framework (build, layout, pintura).
/// - [PlatformDispatcher.onError]: erros assíncronos não tratados (ex.: um
///   `onPressed` async que lança exceção).
/// - [ErrorWidget.builder]: o que aparece no lugar de um widget que falhou
///   no build. Em debug fica a tela padrão (útil para desenvolver); em
///   release, um aviso amigável no lugar da área cinza.
class AppErrorHandler {
  AppErrorHandler._();

  static String get _genericMessage => 'errors.somethingWentWrongPleaseTry'.tr;

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _log(details.exception, details.stack, context: details.context?.toDescription());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _log(error, stack);
      AppFeedback.error(_genericMessage, title: 'errors.unexpectedError'.tr);
      return true;
    };

    if (kReleaseMode) {
      ErrorWidget.builder = (details) => const AppErrorWidget();
    }
  }

  static void _log(Object error, StackTrace? stack, {String? context}) {
    developer.log(
      context == null ? '$error' : '$context: $error',
      name: 'buy_control',
      error: error,
      stackTrace: stack,
      level: 1000, // SEVERE
    );
  }
}

/// Substituto amigável do [ErrorWidget] em release: ocupa o espaço do widget
/// que falhou com um ícone e uma mensagem curta, nas cores do tema.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: colors.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.warning, color: colors.error, size: 32),
                const SizedBox(height: 8),
                Text(
                  'errors.couldntDisplayContent'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
