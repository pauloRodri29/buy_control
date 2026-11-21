import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/backup/domain/repositories/backup_remote.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:buy_control/features/backup/presentation/widgets/backup_busy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Versões do backup guardadas no GitHub (uma por envio). Tocar numa
/// versão baixa e abre o resumo do que muda antes de restaurar.
class BackupHistoryPage extends StatefulWidget {
  const BackupHistoryPage({super.key});

  @override
  State<BackupHistoryPage> createState() => _BackupHistoryPageState();
}

class _BackupHistoryPageState extends State<BackupHistoryPage> {
  final _controller = Get.find<BackupController>();
  List<RemoteBackupVersion>? _versions;
  AppFailure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await _controller.loadHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _versions = result.dataOrNull;
      _failure = result.failureOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('backup.cloudHistory'.tr),
        actions: [
          IconButton(tooltip: 'backup.refresh'.tr, icon: const Icon(Symbols.refresh), onPressed: _loading ? null : _load),
        ],
      ),
      body: BackupBusyOverlay(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final failure = _failure;
    if (failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.cloud_off, size: 40, color: context.colors.error),
              const SizedBox(height: AppSpacing.md),
              AppText(FailurePresenter.present(failure), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'backup.tryAgain'.tr, expanded: false, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final versions = _versions ?? const [];
    if (versions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AppText.subtitle('backup.noBackupCloudYetUse'.tr,
              textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: versions.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppText.subtitle(
            'backup.tapVersionSeeWhatChanges'.tr,
          );
        }
        final version = versions[index - 1];
        final isLatest = index == 1;
        return Card(
          child: ListTile(
            leading: Icon(isLatest ? Symbols.cloud_done : Symbols.history,
                color: isLatest ? context.colors.primary : null),
            title: Row(
              children: [
                Flexible(child: Text(DateTimeFormatter.ddMMyyyyHHmm(version.date))),
                if (isLatest) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('backup.latest'.tr,
                        style: context.text.labelSmall?.copyWith(color: context.colors.onPrimaryContainer)),
                  ),
                ],
              ],
            ),
            subtitle: Text(version.details.isEmpty ? version.title : version.details),
            isThreeLine: version.details.contains('\n'),
            trailing: const Icon(Symbols.settings_backup_restore, size: 20),
            onTap: () => _controller.restoreFromCloud(version),
          ),
        );
      },
    );
  }
}
