import 'dart:convert';

import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/features/backup/data/backup_settings_store.dart';
import 'package:buy_control/features/backup/domain/entities/backup_diff.dart';
import 'package:buy_control/features/backup/domain/entities/backup_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> box(String id, String name, {String updatedAt = '2026-01-01T00:00:00.000Z', String? deletedAt}) => {
      'id': id,
      'name': name,
      'isArchived': false,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'syncStatus': 'synced',
      'version': 1,
    };

BackupSnapshot snap(Map<String, dynamic> payload) =>
    BackupSnapshot.parse(jsonEncode({'version': 1, ...payload})).dataOrNull!;

void main() {
  group('BackupSnapshot.parse', () {
    test('rejeita conteúdo que não é JSON', () {
      final r = BackupSnapshot.parse('isso não é json');
      expect(r.failureOrNull, isA<ValidationFailure>());
      expect(r.failureOrNull!.message, contains('JSON'));
    });

    test('rejeita JSON que não é backup do app', () {
      expect(BackupSnapshot.parse('{"foo": 1}').failureOrNull, isA<ValidationFailure>());
    });

    test('conta só registros ativos e lê a data de exportação', () {
      final s = snap({
        'exportedAt': '2026-11-20T10:00:00.000Z',
        'boxes': [box('a', 'Mercado'), box('b', 'Velha', deletedAt: '2026-02-01T00:00:00.000Z')],
      });
      expect(s.activeCount('boxes'), 1);
      expect(s.exportedAt, DateTime.parse('2026-11-20T10:00:00.000Z').toLocal());
      expect(s.shortSummary(), '1 boxes');
    });
  });

  group('BackupDiff.compare', () {
    test('separa o que entra, sai, muda e fica igual', () {
      final current = snap({
        'boxes': [box('a', 'Mercado'), box('b', 'Farmácia'), box('c', 'Casa')],
      });
      final incoming = snap({
        'boxes': [box('a', 'Mercado'), box('b', 'Farmácia 2', updatedAt: '2026-03-01T00:00:00.000Z'), box('d', 'Pet')],
      });

      final diff = BackupDiff.compare(current, incoming);
      final boxes = diff.collections.firstWhere((c) => c.collection.key == 'boxes');

      expect(boxes.added.map((r) => r.label), ['Pet']);
      expect(boxes.removed.map((r) => r.label), ['Casa']);
      expect(boxes.changed.map((r) => r.label), ['Farmácia 2']);
      expect(boxes.unchanged, 1);
      expect(boxes.currentCount, 3);
      expect(boxes.incomingCount, 3);
      expect(diff.hasChanges, isTrue);
    });

    test('conta registros atuais mais novos que os do backup (perda de alteração)', () {
      final current = snap({'boxes': [box('a', 'Novo nome', updatedAt: '2026-06-01T00:00:00.000Z')]});
      final incoming = snap({
        'exportedAt': '2026-02-01T00:00:00.000Z',
        'boxes': [box('a', 'Nome antigo', updatedAt: '2026-01-01T00:00:00.000Z')],
      });

      final diff = BackupDiff.compare(current, incoming);
      expect(diff.totalCurrentIsNewer, 1);
      expect(diff.incomingIsOlderThanCurrentData, isTrue);
    });

    test('ignora diferença só no syncStatus', () {
      final a = box('a', 'Mercado');
      final b = {...a, 'syncStatus': 'pendingUpdate'};
      final diff = BackupDiff.compare(snap({'boxes': [a]}), snap({'boxes': [b]}));
      expect(diff.hasChanges, isFalse);
      expect(diff.totalUnchanged, 1);
    });

    test('backup antigo sem planejamento mantém o planejamento atual', () {
      final current = snap({
        'planBoards': [
          {'id': 'p1', 'title': 'Viagem', 'updatedAt': '2026-01-01T00:00:00.000Z'},
        ],
      });
      final incoming = snap({'boxes': <Object>[]});

      final diff = BackupDiff.compare(current, incoming);
      final boards = diff.collections.firstWhere((c) => c.collection.key == 'planBoards');
      expect(boards.includedInIncoming, isFalse);
      expect(boards.removed, isEmpty);
      expect(diff.keptCollections.map((c) => c.collection.key), containsAll(['planBoards', 'planItems']));
    });
  });

  group('GithubBackupConfig.parseRepository', () {
    test('aceita link completo, com .git, barra final e forma curta', () {
      for (final input in [
        'https://github.com/joao/gastolog-backup',
        'https://github.com/joao/gastolog-backup.git',
        'github.com/joao/gastolog-backup/',
        '  joao/gastolog-backup ',
      ]) {
        final config = GithubBackupConfig.parseRepository(input);
        expect(config?.fullName, 'joao/gastolog-backup', reason: input);
      }
    });

    test('recusa entradas que não são repositório', () {
      expect(GithubBackupConfig.parseRepository('https://github.com/joao'), isNull);
      expect(GithubBackupConfig.parseRepository('https://gitlab.com/joao/repo'), isNull);
      expect(GithubBackupConfig.parseRepository(''), isNull);
    });
  });
}
