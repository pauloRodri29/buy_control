extension StringSearchExtensions on String {
  /// Normaliza para comparação de busca: minúsculas, sem espaços nas pontas
  /// e espaços internos colapsados.
  String normalizedForSearch() {
    return trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool containsSearchTerm(String term) {
    if (term.trim().isEmpty) return true;
    return normalizedForSearch().contains(term.normalizedForSearch());
  }
}
