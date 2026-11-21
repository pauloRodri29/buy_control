import 'package:buy_control/core/result/result.dart';

/// Repositório remoto validado pelo teste de conexão.
class RemoteTargetInfo {
  final String displayName;
  final String webUrl;
  final bool isPrivate;
  final String defaultBranch;

  const RemoteTargetInfo({
    required this.displayName,
    required this.webUrl,
    required this.isPrivate,
    required this.defaultBranch,
  });
}

/// Uma versão do backup no histórico remoto.
class RemoteBackupVersion {
  /// Identificador para baixar exatamente esta versão (sha do commit).
  final String ref;
  final DateTime date;

  /// Mensagem gravada no envio: 1ª linha = título, resto = resumo.
  final String message;
  final String? webUrl;

  const RemoteBackupVersion({required this.ref, required this.date, required this.message, this.webUrl});

  String get title => message.split('\n').first.trim();

  String get details => message.split('\n').skip(1).where((l) => l.trim().isNotEmpty).join('\n').trim();
}

/// Conteúdo atual do backup remoto + a "impressão digital" (sha) usada
/// para garantir que ninguém alterou o arquivo entre a conferência e o
/// envio.
class RemoteBackupFile {
  final String content;
  final String sha;

  const RemoteBackupFile({required this.content, required this.sha});
}

/// Destino de backup na nuvem. Hoje só o GitHub implementa; outro
/// provedor (WebDAV, Drive…) entra implementando esta interface.
abstract class BackupRemote {
  Future<Result<RemoteTargetInfo>> testConnection();

  /// Backup mais recente, ou `null` se ainda não houver nenhum.
  Future<Result<RemoteBackupFile?>> fetchLatest();

  /// Grava [content] como nova versão. [expectedSha] é o sha lido em
  /// [fetchLatest] (`null` se não havia arquivo); se o remoto mudou desde
  /// então, falha em vez de sobrescrever.
  Future<Result<RemoteBackupVersion>> upload(String content, {required String message, String? expectedSha});

  /// Versões mais recentes primeiro.
  Future<Result<List<RemoteBackupVersion>>> history({int limit = 30});

  Future<Result<String>> download(String ref);
}
