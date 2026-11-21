import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/planning/domain/entities/plan_board_entity.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Pergunta para qual quadro aberto um item deve ir. Devolve o quadro
/// escolhido ou `null` se o usuário desistir.
Future<PlanBoardEntity?> showPlanBoardPicker(
  BuildContext context, {
  required String title,
  required List<PlanBoardEntity> boards,
}) {
  return AppBottomSheet.show<PlanBoardEntity>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(title, maxLines: 2),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final b in boards)
                Builder(
                  builder: (tileContext) => ListTile(
                    leading: const Icon(Symbols.view_kanban),
                    title: AppText(b.title, fontWeight: FontWeight.w600),
                    subtitle: AppText.subtitle(DateTimeFormatter.ddMMyyyy(b.targetDate)),
                    onTap: () => Navigator.of(tileContext).pop(b),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
