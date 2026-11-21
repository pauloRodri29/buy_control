import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_date_picker.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/filter_chips_bar.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/app/widgets/search_field_debounced.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/box_closures/presentation/bindings/box_closures_binding.dart';
import 'package:buy_control/features/box_closures/presentation/pages/box_closures_page.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_summary.dart';
import 'package:buy_control/features/boxes/presentation/controllers/box_detail_controller.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:buy_control/features/transactions/domain/usecases/transaction_sort.dart';
import 'package:buy_control/features/transactions/presentation/add_items_flow.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:get/get.dart';

class BoxDetailPage extends StatefulWidget {
  final BoxEntity box;
  const BoxDetailPage({super.key, required this.box});

  @override
  State<BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<BoxDetailPage> {
  late final controller = Get.find<BoxDetailController>(tag: widget.box.id);

  static const _sortOptions = [
    FilterChipOption(key: 'newest', label: 'boxes.recent'),
    FilterChipOption(key: 'oldest', label: 'boxes.oldest'),
    FilterChipOption(key: 'highestValue', label: 'boxes.highestValue'),
    FilterChipOption(key: 'lowestValue', label: 'boxes.lowestValue'),
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

  /// Lançamentos listados aqui estão sempre abertos: tocar abre a edição
  /// (quantidade, preço, desconto, remover/adicionar itens).
  Future<void> _edit(TransactionEntity transaction) async {
    final saved = await openEditTransactionFlow(context, transaction);
    if (saved) controller.load();
  }

  Future<void> _changeQuantity(TransactionEntity transaction, TransactionItemEntity item, double delta) async {
    final error = await controller.changeItemQuantity(transaction, item.id, delta);
    if (error != null) AppFeedback.error(error);
  }

  Future<void> _delete(TransactionEntity transaction) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'boxes.deleteEntry'.tr,
      message: 'boxes.actionCantUndone'.tr,
    );
    if (confirmed) await controller.removeTransaction(transaction.id);
  }

  TransactionSort _sortFromKey(String? key) {
    return TransactionSort.values.firstWhere((s) => s.name == key, orElse: () => TransactionSort.newest);
  }

  void _openClosures() {
    BoxClosuresBinding(widget.box).dependencies();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BoxClosuresPage(box: widget.box)));
  }

  Future<void> _closeBox() async {
    if (controller.transactions.isEmpty) {
      AppFeedback.info('common.boxHasNoOpenEntries'.tr, title: 'boxes.nothingClose'.tr);
      return;
    }

    final now = DateTime.now();
    final referenceDate = await AppDatePicker.show(
      context,
      title: 'boxes.closingReferenceDate'.tr,
      confirmLabel: 'common.continue'.tr,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      shortcuts: AppDatePicker.recentShortcuts(),
    );
    if (referenceDate == null || !mounted) return;

    final total = controller.transactions.fold(Money.zero, (sum, t) => sum + t.total);
    final itemCount = controller.transactions.fold(0, (sum, t) => sum + t.itemCount);
    final openCount = controller.transactions.length;
    final carriedOver = controller.transactions.where((t) => t.carryOver).length;
    final carryOverMessage = carriedOver == 0
        ? 'boxes.noEntriesAreSetRepeat'.tr
        : carriedOver == openCount
        ? 'boxes.sameEntriesStayBoxNext'.tr
        : 'boxes.entriesAreSetRepeatStayCarriedOverOpenCount'.trParams({'carriedOver': '$carriedOver', 'openCount': '$openCount'});
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'boxes.closePurchasesDate'.trParams({'ddMMyyyy': DateTimeFormatter.ddMMyyyy(referenceDate)}),
      message:
          'boxes.itemsTotalingBecomePermanentRecordItemCountAmountCarryOverMessage'.trParams({'itemCount': '$itemCount', 'formatted': total.formatted, 'carryOverMessage': carryOverMessage}),
      confirmLabel: 'boxes.closeBox'.tr,
      isDestructive: false,
    );
    if (!confirmed) return;

    final error = await controller.closeBox(referenceDate: referenceDate);
    if (error != null) {
      AppFeedback.error(error);
    } else {
      AppFeedback.success('boxes.purchasesSavedHistoryDate'.trParams({'ddMMyyyy': DateTimeFormatter.ddMMyyyy(referenceDate)}), title: 'boxes.boxClosed'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.heading(widget.box.name, ),
        actions: [
          IconButton(icon: const Icon(Symbols.history), onPressed: _openClosures),
          IconButton(icon: const Icon(Symbols.lock), onPressed: _closeBox),
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
                    SearchFieldDebounced(hint: 'boxes.searchEntry'.tr, onChanged: controller.search),
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _addItems,
        child: const Icon(Symbols.add),
      ),
    );
  }

  Widget _buildBody(BoxDetailController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'common.unexpectedError'.tr, onRetry: controller.load);
      case ViewStatus.empty:
        return EmptyStateView(
          icon: Symbols.receipt,
          title: 'boxes.noEntriesBox'.tr,
          message: 'boxes.addProductsOneOffEntry'.tr,
          actionLabel: 'common.addItems'.tr,
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
              onTap: () => _edit(transaction),
              onDelete: () => _delete(transaction),
              onChangeQuantity: (item, delta) => _changeQuantity(transaction, item, delta),
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
                AppText.subtitle('common.total'.tr),
                AppText.title(total, color: context.colors.primary),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.subtitle(_plural(summary?.transactionCount ?? 0, 'boxes.entry'.tr, 'boxes.entries'.tr)),
              AppText.subtitle(_plural(summary?.itemCount ?? 0, 'common.productLower'.tr, 'common.productsLower'.tr)),
            ],
          ),
        ],
      ),
    );
  }
}

