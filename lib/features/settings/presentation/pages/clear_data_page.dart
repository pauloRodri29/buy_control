import 'package:buy_control/app/theme/app_colors.dart';
import 'package:buy_control/app/theme/app_font_sizes.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/features/settings/domain/usecases/clear_app_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClearDataPage extends StatelessWidget {
  const ClearDataPage({super.key});

  Future<void> _run(BuildContext context, ClearDataScope scope, {required String title, required String message}) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: 'Apagar',
    );
    if (!confirmed) return;

    final clearAppData = Get.find<ClearAppData>();
    await clearAppData(scope);

    if (context.mounted) {
      Get.snackbar('Dados apagados', 'A operação foi concluída.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const AppText.title('Limpar dados', fontSize: AppFontSizes.fz09)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppText.subtitle(
            'Cada opção abaixo apaga permanentemente uma parte dos seus dados. Não é possível desfazer.',
            color: AppColors.textSecondary(isDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ClearTile(
                  icon: LucideIcons.package,
                  label: 'Boxes',
                  onTap: () => _run(
                    context,
                    ClearDataScope.boxes,
                    title: 'Apagar todas as Boxes?',
                    message: 'Isso remove todas as Boxes e seus lançamentos/fechamentos. '
                        'Esta ação não pode ser desfeita.',
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: LucideIcons.shoppingBasket,
                  label: 'Produtos',
                  onTap: () => _run(
                    context,
                    ClearDataScope.products,
                    title: 'Apagar todos os Produtos?',
                    message: 'Isso remove todo o catálogo de produtos cadastrados. Categorias, tipos e '
                        'unidades não são afetados. Esta ação não pode ser desfeita.',
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: LucideIcons.history,
                  label: 'Histórico de compras',
                  onTap: () => _run(
                    context,
                    ClearDataScope.history,
                    title: 'Apagar o histórico de compras?',
                    message: 'Isso remove todos os lançamentos e fechamentos registrados nas Boxes. '
                        'As Boxes e o catálogo de produtos continuam existindo. Esta ação não pode ser '
                        'desfeita.',
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: LucideIcons.fileText,
                  label: 'Relatórios salvos',
                  onTap: () => _run(
                    context,
                    ClearDataScope.reports,
                    title: 'Apagar os relatórios salvos?',
                    message: 'Isso remove todas as combinações de filtros salvas na tela de Relatórios. '
                        'Esta ação não pode ser desfeita.',
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: LucideIcons.palette,
                  label: 'Preferências',
                  onTap: () => _run(
                    context,
                    ClearDataScope.preferences,
                    title: 'Restaurar preferências?',
                    message: 'Isso restaura as preferências de aparência e comportamento do app para o '
                        'padrão. Esta ação não pode ser desfeita.',
                  ),
                ),
                const Divider(height: 1),
                _ClearTile(
                  icon: LucideIcons.rotateCcw,
                  label: 'Restaurar tudo',
                  destructive: true,
                  onTap: () => _run(
                    context,
                    ClearDataScope.all,
                    title: 'Restaurar o app para o estado inicial?',
                    message: 'Isso apaga TODAS as Boxes, produtos, histórico de compras e relatórios '
                        'salvos, recria as categorias, tipos e unidades padrão e encerra sua sessão. '
                        'Esta ação não pode ser desfeita.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ClearTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: AppText(label, fontWeight: FontWeight.w600, color: color),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap,
    );
  }
}
