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
import 'package:buy_control/features/box_closures/presentation/bindings/box_closures_binding.dart';
import 'package:buy_control/features/box_closures/presentation/pages/box_closures_page.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/boxes/presentation/controllers/box_detail_controller.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/usecases/transaction_sort.dart';
import 'package:buy_control/features/transactions/presentation/add_items_flow.dart';
import 'package:buy_control/features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BoxDetailPage extends StatefulWidget {
  final BoxEntity box;
  const BoxDetailPage({super.key, required this.box});

  @override
  State<BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<BoxDetailPage> {
  late final controller = Get.find<BoxDetailController>(tag: widget.box.id);

  static const _sortOptions = [
    FilterChipOption(key: 'newest', label: 'Recentes'),
    FilterChipOption(key: 'oldest', label: 'Mais antigos'),
    FilterChipOption(key: 'highestValue', label: 'Maior valor'),
    FilterChipOption(key: 'lowestValue', label: 'Menor valor'),
  ];

  @override
  void dispose() {
    Get.delete<BoxDetailController>(tag: widget.box.id);
    super.dispose();
  }

  Future<void> _addItems() async {
    await openAddItemsFlow(context, widget.box.id);
    controller.load();
  }

  Future<void> _showDetails(TransactionEntity transaction) {
    return AppBottomSheet.show(context, child: TransactionDetailSheet(transaction: transaction));
  }

  Future<void> _delete(TransactionEntity transaction) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Excluir este lançamento?',
      message: 'Esta ação não poderá ser desfeita.',
    );
    if (confirmed) await controller.removeTransaction(transaction.id);
  }

  TransactionSort _sortFromKey(String? key) {
    return TransactionSort.values.firstWhere((s) => s.name == key, orElse: () => TransactionSort.newest);
  }

  void _openClosures() {
    BoxClosuresBinding(widget.box).dependencies();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BoxClosuresPage(box: widget.box),
    ));
  }

  Future<void> _closeBox() async {
    if (controller.transactions.isEmpty) {
      Get.snackbar('Nada para fechar', 'Esta Box não tem lançamentos abertos para fechar.');
      return;
    }

    final total = controller.transactions.fold(Money.zero, (sum, t) => sum + t.total);
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Fechar a Box "${widget.box.name}"?',
      message:
          'Isso vai congelar ${controller.transactions.length} lançamento(s) totalizando ${total.formatted}. '
          'Eles deixarão de poder ser editados ou excluídos, mas continuam disponíveis no histórico de '
          'Fechamentos. A Box continua disponível para novos lançamentos.',
      confirmLabel: 'Fechar Box',
      isDestructive: false,
    );
    if (!confirmed) return;

    final error = await controller.closeBox();
    if (error != null) Get.snackbar('Erro', error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title(widget.box.name, fontSize: AppFontSizes.fz09),
        actions: [
          IconButton(icon: const Icon(LucideIcons.history), onPressed: _openClosures),
          IconButton(icon: const Icon(LucideIcons.lock), onPressed: _closeBox),
        ],
      ),
      body: GetBuilder<BoxDetailController>(
        tag: widget.box.id,
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _SummaryHeader(summary: controller.summary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    SearchFieldDebounced(hint: 'Buscar lançamento', onChanged: controller.search),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChipsBar(
                        options: _sortOptions,
                        selectedKey: controller.sort.name,
                        onSelected: (key) => controller.setSort(_sortFromKey(key)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildBody(controller)),
            ],
          );
        },
      ),
      floatingActionButton: AppCircleButton(icon: LucideIcons.plus, onPressed: _addItems),
    );
  }

  Widget _buildBody(BoxDetailController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
      case ViewStatus.empty:
        return EmptyStateView(
          icon: LucideIcons.receipt,
          title: 'Nenhum lançamento nesta caixa',
          message: 'Adicione produtos ou um lançamento avulso para começar.',
          actionLabel: 'Adicionar itens',
          onAction: _addItems,
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final transaction = controller.transactions[i];
            return _TransactionCard(
              transaction: transaction,
              onTap: () => _showDetails(transaction),
              onDelete: () => _delete(transaction),
            );
          },
        );
    }
  }
}

class _SummaryHeader extends StatelessWidget {
  final BoxSummary? summary;
  const _SummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary?.total.formatted ?? Money.zero.formatted;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText.subtitle('Total'),
                AppText(total, fontWeight: FontWeight.bold, fontSize: AppFontSizes.fz11, color: AppColors.accent),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.subtitle('${summary?.transactionCount ?? 0} lançamentos'),
              AppText.subtitle('${summary?.itemCount ?? 0} itens'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionCard({required this.transaction, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = (transaction.title != null && transaction.title!.trim().isNotEmpty)
        ? transaction.title!
        : (transaction.items.isNotEmpty ? transaction.items.first.nameSnapshot : 'Lançamento');

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontWeight: FontWeight.w600),
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle(
                  '${DateTimeFormatter.ddMMyyyy(transaction.occurredAt)} · ${transaction.itemCount} itens',
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(transaction.total.formatted, fontWeight: FontWeight.w600, color: AppColors.accent),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
