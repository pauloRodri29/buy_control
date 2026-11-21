import 'package:get/get.dart';
import 'package:buy_control/app/theme/app_radius.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_definition.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Selo com o nome do plano (card da conta, Configurações, cards de plano).
class PlanBadge extends StatelessWidget {
  final PlanDefinition plan;

  const PlanBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) =
        plan.isFree ? (colors.surfaceContainerHighest, colors.onSurfaceVariant) : (colors.primary, colors.onPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.workspace_premium, size: 14, color: foreground, fill: plan.isFree ? 0 : 1),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'common.planName'.trParams({'name': plan.name}),
            style: context.text.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
