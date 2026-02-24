class UnitType {
  final String code; // UN
  final String label; // Unidade

  const UnitType(this.code, this.label);

  // cria um Map
  Map<String, dynamic> toMap() {
    return {'code': code, 'label': label};
  }

  UnitType? find(String code) {
    return this.code == code ? this : null;
  }
}
