import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_circle_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/box_closures/domain/usecases/get_box_closure_details.dart';
import 'package:buy_control/features/box_closures/presentation/controllers/box_closure_detail_controller.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BoxClosureDetailPage extends StatefulWidget {
  final String closureId;
  const BoxClosureDetailPage({super.key, required this.closureId});

  @override
  State<BoxClosureDetailPage> createState() => _BoxClosureDetailPageState();
}

class _BoxClosureDetailPageState extends State<BoxClosureDetailPage> {
  late final controller = Get.find<BoxClosureDetailController>(tag: widget.closureId);

  @override
  void dispose() {
    Get.delete<BoxClosureDetailController>(tag: widget.closureId);
    super.dispose();
  }

  Future<void> _showDetails(TransactionEntity transaction) {
    return AppBottomSheet.show(context, child: TransactionDetailSheet(transaction: transaction));
  }

  Future<void> _reopen() async {
    final details = controller.details;
    if (details == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reabrir este Fechamento?',
      message:
          'Os ${details.transactions.length} lançamentos voltarão a ficar abertos e editáveis. '
          'Esta ação desfaz o congelamento.',
      confirmLabel: 'Reabrir',
    );
    if (!confirmed) return;

    final error = await controller.reopen();
    if (!mounted) return;

    if (error != null) {
      Get.snackbar('Erro', error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoxClosureDetailController>(
      tag: widget.closureId,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const AppText.title('Fechamento')),
        body: _buildBody(controller),
        floatingActionButton: controller.details == null
            ? null
            : AppCircleButton(icon: LucideIcons.lockOpen, onPressed: _reopen),
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
        return _ClosureDetailBody(details: details, onTapTransaction: _showDetails);
    }
  }
}

class _ClosureDetailBody extends StatelessWidget {
  final BoxClosureDetails details;
  final ValueChanged<TransactionEntity> onTapTransaction;
  const _ClosureDetailBody({required this.details, required this.onTapTransaction});

  @override
  Widget build(BuildContext context) {
    final closure = details.closure;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.title(DateTimeFormatter.ddMMyyyy(closure.closedAt), fontSize: AppFontSizes.fz09),
              const SizedBox(height: AppSpacing.xs),
              AppText.subtitle('${closure.transactionCount} lançamentos · ${closure.itemCount} itens'),
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
        const AppText.subtitle('Lançamentos congelados'),
        const SizedBox(height: AppSpacing.sm),
        ...details.transactions.map((transaction) {
          final title = (transaction.title != null && transaction.title!.trim().isNotEmpty)
              ? transaction.title!
              : (transaction.items.isNotEmpty ? transaction.items.first.nameSnapshot : 'Lançamento');

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => onTapTransaction(transaction),
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
                  AppText(transaction.total.formatted, fontWeight: FontWeight.w600, color: AppColors.accent),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
