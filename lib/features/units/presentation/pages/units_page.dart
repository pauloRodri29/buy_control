import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_circle_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/features/units/domain/entities/unit_entity.dart';
import 'package:buy_control/features/units/presentation/controllers/units_controller.dart';
import 'package:buy_control/features/units/presentation/widgets/unit_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  void _openForm(BuildContext context, {UnitEntity? unit}) {
    AppBottomSheet.show(context, child: UnitFormSheet(unit: unit));
  }

  Future<void> _delete(BuildContext context, UnitsController controller, UnitEntity unit) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir a unidade "${unit.name}"?',
      message: 'Esta unidade deixará de aparecer para novos produtos e lançamentos. '
          'Itens já cadastrados com ela continuam funcionando normalmente.',
    );
    if (confirmed) await controller.delete(unit.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Unidades', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<UnitsController>(
        builder: (controller) {
          switch (controller.status) {
            case ViewStatus.initial:
            case ViewStatus.loading:
              return const LoadingSkeletonList();
            case ViewStatus.error:
              return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
            case ViewStatus.empty:
              return EmptyStateView(
                icon: LucideIcons.ruler,
                title: 'Nenhuma unidade cadastrada',
                message: 'Crie unidades como Quilo, Litro ou Unidade para usar nos produtos.',
                actionLabel: 'Nova unidade',
                onAction: () => _openForm(context),
              );
            case ViewStatus.success:
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.units.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final unit = controller.units[i];
                  return ListTile(
                    title: AppText(unit.name, fontWeight: FontWeight.w600),
                    subtitle: AppText.subtitle(unit.abbreviation),
                    onTap: () => _openForm(context, unit: unit),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      onPressed: () => _delete(context, controller, unit),
                    ),
                  );
                },
              );
          }
        },
      ),
      floatingActionButton: AppCircleButton(icon: LucideIcons.plus, onPressed: () => _openForm(context)),
    );
  }
}
