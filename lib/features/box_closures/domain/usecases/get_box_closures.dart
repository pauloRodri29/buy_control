import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/box_closures/domain/entities/box_closure_entity.dart';
import 'package:buy_control/features/box_closures/domain/repositories/box_closure_repository.dart';

class GetBoxClosures {
  final BoxClosureRepository repository;
  const GetBoxClosures(this.repository);

  Future<Result<List<BoxClosureEntity>>> call(String boxId) {
    return repository.getAll(boxId: boxId);
  }
}
