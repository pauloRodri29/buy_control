import 'package:buy_control/app/errors/failure_presenter.dart';
import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/theme/theme_context.dart';
import 'package:buy_control/app/widgets/app_button.dart';
import 'package:buy_control/app/widgets/app_card.dart';
import 'package:buy_control/app/widgets/app_feedback.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/app/widgets/app_text_field.dart';
import 'package:buy_control/app/widgets/confirm_dialog.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/domain/repositories/backup_remote.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Configura o repositório privado do GitHub que recebe os backups: o
/// link do repositório + um token pessoal. Sempre testa a conexão antes
/// de salvar.
class GithubSettingsPage extends StatefulWidget {
  const GithubSettingsPage({super.key});

  @override
  State<GithubSettingsPage> createState() => _GithubSettingsPageState();
}

class _GithubSettingsPageState extends State<GithubSettingsPage> {
  final _controller = Get.find<BackupController>();
  final _repoField = TextEditingController();
  final _tokenField = TextEditingController();
  bool _showToken = false;
  bool _working = false;
  String? _repoError;
  String? _tokenError;

  /// Resultado do último teste (sucesso ou falha) para mostrar na tela.
  Result<RemoteTargetInfo>? _lastTest;

  static const _tokenUrl = 'https://github.com/settings/personal-access-tokens/new';
  static const _newRepoUrl = 'https://github.com/new';

  @override
  void initState() {
    super.initState();
    final config = _controller.config;
    if (config != null) _repoField.text = 'https://github.com/${config.fullName}';
  }

  @override
  void dispose() {
    _repoField.dispose();
    _tokenField.dispose();
    super.dispose();
  }

  bool get _isConfigured => _controller.config != null;

  /// Valida os campos. Com a nuvem já configurada, token vazio = manter o
  /// token salvo.
  Future<(GithubBackupConfig, String)?> _readInput() async {
    final config = GithubBackupConfig.parseRepository(_repoField.text);
    var token = _tokenField.text.trim();
    if (token.isEmpty && _isConfigured) token = await _controller.settings.readToken() ?? '';
    setState(() {
      _repoError = config == null ? 'backup.useRepositoryLinkEG'.tr : null;
      _tokenError = token.isEmpty ? 'backup.pasteTokenGeneratedGithub'.tr : null;
    });
    if (config == null || token.isEmpty) return null;
    return (config, token);
  }

  Future<void> _run(Future<Result<RemoteTargetInfo>> Function(GithubBackupConfig, String) action,
      {required bool closeOnSuccess}) async {
    final input = await _readInput();
    if (input == null) return;
    setState(() {
      _working = true;
      _lastTest = null;
    });
    final result = await action(input.$1, input.$2);
    if (!mounted) return;
    setState(() {
      _working = false;
      _lastTest = result;
    });
    if (result.isSuccess && closeOnSuccess) {
      AppFeedback.success('backup.backupsWillSentFullName'.trParams({'fullName': input.$1.fullName}), title: 'backup.githubSetUp'.tr);
      Get.back();
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'backup.disconnectGithub'.tr,
      message: 'backup.tokenDeletedFromDeviceBackups'.tr,
      confirmLabel: 'backup.disconnect'.tr,
    );
    if (!confirmed) return;
    await _controller.disconnectGithub();
    AppFeedback.info('backup.tokenWasDeletedFromDevice'.tr, title: 'backup.githubDisconnected'.tr);
    Get.back();
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.info(text, title: 'backup.linkCopied'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('backup.githubBackup'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Instructions(onCopy: _copy, tokenUrl: _tokenUrl, newRepoUrl: _newRepoUrl),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _repoField,
            label: 'backup.repositoryLink'.tr,
            hint: 'https://github.com/voce/gastolog-backup',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            errorText: _repoError,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _tokenField,
            label: _isConfigured ? 'backup.tokenLeaveEmptyKeepCurrent'.tr : 'backup.personalToken'.tr,
            hint: 'github_pat_…',
            obscureText: !_showToken,
            errorText: _tokenError,
            suffix: IconButton(
              tooltip: _showToken ? 'backup.hide'.tr : 'backup.show'.tr,
              icon: Icon(_showToken ? Symbols.visibility_off : Symbols.visibility),
              onPressed: () => setState(() => _showToken = !_showToken),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText.caption('backup.tokenStoredEncryptedDeviceOnly'.tr),
          if (_lastTest != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _TestResult(result: _lastTest!),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_working)
            const Center(child: CircularProgressIndicator())
          else ...[
            AppButton.secondary(
              label: 'backup.testConnection'.tr,
              icon: Symbols.network_check,
              onPressed: () => _run(_controller.testGithub, closeOnSuccess: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'backup.testSave'.tr,
              icon: Symbols.save,
              onPressed: () => _run(_controller.saveGithub, closeOnSuccess: true),
            ),
            if (_isConfigured) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(child: AppButton.text(label: 'backup.disconnect'.tr, icon: Symbols.link_off, onPressed: _disconnect)),
            ],
          ],
        ],
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  final void Function(String) onCopy;
  final String tokenUrl;
  final String newRepoUrl;

  const _Instructions({required this.onCopy, required this.tokenUrl, required this.newRepoUrl});

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String text, {String? url}) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: context.colors.primaryContainer,
              child: Text('$n', style: context.text.labelSmall?.copyWith(color: context.colors.onPrimaryContainer)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.small(text),
                  if (url != null)
                    InkWell(
                      onTap: () => onCopy(url),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Flexible(
                              child: AppText.small(url, color: context.colors.primary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Icon(Symbols.content_copy, size: 14, color: context.colors.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('backup.howSetUpFreeJust'.tr, fontWeight: FontWeight.w700),
          step(1, 'backup.createPrivateRepositoryGithubE'.tr, url: newRepoUrl),
          step(2, 'backup.generateFineGrainedToken'.tr, url: tokenUrl),
          step(3, 'backup.underRepositoryAccessChooseOnly'.tr),
          step(4, 'backup.underPermissionsContentsChooseRead'.tr),
          step(5, 'backup.setExpirationEG1'.tr),
          step(6, 'backup.pasteRepositoryLinkTokenBelow'.tr),
        ],
      ),
    );
  }
}

class _TestResult extends StatelessWidget {
  final Result<RemoteTargetInfo> result;

  const _TestResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final info = result.dataOrNull;
    final ok = info != null;
    final text = ok
        ? 'backup.connectedPrivateBranchDisplayNameDefaultBranch'.trParams({'displayName': info.displayName, 'defaultBranch': info.defaultBranch})
        : FailurePresenter.present(result.failureOrNull!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ok ? context.semantic.successContainer : context.colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Symbols.check_circle : Symbols.error,
              size: 20, color: ok ? context.semantic.success : context.colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText.small(text, color: ok ? context.colors.onSurface : context.colors.onErrorContainer),
          ),
        ],
      ),
    );
  }
}
