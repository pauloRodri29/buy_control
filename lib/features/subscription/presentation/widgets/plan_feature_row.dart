import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Um módulo do plano: ✓ quando incluído, cadeado quando não, e
/// "Em breve" para o que ainda não existe no app.
class PlanFeatureRow extends StatelessWidget {
  final FeatureKey feature;
  final bool included;

  /// Versão compacta, sem margem lateral (dentro dos cards de plano).
  final bool dense;

  const PlanFeatureRow({super.key, required this.feature, required this.included, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 0 : AppSpacing.lg, vertical: dense ? 2 : AppSpacing.xs + 2),
      child: Row(
        children: [
          Icon(
            included ? Symbols.check_circle : Symbols.lock,
            size: 18,
            fill: included ? 1 : 0,
            color: included ? context.semantic.success : colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              feature.label,
              style: context.text.bodyMedium?.copyWith(
                color: included ? null : colors.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (!feature.available)
            Text('common.comingSoon'.tr, style: context.text.labelSmall?.copyWith(color: colors.tertiary)),
        ],
      ),
    );
  }
}
