import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/boxes/domain/entities/box_entity.dart';
import 'package:buy_control/features/boxes/domain/repositories/box_repository.dart';

class GetBoxById {
  final BoxRepository repository;
  const GetBoxById(this.repository);

  Future<Result<BoxEntity>> call(String id) {
    return repository.getById(id);
  }
}
