import 'dart:convert';

import 'package:buy_control/features/backup/domain/entities/backup_collections.dart';
import 'package:buy_control/features/backup/domain/entities/backup_snapshot.dart';

/// Um registro citado no resumo: id, descrição de uma linha e a data da
/// última alteração (quando houver).
class BackupRecordRef {
  final String id;
  final String label;
  final DateTime? updatedAt;

  const BackupRecordRef({required this.id, required this.label, this.updatedAt});
}

/// Diferença de uma coleção entre o que existe hoje ([currentCount]) e o
/// que vai ficar depois da operação ([incomingCount]).
class CollectionDiff {
  final BackupCollection collection;

  /// `false` quando o backup que chega não traz esta coleção (backup
  /// antigo): nada muda nela, os dados atuais são mantidos.
  final bool includedInIncoming;
  final int currentCount;
  final int incomingCount;

  /// Existem só no que chega — vão passar a existir.
  final List<BackupRecordRef> added;

  /// Existem só no atual — vão deixar de existir.
  final List<BackupRecordRef> removed;

  /// Existem nos dois, mas com conteúdo diferente — a versão que chega
  /// substitui a atual.
  final List<BackupRecordRef> changed;

  /// Dos [changed], quantos têm a versão atual MAIS NOVA que a que chega,
  /// ou seja, alterações recentes que seriam trocadas por versões antigas.
  final int changedButCurrentIsNewer;
  final int unchanged;

  const CollectionDiff({
    required this.collection,
    required this.includedInIncoming,
    required this.currentCount,
    required this.incomingCount,
    required this.added,
    required this.removed,
    required this.changed,
    required this.changedButCurrentIsNewer,
    required this.unchanged,
  });

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty || changed.isNotEmpty;
}

/// Comparação completa entre dois backups: o que existe hoje (`current`)
/// e o que vai substituí-lo (`incoming`). Serve para os dois sentidos:
/// - restaurar: current = dados do aparelho, incoming = arquivo/nuvem;
/// - enviar: current = backup que está na nuvem, incoming = aparelho.
///
/// Só registros ativos entram na conta (registros com exclusão lógica não
/// aparecem para o usuário, então não fazem sentido no resumo).
class BackupDiff {
  final BackupSnapshot current;
  final BackupSnapshot incoming;
  final List<CollectionDiff> collections;

  const BackupDiff._(this.current, this.incoming, this.collections);

  factory BackupDiff.compare(BackupSnapshot current, BackupSnapshot incoming) {
    return BackupDiff._(current, incoming, [
      for (final c in backupCollections) _compareCollection(c, current, incoming),
    ]);
  }

  int get totalAdded => collections.fold(0, (s, c) => s + c.added.length);
  int get totalRemoved => collections.fold(0, (s, c) => s + c.removed.length);
  int get totalChanged => collections.fold(0, (s, c) => s + c.changed.length);
  int get totalUnchanged => collections.fold(0, (s, c) => s + c.unchanged);
  int get totalCurrentIsNewer => collections.fold(0, (s, c) => s + c.changedButCurrentIsNewer);
  bool get hasChanges => collections.any((c) => c.hasChanges);

  /// Coleções que o backup que chega não traz (mantidas como estão).
  List<CollectionDiff> get keptCollections => collections.where((c) => !c.includedInIncoming).toList();

  /// Data da alteração mais recente entre os registros atuais.
  DateTime? get currentLastChange => _lastChange(current);

  /// `true` quando o backup que chega foi gerado antes da última alteração
  /// feita nos dados atuais — sinal forte de que é um backup velho.
  bool get incomingIsOlderThanCurrentData {
    final exportedAt = incoming.exportedAt;
    final lastChange = currentLastChange;
    if (exportedAt == null || lastChange == null) return false;
    return exportedAt.isBefore(lastChange);
  }

  static DateTime? _lastChange(BackupSnapshot snapshot) {
    DateTime? latest;
    for (final c in backupCollections) {
      for (final r in snapshot.active(c.key)) {
        final updatedAt = _updatedAt(r);
        if (updatedAt != null && (latest == null || updatedAt.isAfter(latest))) latest = updatedAt;
      }
    }
    return latest;
  }

  static CollectionDiff _compareCollection(
    BackupCollection collection,
    BackupSnapshot current,
    BackupSnapshot incoming,
  ) {
    final currentById = {for (final r in current.active(collection.key)) '${r['id']}': r};

    final kept = !incoming.includes(collection.key) && optionalBackupKeys.contains(collection.key);
    if (kept) {
      return CollectionDiff(
        collection: collection,
        includedInIncoming: false,
        currentCount: currentById.length,
        incomingCount: currentById.length,
        added: const [],
        removed: const [],
        changed: const [],
        changedButCurrentIsNewer: 0,
        unchanged: currentById.length,
      );
    }

    final incomingById = {for (final r in incoming.active(collection.key)) '${r['id']}': r};
    final added = <BackupRecordRef>[];
    final removed = <BackupRecordRef>[];
    final changed = <BackupRecordRef>[];
    var currentIsNewer = 0;
    var unchanged = 0;

    for (final entry in incomingById.entries) {
      final before = currentById[entry.key];
      if (before == null) {
        added.add(_ref(collection, entry.value));
      } else if (_sameContent(before, entry.value)) {
        unchanged++;
      } else {
        changed.add(_ref(collection, entry.value));
        final beforeAt = _updatedAt(before);
        final afterAt = _updatedAt(entry.value);
        if (beforeAt != null && afterAt != null && beforeAt.isAfter(afterAt)) currentIsNewer++;
      }
    }
    for (final entry in currentById.entries) {
      if (!incomingById.containsKey(entry.key)) removed.add(_ref(collection, entry.value));
    }

    int byDateDesc(BackupRecordRef a, BackupRecordRef b) =>
        (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
    added.sort(byDateDesc);
    removed.sort(byDateDesc);
    changed.sort(byDateDesc);

    return CollectionDiff(
      collection: collection,
      includedInIncoming: true,
      currentCount: currentById.length,
      incomingCount: incomingById.length,
      added: added,
      removed: removed,
      changed: changed,
      changedButCurrentIsNewer: currentIsNewer,
      unchanged: unchanged,
    );
  }

  /// Compara o conteúdo ignorando o estado de sincronização, que não é
  /// dado do usuário.
  static bool _sameContent(Map<String, dynamic> a, Map<String, dynamic> b) {
    String normalized(Map<String, dynamic> m) {
      final copy = Map<String, dynamic>.from(m)..remove('syncStatus');
      final keys = copy.keys.toList()..sort();
      return jsonEncode({for (final k in keys) k: copy[k]});
    }

    return normalized(a) == normalized(b);
  }

  static DateTime? _updatedAt(Map<String, dynamic> r) => DateTime.tryParse('${r['updatedAt']}')?.toLocal();

  static BackupRecordRef _ref(BackupCollection collection, Map<String, dynamic> r) {
    return BackupRecordRef(id: '${r['id']}', label: collection.describe(r), updatedAt: _updatedAt(r));
  }
}
