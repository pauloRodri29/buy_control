import 'package:get/get.dart';
import 'package:buy_control/core/formatters/date_time_formatter.dart';

/// Uma coleção de dados que entra no backup (uma chave do JSON), com o
/// nome amigável usado no resumo e como descrever um registro dela em uma
/// linha ("Mercado do mês", "Compra · 21/11/2026").
class BackupCollection {
  final String key;
  final String _label;
  final String Function(Map<String, dynamic> record) describe;

  const BackupCollection({required this.key, required String label, required this.describe}) : _label = label;

  /// Nome amigável no idioma atual.
  String get label => _label.tr;
}

String _text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : '';

String _date(Object? value) {
  if (value is! String) return '';
  final parsed = DateTime.tryParse(value);
  return parsed == null ? '' : DateTimeFormatter.ddMMyyyy(parsed.toLocal());
}

String _join(List<String> parts) {
  final present = parts.where((p) => p.isNotEmpty).toList();
  return present.isEmpty ? 'backup.unnamed'.tr : present.join(' · ');
}

String _byName(Map<String, dynamic> r) => _join([_text(r['name'])]);

String _byTitle(Map<String, dynamic> r) => _join([_text(r['title'])]);

/// Ordem em que as coleções aparecem no resumo (e são gravadas no JSON).
/// `optional` = backups antigos podem não ter a chave; nesse caso o
/// import mantém os dados locais dessa coleção (ver `ImportBackup`).
final List<BackupCollection> backupCollections = [
  const BackupCollection(key: 'boxes', label: 'common.boxes', describe: _byName),
  BackupCollection(
    key: 'transactions',
    label: 'common.entries',
    describe: (r) => _join([_text(r['title']), _date(r['occurredAt'])]),
  ),
  BackupCollection(
    key: 'boxClosures',
    label: 'common.closings',
    describe: (r) => _join([_text(r['boxNameSnapshot']), _date(r['referenceDate'])]),
  ),
  BackupCollection(
    key: 'products',
    label: 'common.products',
    describe: (r) => _join([_text(r['name']), _text(r['brand'])]),
  ),
  const BackupCollection(key: 'categories', label: 'common.categories', describe: _byName),
  const BackupCollection(key: 'productTypes', label: 'common.productTypes2', describe: _byName),
  BackupCollection(
    key: 'units',
    label: 'common.units',
    describe: (r) => _join([_text(r['name']), _text(r['abbreviation'])]),
  ),
  const BackupCollection(key: 'planBoards', label: 'backup.planningBoards', describe: _byTitle),
  const BackupCollection(key: 'planItems', label: 'backup.planningItems', describe: _byTitle),
];

/// Chaves que backups antigos podem não ter (criadas depois do formato v1).
const optionalBackupKeys = {'planBoards', 'planItems'};
