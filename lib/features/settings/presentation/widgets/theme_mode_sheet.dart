import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

/// Escolha do tema (sistema/claro/escuro). A troca é aplicada na hora,
/// sem botão de confirmar.
class ThemeModeSheet extends StatelessWidget {
  const ThemeModeSheet({super.key});

  static const _options = [
    (ThemeMode.system, Symbols.smartphone, 'settings.automatic', 'settings.followsDeviceTheme'),
    (ThemeMode.light, Symbols.light_mode, 'common.light', 'settings.alwaysLight'),
    (ThemeMode.dark, Symbols.dark_mode, 'common.dark', 'settings.alwaysDark'),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('settings.theme'.tr, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final (mode, icon, title, subtitle) in _options)
            ListTile(
              selected: controller.mode == mode,
              leading: Icon(icon),
              title: Text(title.tr),
              subtitle: Text(subtitle.tr),
              trailing: controller.mode == mode ? const Icon(Symbols.check) : null,
              onTap: () => controller.setMode(mode),
            ),
        ],
      ),
    );
  }
}
