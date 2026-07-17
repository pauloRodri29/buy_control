import 'package:buy_control/features/boxes/data/mappers/box_mapper.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BoxMapper round-trip Entity -> Model -> Entity preserva os dados', () {
    final now = DateTime.now();
    final entity = BoxEntity(
      id: 'b1',
      name: 'Mercado',
      description: 'Compras do mês',
      isArchived: true,
      createdAt: now,
      updatedAt: now,
      version: 3,
    );

    final model = BoxMapper.toModel(entity);
    final roundTripped = BoxMapper.toEntity(model);

    expect(roundTripped.id, entity.id);
    expect(roundTripped.name, entity.name);
    expect(roundTripped.description, entity.description);
    expect(roundTripped.isArchived, entity.isArchived);
    expect(roundTripped.version, entity.version);
  });
}
