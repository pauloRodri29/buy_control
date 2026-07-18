import 'package:buy_control/app/state/view_status.dart';
import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/empty_state_view.dart';
import 'package:buy_control/app/widgets/error_state_view.dart';
import 'package:buy_control/app/widgets/loading_skeleton.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/presentation/bindings/box_closure_detail_binding.dart';
import 'package:buy_control/features/box_closures/presentation/controllers/box_closures_controller.dart';
import 'package:buy_control/features/box_closures/presentation/pages/box_closure_detail_page.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BoxClosuresPage extends StatefulWidget {
  final BoxEntity box;
  const BoxClosuresPage({super.key, required this.box});

  @override
  State<BoxClosuresPage> createState() => _BoxClosuresPageState();
}

class _BoxClosuresPageState extends State<BoxClosuresPage> {
  late final controller = Get.find<BoxClosuresController>(tag: widget.box.id);

  @override
  void dispose() {
    Get.delete<BoxClosuresController>(tag: widget.box.id);
    super.dispose();
  }

  Future<void> _openDetail(BoxClosureEntity closure) async {
    BoxClosureDetailBinding(closure.id).dependencies();
    final reopened = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BoxClosureDetailPage(closureId: closure.id),
    ));
    if (reopened == true) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.title('Fechamentos')),
      body: GetBuilder<BoxClosuresController>(
        tag: widget.box.id,
        builder: (controller) => _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(BoxClosuresController controller) {
    switch (controller.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const LoadingSkeletonList();
      case ViewStatus.error:
        return ErrorStateView(message: controller.errorMessage ?? 'Erro inesperado.', onRetry: controller.load);
      case ViewStatus.empty:
        return const EmptyStateView(
          icon: LucideIcons.archive,
          title: 'Nenhum Fechamento ainda',
          message: 'Feche a Box para começar o histórico.',
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.closures.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final closure = controller.closures[i];
            return _ClosureCard(closure: closure, onTap: () => _openDetail(closure));
          },
        );
    }
  }
}

class _ClosureCard extends StatelessWidget {
  final BoxClosureEntity closure;
  final VoidCallback onTap;
  const _ClosureCard({required this.closure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(DateTimeFormatter.ddMMyyyy(closure.closedAt), fontWeight: FontWeight.w600),
                const SizedBox(height: AppSpacing.xs),
                AppText.subtitle('${closure.transactionCount} lançamentos · ${closure.itemCount} itens'),
              ],
            ),
          ),
          AppText(closure.total.formatted, fontWeight: FontWeight.w600, color: AppColors.accent),
        ],
      ),
    );
  }
}
