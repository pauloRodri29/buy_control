import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:buy_control/features/backup/presentation/pages/backup_history_page.dart';
import 'package:buy_control/features/backup/presentation/pages/github_settings_page.dart';
import 'package:buy_control/features/backup/presentation/widgets/backup_busy_overlay.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Central de backup: nuvem (GitHub), arquivo, desfazer importação e o
/// registro das últimas operações (com sucesso ou erro).
class BackupPage extends GetView<BackupController> {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('common.backupRestore'.tr)),
      body: BackupBusyOverlay(
        child: GetBuilder<BackupController>(
          builder: (c) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SectionTitle('backup.cloudGithub'.tr),
              _CloudCard(controller: c),
              if (c.safetyInfo != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle('backup.safety'.tr),
                _UndoCard(controller: c),
              ],
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('backup.file'.tr),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Symbols.file_save),
                      title: Text('backup.exportFile'.tr),
                      subtitle: Text('backup.createsJsonKeepShare'.tr),
                      trailing: const Icon(Symbols.chevron_right, size: 18),
                      onTap: c.isBusy ? null : c.exportToFile,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Symbols.file_open),
                      title: Text('backup.importFromFile'.tr),
                      subtitle: Text('backup.showsSummaryBeforeReplacing'.tr),
                      trailing: const Icon(Symbols.chevron_right, size: 18),
                      onTap: c.isBusy ? null : c.importFromFile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('backup.recentActivity'.tr),
              _ActivityList(entries: c.log),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text.toUpperCase(), style: context.text.labelMedium),
    );
  }
}

class _CloudCard extends StatelessWidget {
  final BackupController controller;

  const _CloudCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final config = c.config;

    if (config == null) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.cloud_off, color: context.colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                AppText('backup.cloudNotSetUp'.tr, fontWeight: FontWeight.w700),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText.subtitle(
              'backup.keepBackupsPrivateGithubRepository'.tr,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'backup.setUpGithub'.tr,
              icon: Symbols.settings,
              onPressed: () => Get.to(() => const GithubSettingsPage()),
            ),
          ],
        ),
      );
    }

    final lastUpload = c.lastSuccessfulUpload;
    final lastAttempt = c.lastCloudAttempt;
    final lastFailed = lastAttempt != null && !lastAttempt.success;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.cloud_done, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppText(config.fullName, fontWeight: FontWeight.w700, overflow: TextOverflow.ellipsis)),
              IconButton(
                tooltip: 'backup.settings'.tr,
                icon: const Icon(Symbols.settings, size: 20),
                onPressed: () => Get.to(() => const GithubSettingsPage()),
              ),
            ],
          ),
          AppText.subtitle(
            lastUpload == null
                ? 'backup.noBackupSentFromDevice'.tr
                : 'backup.lastBackupSentDateTimeRelative'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(lastUpload.at), 'relative': DateTimeFormatter.relative(lastUpload.at)}),
          ),
          if (lastFailed) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.error, size: 20, color: context.colors.onErrorContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText.small(
                      'backup.lastAttemptFailedNameDateTimeMessage'.trParams({'toLowerCase': lastAttempt.operation.label.toLowerCase(), 'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(lastAttempt.at), 'message': lastAttempt.message}),
                      color: context.colors.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'backup.sendNow'.tr,
                  icon: Symbols.cloud_upload,
                  onPressed: c.isBusy ? null : c.uploadNow,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: 'common.history'.tr,
                  icon: Symbols.history,
                  onPressed: c.isBusy ? null : () => Get.to(() => const BackupHistoryPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UndoCard extends StatelessWidget {
  final BackupController controller;

  const _UndoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final info = controller.safetyInfo!;
    return Card(
      child: ListTile(
        leading: const Icon(Symbols.undo),
        title: Text('backup.undoLastImport'.tr),
        subtitle: Text(
          'backup.bringsDataBackHowWasDateTimeReplacedBy'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(info.createdAt), 'replacedBy': info.replacedBy}),
        ),
        trailing: const Icon(Symbols.chevron_right, size: 18),
        onTap: controller.isBusy ? null : controller.undoLastImport,
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<BackupLogEntry> entries;

  const _ActivityList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return AppText.subtitle('backup.noBackupOperationsYet'.tr);
    }
    final shown = entries.take(10).toList();
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(
                shown[i].success ? Symbols.check_circle : Symbols.error,
                color: shown[i].success ? context.semantic.success : context.colors.error,
              ),
              title: Text(shown[i].operation.label),
              subtitle: Text('${DateTimeFormatter.ddMMyyyyHHmm(shown[i].at)} · ${shown[i].message}'),
            ),
          ],
        ],
      ),
    );
  }
}
