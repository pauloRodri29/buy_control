import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/core/formatters/quantity_formatter.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:buy_control/features/box_closures/presentation/controllers/box_closure_detail_controller.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Visualização somente leitura de um Fechamento: cabeçalho com data de
/// referência, quantidade de itens e total, seguido de todos os produtos
/// que compuseram aquele ciclo. Fechamentos são definitivos — não há
/// ação de reabrir nem de editar aqui.
class BoxClosureDetailPage extends StatefulWidget {
  final String closureId;
  const BoxClosureDetailPage({super.key, required this.closureId});

  @override
  State<BoxClosureDetailPage> createState() => _BoxClosureDetailPageState();
}

class _BoxClosureDetailPageState extends State<BoxClosureDetailPage> {
  @override
  void dispose() {
    Get.delete<BoxClosureDetailController>(tag: widget.closureId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoxClosureDetailController>(
      tag: widget.closureId,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const AppText.title('Fechamento', fontSize: AppFontSizes.fz09)),
        body: _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(BoxClosureDetailController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
      case ViewStatus.empty:
      case ViewStatus.success:
        final details = controller.details;
        if (details == null) {
          return ErrorStateView(message: 'Fechamento não encontrado.', onRetry: controller.load);
        }
        return _ClosureDetailBody(details: details);
    }
  }
}

class _ClosureDetailBody extends StatelessWidget {
  final BoxClosureDetails details;
  const _ClosureDetailBody({required this.details});

  @override
  Widget build(BuildContext context) {
    final closure = details.closure;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = details.transactions.expand((t) => t.items).toList()
      ..sort((a, b) => a.nameSnapshot.toLowerCase().compareTo(b.nameSnapshot.toLowerCase()));
    final generalDiscount = details.transactions.fold(0, (sum, t) => sum + t.discount.cents);
    final generalExtra = details.transactions.fold(0, (sum, t) => sum + t.additionalCost.cents);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.lock, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  AppText.subtitle(closure.boxNameSnapshot),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText.title(
                'Compras de ${DateTimeFormatter.ddMMyyyy(closure.referenceDate)}',
                fontSize: AppFontSizes.fz09,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle('${items.length} itens · fechado em ${DateTimeFormatter.ddMMyyyy(closure.closedAt)}'),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                closure.total.formatted,
                fontWeight: FontWeight.bold,
                fontSize: AppFontSizes.fz11,
                color: AppColors.accent,
              ),
              if (closure.notes != null && closure.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AppText(closure.notes!, color: AppColors.textSecondary(isDark)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppText.subtitle('Produtos'),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(child: _ItemRow(item: item)),
            )),
        if (generalDiscount != 0 || generalExtra != 0) ...[
          const Divider(),
          if (generalDiscount != 0) _TotalRow(label: 'Desconto na compra', value: '- ${Money(generalDiscount).formatted}'),
          if (generalExtra != 0) _TotalRow(label: 'Acréscimo', value: '+ ${Money(generalExtra).formatted}'),
          _TotalRow(label: 'Total', value: closure.total.formatted),
        ],
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  const _TotalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [AppText.subtitle(label), AppText(value, fontWeight: FontWeight.w600)],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TransactionItemEntity item;
  const _ItemRow({required this.item});

  String get _quantity {
    final q = item.quantity;
    return QuantityFormatter.format(q);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(item.nameSnapshot, fontWeight: FontWeight.w600),
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle('$_quantity × ${item.unitPrice.formatted}'),
              if (!item.discount.isZero)
                AppText(
                  '${item.discountRule?.description ?? 'Desconto'} · - ${item.discount.formatted}',
                  color: AppColors.accent,
                  fontSize: AppFontSizes.fz06,
                ),
            ],
          ),
        ),
        AppText(item.total.formatted, fontWeight: FontWeight.w600),
      ],
    );
  }
}
