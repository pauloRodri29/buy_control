import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';
import 'package:buy_control/features/backup/domain/entities/backup_diff.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Sentido da operação: muda os rótulos e avisos do resumo.
enum BackupDirection {
  /// Dados de um backup (arquivo/nuvem) substituem os do aparelho.
  restore,

  /// Dados do aparelho viram a nova versão na nuvem.
  upload,

  /// Volta a cópia de segurança tirada antes da última importação.
  undo,
}

class BackupPreviewArgs {
  final BackupDirection direction;
  final BackupDiff diff;
  final String sourceTitle;
  final String sourceSubtitle;
  final List<String> notes;

  const BackupPreviewArgs({
    required this.direction,
    required this.diff,
    required this.sourceTitle,
    required this.sourceSubtitle,
    this.notes = const [],
  });
}

/// Resumo de tudo o que uma operação de backup vai mudar, mostrado ANTES
/// de ela acontecer: totais, avisos de risco e, por tipo de dado, a lista
/// do que entra, sai e muda. Devolve `true` só se o usuário confirmar.
class BackupPreviewPage extends StatelessWidget {
  final BackupPreviewArgs args;

  const BackupPreviewPage({super.key, required this.args});

  static Future<bool> open(BackupPreviewArgs args) async {
    final result = await Get.to<bool>(() => BackupPreviewPage(args: args), fullscreenDialog: true);
    return result ?? false;
  }

  bool get _isUpload => args.direction == BackupDirection.upload;

  String get _pageTitle => switch (args.direction) {
        BackupDirection.restore => 'backup.reviewBeforeRestoring'.tr,
        BackupDirection.upload => 'backup.reviewBeforeSending'.tr,
        BackupDirection.undo => 'backup.undoImport'.tr,
      };

  String get _confirmLabel => switch (args.direction) {
        BackupDirection.restore => 'backup.replaceMyData'.tr,
        BackupDirection.upload => 'backup.sendCloud'.tr,
        BackupDirection.undo => 'backup.backPreviousData'.tr,
      };

  String get _currentLabel => _isUpload ? 'backup.cloud'.tr : 'backup.device'.tr;

  String get _afterLabel => _isUpload ? 'backup.willStayCloud'.tr : 'backup.willStayDevice'.tr;

