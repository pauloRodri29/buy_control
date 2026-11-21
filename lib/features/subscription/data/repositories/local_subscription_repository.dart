import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/data/models/subscription_model.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Assinatura guardada no aparelho, na box `subscription`, sob o id do
/// usuário. Fica fora do backup de dados: o plano é da conta, não dos dados.
class LocalSubscriptionRepository implements SubscriptionRepository {
  Box get _box => Hive.box(HiveBoxRegistry.subscription);

  @override
  Future<Result<SubscriptionEntity?>> get(String userId) async {
    try {
      final raw = _box.get(userId);
      if (raw == null) return const Success(null);
      return Success(SubscriptionModel.fromMap(Map<String, dynamic>.from(raw as Map)));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> save(SubscriptionEntity subscription) async {
    try {
      await _box.put(subscription.userId, SubscriptionModel.toMap(subscription));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> clear(String userId) async {
    try {
      await _box.delete(userId);
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }
}
