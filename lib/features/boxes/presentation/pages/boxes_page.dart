import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_circle_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/boxes/presentation/bindings/box_detail_binding.dart';
import 'package:buy_control/features/boxes/presentation/controllers/boxes_controller.dart';
import 'package:buy_control/features/boxes/presentation/pages/box_detail_page.dart';
import 'package:buy_control/features/boxes/presentation/widgets/box_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BoxesPage extends StatelessWidget {
  const BoxesPage({super.key});

  static const _sortOptions = [
    FilterChipOption(key: 'date', label: 'Recentes'),
    FilterChipOption(key: 'name', label: 'Nome'),
    FilterChipOption(key: 'value', label: 'Valor'),
  ];

  void _openForm(BuildContext context, {BoxEntity? box}) {
    AppBottomSheet.show(context, child: BoxFormSheet(box: box));
  }

  void _openDetail(BuildContext context, BoxEntity box) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) {
        BoxDetailBinding(box).dependencies();
        return BoxDetailPage(box: box);
      },
    ));
  }

  Future<void> _delete(BuildContext context, BoxesController controller, BoxEntity box) async {
    final summary = controller.summaries[box.id];
    final count = summary?.transactionCount ?? 0;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir a caixa "${box.name}"?',
      message: 'Isso não apaga o histórico: os $count lançamentos registrados nela deixam de '
          'aparecer nas listagens, mas continuam preservados.',
    );
    if (confirmed) await controller.delete(box.id);
  }

  BoxSort _sortFromKey(String? key) {
    switch (key) {
      case 'name':
        return BoxSort.name;
      case 'value':
        return BoxSort.value;
      default:
        return BoxSort.date;
    }
  }

  String _sortKey(BoxSort sort) {
    switch (sort) {
      case BoxSort.name:
        return 'name';
      case BoxSort.value:
        return 'value';
      case BoxSort.date:
        return 'date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Caixas', fontSize: AppFontSizes.fz09)),
      body: GetBuilder<BoxesController>(
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Column(
                  children: [
                    SearchFieldDebounced(hint: 'Buscar caixa', onChanged: controller.search),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChipsBar(
                        options: _sortOptions,
                        selectedKey: _sortKey(controller.sort),
                        onSelected: (key) => controller.setSort(_sortFromKey(key)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(context, controller)),
            ],
          );
        },
      ),
      floatingActionButton: AppCircleButton(icon: LucideIcons.plus, onPressed: () => _openForm(context)),
    );
  }

  Widget _buildBody(BuildContext context, BoxesController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
      case ViewStatus.empty:
        return EmptyStateView(
          icon: LucideIcons.package,
          title: 'Nenhuma caixa cadastrada',
          message: 'Crie caixas para organizar suas compras, como "Mercado" ou "Farmácia".',
          actionLabel: 'Nova caixa',
          onAction: () => _openForm(context),
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.boxes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final box = controller.boxes[i];
            final summary = controller.summaries[box.id];
            return _BoxCard(
              box: box,
              summary: summary,
              onTap: () => _openDetail(context, box),
              onEdit: () => _openForm(context, box: box),
              onArchive: () => controller.archive(box.id, archived: !box.isArchived),
              onDelete: () => _delete(context, controller, box),
            );
          },
        );
    }
  }
}

class _BoxCard extends StatelessWidget {
  final BoxEntity box;
  final BoxSummary? summary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _BoxCard({
    required this.box,
    required this.summary,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = summary?.total.formatted ?? Money.zero.formatted;
    final transactionCount = summary?.transactionCount ?? 0;
    final lastMovement = summary?.lastMovementAt;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(box.name, fontWeight: FontWeight.bold, fontSize: AppFontSizes.fz08),
                const SizedBox(height: AppSpacing.xs),
                AppText(total, fontWeight: FontWeight.w600, color: AppColors.accent),
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle('$transactionCount lançamentos'),
                AppText.subtitle(
                  lastMovement == null
                      ? 'Sem movimentações'
                      : 'Última movimentação: ${DateTimeFormatter.relative(lastMovement)}',
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'archive':
                  onArchive();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'archive', child: Text(box.isArchived ? 'Desarquivar' : 'Arquivar')),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
