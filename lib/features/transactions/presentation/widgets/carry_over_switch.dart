import 'package:get/get.dart';
import 'package:buy_control/app/theme/theme_context.dart';
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
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeTrackColor: context.colors.primary,
      onChanged: onChanged,
      title: AppText('transactions.repeatNextCycle'.tr, fontWeight: FontWeight.w600),
      subtitle: AppText.subtitle(
        value
            ? 'transactions.whenBoxClosedEntryStays'.tr
            : 'transactions.whenBoxClosedEntryGoes'.tr,
      ),
    );
  }
}