String _plural(num count, String singular, String plural) => '$count ${count == 1 ? singular : plural}';

/// Card de um lançamento aberto. O caso comum é um produto por lançamento
/// (layout plano: nome, preço, quantidade e total). Lançamentos antigos
/// com vários produtos mostram uma linha por produto.
class _TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  final void Function(TransactionItemEntity item, double delta) onChangeQuantity;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
    required this.onChangeQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
          child: transaction.items.length == 1 ? _single(context) : _multiple(context),
        ),
      ),
    );
  }

  Widget _deleteButton() => IconButton(
        tooltip: 'boxes.deleteEntry2'.tr,
        icon: const Icon(Symbols.delete, size: 18),
        onPressed: onDelete,
      );

  Widget _single(BuildContext context) {
    final item = transaction.items.single;
    final text = context.text;
    final date = DateTimeFormatter.ddMMyyyy(transaction.occurredAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.nameSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                transaction.total.formatted,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('boxes.eachAmountDate'.trParams({'formatted': item.unitPrice.formatted, 'date': date}), style: text.bodySmall),
                  if (!item.discount.isZero)
                    Text(
                      '${item.discountRule?.description ?? 'common.discount'.tr} · - ${item.discount.formatted}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: context.colors.primary),
                    ),
                ],
              ),
            ),
            _QuantityStepper(item: item, onChange: (delta) => onChangeQuantity(item, delta)),
            _deleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _multiple(BuildContext context) {
    final text = context.text;
    final title = (transaction.title != null && transaction.title!.trim().isNotEmpty)
        ? transaction.title!
        : 'boxes.purchasePluralCount'.trParams({'_plural': _plural(transaction.itemCount, 'common.productLower'.tr, 'common.productsLower'.tr)});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${DateTimeFormatter.ddMMyyyy(transaction.occurredAt)} · '
                    '${_plural(transaction.itemCount, 'common.productLower'.tr, 'common.productsLower'.tr)}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              transaction.total.formatted,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
            ),
            _deleteButton(),
          ],
        ),
        const Divider(height: AppSpacing.md),
        for (final item in transaction.items)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nameSnapshot, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                    Text(
                      item.discount.isZero
                          ? item.unitPrice.formatted
                          : '${item.unitPrice.formatted} · ${item.discountRule?.description ?? 'boxes.discounted'.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              _QuantityStepper(item: item, onChange: (delta) => onChangeQuantity(item, delta)),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: SizedBox(
                  width: 84,
                  child: Text(item.total.formatted, textAlign: TextAlign.right, style: text.bodyLarge),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Ajuste rápido de quantidade (− 2 +) direto no card da Box.
class _QuantityStepper extends StatelessWidget {
  final TransactionItemEntity item;
  final ValueChanged<double> onChange;

  const _QuantityStepper({required this.item, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'common.decrease'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Symbols.remove, size: 16),
          onPressed: item.quantity > 1 ? () => onChange(-1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            QuantityFormatter.format(item.quantity),
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'common.increase'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Symbols.add, size: 16),
          onPressed: () => onChange(1),
        ),
      ],
    );
  }
}
