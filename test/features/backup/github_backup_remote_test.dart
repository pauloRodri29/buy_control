import 'dart:convert';
import 'dart:io';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/data/github_backup_remote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = GithubBackupConfig(owner: 'joao', repo: 'backup');

GithubBackupRemote _remote(Future<http.Response> Function(http.Request) handler) =>
    GithubBackupRemote(config: _config, token: 'tok', client: MockClient(handler));

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  group('testConnection', () {
    test('aceita repositório privado e envia o token', () async {
      late http.Request sent;
      final remote = _remote((req) async {
        sent = req;
        return _json({
          'full_name': 'joao/backup',
          'private': true,
          'html_url': 'https://github.com/joao/backup',
          'default_branch': 'main',
          'permissions': {'push': true},
        }, 200);
      });

      final result = await remote.testConnection();

      expect(result.dataOrNull?.displayName, 'joao/backup');
      expect(sent.url.toString(), 'https://api.github.com/repos/joao/backup');
      expect(sent.headers['Authorization'], 'Bearer tok');
    });

    test('recusa repositório público', () async {
      final remote = _remote((_) async => _json({'private': false}, 200));
      final failure = (await remote.testConnection()).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('PÚBLICO'));
    });

    test('traduz 401, 404 e 5xx em mensagens claras', () async {
      expect((await _remote((_) async => _json({}, 401)).testConnection()).failureOrNull!.message,
          contains('recusou o token'));
      expect((await _remote((_) async => _json({}, 404)).testConnection()).failureOrNull!.message,
          contains('não encontrado'));
      expect((await _remote((_) async => _json({}, 503)).testConnection()).failureOrNull!.message,
          contains('instável'));
    });

    test('sem internet vira NetworkFailure', () async {
      final remote = _remote((_) async => throw const SocketException('offline'));
      final failure = (await remote.testConnection()).failureOrNull;
      expect(failure, isA<NetworkFailure>());
      expect(failure!.message, contains('Sem conexão'));
    });
  });

  group('fetchLatest / upload', () {
    test('sem arquivo ainda devolve null (primeiro envio)', () async {
      final remote = _remote((_) async => _json({'message': 'Not Found'}, 404));
      final result = await remote.fetchLatest();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('lê sha pelos metadados e conteúdo pelo formato raw', () async {
      final remote = _remote((req) async {
        if (req.headers['Accept'] == 'application/vnd.github.raw+json') {
          return http.Response.bytes(utf8.encode('{"version":1,"boxes":[]}'), 200);
        }
        return _json({'type': 'file', 'sha': 'abc123'}, 200);
      });
      final file = (await remote.fetchLatest()).dataOrNull!;
      expect(file.sha, 'abc123');
      expect(file.content, '{"version":1,"boxes":[]}');
    });

    test('upload envia conteúdo em base64 com o sha esperado', () async {
      late Map<String, dynamic> body;
      final remote = _remote((req) async {
        expect(req.method, 'PUT');
        expect(req.url.path, '/repos/joao/backup/contents/gastolog-backup.json');
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({
          'commit': {
            'sha': 'c1',
            'message': 'Backup',
            'author': {'date': '2026-11-21T12:00:00Z'},
          },
        }, 200);
      });

      final result = await remote.upload('{"x":"ç"}', message: 'Backup', expectedSha: 'abc');

      expect(result.dataOrNull?.ref, 'c1');
      expect(utf8.decode(base64Decode(body['content'] as String)), '{"x":"ç"}');
      expect(body['sha'], 'abc');
      expect(body['message'], 'Backup');
    });

    test('conflito (remoto mudou) não sobrescreve e explica', () async {
      final remote = _remote((_) async => _json({'message': 'sha mismatch'}, 409));
      final failure = (await remote.upload('{}', message: 'm', expectedSha: 'old')).failureOrNull;
      expect(failure!.message, contains('mudou desde que você conferiu'));
    });
  });

  group('history', () {
    test('lista commits do arquivo com título e detalhes', () async {
      final remote = _remote((req) async {
        expect(req.url.queryParameters['path'], 'gastolog-backup.json');
        return _json([
          {
            'sha': 's1',
            'html_url': 'https://github.com/joao/backup/commit/s1',
            'commit': {
              'message': 'Backup GastoLog · 21/11/2026\n\nBoxes: 2\nTotal: 2 registros',
              'author': {'date': '2026-11-21T12:00:00Z'},
            },
          },
        ], 200);
      });
      final versions = (await remote.history()).dataOrNull!;
      expect(versions.single.ref, 's1');
      expect(versions.single.title, 'Backup GastoLog · 21/11/2026');
      expect(versions.single.details, 'Boxes: 2\nTotal: 2 registros');
    });

    test('repositório vazio = histórico vazio', () async {
      final remote = _remote((_) async => _json({'message': 'Git Repository is empty.'}, 409));
      expect((await remote.history()).dataOrNull, isEmpty);
    });
  });
}
