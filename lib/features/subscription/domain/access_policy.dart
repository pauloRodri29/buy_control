/// Regra de acesso quando há mais itens do que o plano permite: ficam
/// liberados os [limit] **primeiros** (os mais antigos, ou os primeiros da
/// coluna no caso dos itens de um quadro) e o resto fica inacessível.
///
/// O usuário não escolhe quais — a regra é fixa e previsível, e criar ou
/// editar não muda quem está liberado. Nada disso é gravado nos registros:
/// o bloqueio é recalculado a partir do plano em vigor, então subir de
/// plano libera tudo na hora.
class AccessPolicy {
  AccessPolicy._();

  /// Ids inacessíveis entre [items]. [limit] `null` = ilimitado (nenhum
  /// bloqueado). Itens em que [isExempt] é verdadeiro (ex.: catálogos
  /// padrão do app) nunca são bloqueados nem contam no limite.
  static Set<String> lockedIds<T>(
    Iterable<T> items, {
    required int? limit,
    required String Function(T item) id,
    required Comparable<Object> Function(T item) orderBy,
    bool Function(T item)? isExempt,
  }) {
    if (limit == null) return const {};
    final counted = items.where((i) => !(isExempt?.call(i) ?? false)).toList();
    if (counted.length <= limit) return const {};

    counted.sort((a, b) {
      final byOrder = orderBy(a).compareTo(orderBy(b));
      return byOrder != 0 ? byOrder : id(a).compareTo(id(b));
    });
    return {for (final item in counted.skip(limit)) id(item)};
  }
}