  List<_Warning> _warnings() {
    final diff = args.diff;
    final warnings = <_Warning>[];

    if (!diff.hasChanges) {
      warnings.add(_Warning.info(
        'backup.nothingChangesContentIdenticalYou'.tr,
      ));
    }
    if (!_isUpload && diff.incomingIsOlderThanCurrentData) {
      warnings.add(_Warning.danger(
        'backup.backupFromButDataWasDateTime'.trParams({'ddMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(diff.incoming.exportedAt!), 'vBDdMMyyyyHHmm': DateTimeFormatter.ddMMyyyyHHmm(diff.currentLastChange!)}),
      ));
    }
    if (diff.totalCurrentIsNewer > 0) {
      warnings.add(_Warning.danger(_isUpload
          ? 'backup.recordSCloudAreNewerTotalCurrentIsNewer'.trParams({'totalCurrentIsNewer': '${diff.totalCurrentIsNewer}'})
          : 'backup.recordSDeviceAreNewerTotalCurrentIsNewer'.trParams({'totalCurrentIsNewer': '${diff.totalCurrentIsNewer}'})));
    }
    if (diff.totalRemoved > 0) {
      warnings.add(_isUpload
          ? _Warning.warning(
              'backup.recordSCloudDontExistTotalRemoved'.trParams({'totalRemoved': '${diff.totalRemoved}'}))
          : _Warning.danger('backup.recordSDeviceAreNotTotalRemoved'.trParams({'totalRemoved': '${diff.totalRemoved}'})));
    }
    for (final kept in diff.keptCollections) {
      warnings.add(_Warning.info(
        'backup.backupDoesntIncludeFromOlderLabel'.trParams({'label': kept.collection.label}),
      ));
    }
    for (final note in args.notes) {
      warnings.add(_Warning.info(note));
    }
    warnings.add(_Warning.safe(switch (args.direction) {
      BackupDirection.restore =>
        'backup.beforeReplacingCopyCurrentData'.tr,
      BackupDirection.upload => 'backup.versionCurrentlyCloudStaysHistory'.tr,
      BackupDirection.undo => 'backup.dataGoesBackExactlyWas'.tr,
    }));
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final diff = args.diff;

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Row(
              children: [
                Icon(_isUpload ? Symbols.cloud_upload : Symbols.settings_backup_restore,
                    color: context.colors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(args.sourceTitle, fontWeight: FontWeight.w700),
                      const SizedBox(height: 2),
                      AppText.subtitle(args.sourceSubtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: _isUpload ? 'backup.new'.tr : 'backup.incoming'.tr,
                  value: diff.totalAdded,
                  color: context.semantic.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(label: 'backup.changing'.tr, value: diff.totalChanged, color: context.semantic.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: _isUpload ? 'backup.outgoing'.tr : 'backup.deleted'.tr,
                  value: diff.totalRemoved,
                  color: context.colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText.caption('backup.recordSStaySameTotalUnchanged'.trParams({'totalUnchanged': '${diff.totalUnchanged}'})),
          const SizedBox(height: AppSpacing.lg),
          for (final w in _warnings()) ...[
            _WarningBox(warning: w),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('backup.detailsType'.tr, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < diff.collections.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _CollectionTile(
                    diff: diff.collections[i],
                    currentLabel: _currentLabel,
                    afterLabel: _afterLabel,
                    isUpload: _isUpload,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(label: 'common.cancel'.tr, onPressed: () => Get.back(result: false)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: _isUpload
                    ? AppButton(label: _confirmLabel, icon: Symbols.cloud_upload, onPressed: () => Get.back(result: true))
                    : AppButton.danger(label: _confirmLabel, onPressed: () => Get.back(result: true)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('$value', color: value == 0 ? context.colors.onSurfaceVariant : color),
          AppText.subtitle(label),
        ],
      ),
    );
  }
}

enum _WarningKind { danger, warning, info, safe }

class _Warning {
  final _WarningKind kind;
  final String text;

  const _Warning.danger(this.text) : kind = _WarningKind.danger;
  const _Warning.warning(this.text) : kind = _WarningKind.warning;
  const _Warning.info(this.text) : kind = _WarningKind.info;
  const _Warning.safe(this.text) : kind = _WarningKind.safe;
}

class _WarningBox extends StatelessWidget {
  final _Warning warning;

  const _WarningBox({required this.warning});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final (icon, background, foreground) = switch (warning.kind) {
      _WarningKind.danger => (Symbols.warning, colors.errorContainer, colors.onErrorContainer),
      _WarningKind.warning => (Symbols.error, semantic.warningContainer, colors.onSurface),
      _WarningKind.info => (Symbols.info, colors.surfaceContainerHighest, colors.onSurface),
      _WarningKind.safe => (Symbols.verified_user, semantic.successContainer, colors.onSurface),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppText.small(warning.text, color: foreground)),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final CollectionDiff diff;
  final String currentLabel;
  final String afterLabel;
  final bool isUpload;

  const _CollectionTile({
    required this.diff,
    required this.currentLabel,
    required this.afterLabel,
    required this.isUpload,
  });

  static const _maxListed = 30;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (diff.added.isNotEmpty) '+${diff.added.length}',
      if (diff.changed.isNotEmpty) '~${diff.changed.length}',
      if (diff.removed.isNotEmpty) '−${diff.removed.length}',
    ];
    final subtitle = !diff.includedInIncoming
        ? 'backup.notIncludedBackupKeptCurrentCount'.trParams({'currentCount': '${diff.currentCount}'})
        : '$currentLabel: ${diff.currentCount} → $afterLabel: ${diff.incomingCount}'
            '${parts.isEmpty ? 'backup.noChanges'.tr : ' · ${parts.join(' ')}'}';

    if (!diff.hasChanges) {
      return ListTile(
        title: Text(diff.collection.label),
        subtitle: Text(subtitle),
        trailing: Icon(Symbols.check, size: 18, color: context.colors.onSurfaceVariant),
      );
    }

    return ExpansionTile(
      title: Text(diff.collection.label),
      subtitle: Text(subtitle),
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecordList(
          title: isUpload ? 'backup.newCloud'.tr : 'backup.incoming'.tr,
          records: diff.added,
          color: context.semantic.success,
          max: _maxListed,
        ),
        _RecordList(
          title: isUpload ? 'backup.updated'.tr : 'backup.replacedBackupVersion'.tr,
          records: diff.changed,
          color: context.semantic.warning,
          max: _maxListed,
        ),
        _RecordList(
          title: isUpload ? 'backup.leavingLatestBackup'.tr : 'backup.willDeleted'.tr,
          records: diff.removed,
          color: context.colors.error,
          max: _maxListed,
        ),
      ],
    );
  }
}

class _RecordList extends StatelessWidget {
  final String title;
  final List<BackupRecordRef> records;
  final Color color;
  final int max;

  const _RecordList({required this.title, required this.records, required this.color, required this.max});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final shown = records.take(max).toList();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.small('$title (${records.length})', fontWeight: FontWeight.w700, color: color),
          const SizedBox(height: AppSpacing.xs),
          for (final r in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                    child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ),
                  Expanded(child: AppText.small(r.label)),
                  if (r.updatedAt != null) AppText.caption(DateTimeFormatter.ddMMyyyy(r.updatedAt!)),
                ],
              ),
            ),
          if (records.length > shown.length) AppText.caption('backup.moreValue'.trParams({'value': '${records.length - shown.length}'})),
        ],
      ),
    );
  }
}
