import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/domain/repositories/backup_remote.dart';
import 'package:http/http.dart' as http;

/// Backup num repositório PRIVADO do GitHub, pela API REST "Contents".
///
/// - O backup é um único arquivo JSON ([GithubBackupConfig.path]).
/// - Cada envio é um commit que substitui o arquivo: o histórico de
///   commits do arquivo é o histórico de backups, e qualquer versão pode
///   ser baixada de volta.
/// - Autenticação por token pessoal (fine-grained) com permissão
///   "Contents: Read and write" só nesse repositório.
class GithubBackupRemote implements BackupRemote {
  final GithubBackupConfig config;
  final String token;
  final http.Client client;
  final Duration timeout;

  GithubBackupRemote({
    required this.config,
    required this.token,
    required this.client,
    this.timeout = const Duration(seconds: 25),
  });

  static const _host = 'api.github.com';

  Map<String, String> _headers({bool raw = false}) => {
        'Authorization': 'Bearer $token',
        'Accept': raw ? 'application/vnd.github.raw+json' : 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'GastoLog-App',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.https(_host, path, query);

  String get _repoPath => '/repos/${config.owner}/${config.repo}';
  String get _contentsPath => '$_repoPath/contents/${config.path}';

  @override
  Future<Result<RemoteTargetInfo>> testConnection() async {
    return _guard(() async {
      final response = await client.get(_uri(_repoPath), headers: _headers()).timeout(timeout);
      if (response.statusCode != 200) return Failure(_failureFor(response));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final isPrivate = body['private'] == true;
      if (!isPrivate) {
        return Failure(ValidationFailure(
          'backup.repositoryPublicAnyoneCouldSeeFullName'.trParams({'fullName': config.fullName}),
        ));
      }
      final permissions = body['permissions'];
      if (permissions is Map && permissions['push'] == false) {
        return Failure(ValidationFailure(
          'backup.accountOnlyHasReadAccessFullName'.trParams({'fullName': config.fullName}),
        ));
      }
      return Success(RemoteTargetInfo(
        displayName: '${body['full_name'] ?? config.fullName}',
        webUrl: '${body['html_url'] ?? 'https://github.com/${config.fullName}'}',
        isPrivate: isPrivate,
        defaultBranch: '${body['default_branch'] ?? 'main'}',
      ));
    });
  }

  @override
  Future<Result<RemoteBackupFile?>> fetchLatest() async {
    return _guard(() async {
      final meta = await client.get(_uri(_contentsPath), headers: _headers()).timeout(timeout);
      // 404 = arquivo ainda não existe (ou repositório vazio): primeiro envio.
      if (meta.statusCode == 404) return const Success(null);
      if (meta.statusCode != 200) return Failure(_failureFor(meta));

      final decoded = jsonDecode(meta.body);
      if (decoded is! Map || decoded['type'] != 'file') {
        return Failure(ValidationFailure(
          'backup.pathRepositoryNotFileRemove'.trParams({'path': config.path}),
        ));
      }
      final sha = '${decoded['sha']}';
      final content = await _downloadRaw(null);
      return content.fold((text) => Success(RemoteBackupFile(content: text, sha: sha)), Failure.new);
    });
  }

  @override
  Future<Result<RemoteBackupVersion>> upload(String content, {required String message, String? expectedSha}) async {
    return _guard(() async {
      final response = await client
          .put(
            _uri(_contentsPath),
            headers: _headers(),
            body: jsonEncode({
              'message': message,
              'content': base64Encode(utf8.encode(content)),
              if (expectedSha != null) 'sha': expectedSha,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 409 || response.statusCode == 422) {
        return Failure(ValidationFailure(
          'backup.cloudBackupChangedSinceYou'.tr,
        ));
      }
      if (response.statusCode != 200 && response.statusCode != 201) return Failure(_failureFor(response));

      final commit = (jsonDecode(response.body) as Map)['commit'] as Map? ?? const {};
      return Success(RemoteBackupVersion(
        ref: '${commit['sha'] ?? ''}',
        date: DateTime.tryParse('${(commit['author'] as Map?)?['date']}')?.toLocal() ?? DateTime.now(),
        message: '${commit['message'] ?? message}',
        webUrl: commit['html_url'] as String?,
      ));
    });
  }

  @override
  Future<Result<List<RemoteBackupVersion>>> history({int limit = 30}) async {
    return _guard(() async {
      final response = await client
          .get(_uri('$_repoPath/commits', {'path': config.path, 'per_page': '$limit'}), headers: _headers())
          .timeout(timeout);
      // 409 = repositório vazio: ainda não há histórico.
      if (response.statusCode == 409) return const Success(<RemoteBackupVersion>[]);
      if (response.statusCode != 200) return Failure(_failureFor(response));

      final list = jsonDecode(response.body) as List;
      return Success([
        for (final item in list.whereType<Map>())
          RemoteBackupVersion(
            ref: '${item['sha']}',
            date: DateTime.tryParse('${((item['commit'] as Map?)?['author'] as Map?)?['date']}')?.toLocal() ??
                DateTime.fromMillisecondsSinceEpoch(0),
            message: '${(item['commit'] as Map?)?['message'] ?? ''}',
            webUrl: item['html_url'] as String?,
          ),
      ]);
    });
  }

  @override
  Future<Result<String>> download(String ref) => _guard(() => _downloadRaw(ref));

  Future<Result<String>> _downloadRaw(String? ref) async {
    final response = await client
        .get(_uri(_contentsPath, ref == null ? null : {'ref': ref}), headers: _headers(raw: true))
        .timeout(timeout);
    if (response.statusCode == 404) {
      return Failure(NotFoundFailure('backup.backupVersionWasNotFound'.tr));
    }
    if (response.statusCode != 200) return Failure(_failureFor(response));
    return Success(utf8.decode(response.bodyBytes));
  }

  /// Converte problemas de rede em [NetworkFailure] com mensagem clara.
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() run) async {
    try {
      return await run();
    } on TimeoutException {
      return Failure(NetworkFailure(
        'backup.githubTookTooLongRespond'.tr,
      ));
    } on SocketException {
      return Failure(NetworkFailure('backup.noInternetConnectionConnectTry'.tr));
    } on HandshakeException {
      return Failure(NetworkFailure(
        'backup.couldntOpenSecureConnectionGithub'.tr,
      ));
    } on http.ClientException {
      return Failure(NetworkFailure('backup.noInternetConnectionConnectTry'.tr));
    } on FormatException {
      return Failure(UnknownFailure('backup.githubReturnedSomethingUnexpectedTry'.tr));
    }
  }

  AppFailure _failureFor(http.Response response) {
    final code = response.statusCode;
    final apiMessage = _apiMessage(response);
    switch (code) {
      case 401:
        return NetworkFailure(
          'backup.githubRejectedTokenInvalidRevoked'.tr,
        );
      case 403 || 429:
        if (response.headers['x-ratelimit-remaining'] == '0' || code == 429) {
          return NetworkFailure('backup.githubApiRateLimitReached'.tr);
        }
        return NetworkFailure(
          'backup.tokenHasNoPermissionCheckFullName'.trParams({'fullName': config.fullName}),
        );
      case 404:
        return NetworkFailure(
          'backup.repositoryNotFoundCheckLinkFullName'.trParams({'fullName': config.fullName}),
        );
      default:
        if (code >= 500) {
          return NetworkFailure('backup.githubUnstableRightNowErrorCode'.trParams({'code': '$code'}));
        }
        return NetworkFailure('backup.githubRespondedErrorCodeValue'.trParams({'code': '$code', 'value': apiMessage == null ? '' : ': $apiMessage'}));
    }
  }

  String? _apiMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body is Map && body['message'] is String ? body['message'] as String : null;
    } catch (_) {
      return null;
    }
  }
}
