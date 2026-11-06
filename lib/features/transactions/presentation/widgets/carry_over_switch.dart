import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:flutter/material.dart';

/// Opção "Repetir no próximo ciclo" de um lançamento: quando a Box for
/// fechada, os lançamentos marcados voltam para ela como novos lançamentos
/// abertos (ver `CloseBox`); os desmarcados ficam só no histórico.
class CarryOverSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CarryOverSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeTrackColor: AppColors.accent,
      onChanged: onChanged,
      title: const AppText('Repetir no próximo ciclo', fontWeight: FontWeight.w600),
      subtitle: AppText.subtitle(
        value
            ? 'Ao fechar a Box, este lançamento continua nela para a próxima compra.'
            : 'Ao fechar a Box, este lançamento vai só para o histórico.',
        color: AppColors.textSecondary(isDark),
      ),
    );
  }
}
