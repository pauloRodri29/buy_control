import 'package:buy_control/app/i18n/locale_controller.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/core/i18n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Escolha do idioma (português ou inglês). A troca é aplicada na hora,
/// sem botão de confirmar. Cada idioma aparece com o nome nele mesmo.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocaleController>(
      builder: (controller) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('settings.language'.tr, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final locale in AppLocale.supported)
            ListTile(
              selected: controller.locale == locale,
              leading: const Icon(Symbols.translate),
              title: Text(AppLocale.nativeName(locale)),
              trailing: controller.locale == locale ? const Icon(Symbols.check) : null,
              onTap: () => controller.setLocale(locale),
            ),
        ],
      ),
    );
  }
}
