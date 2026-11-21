import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';

/// Assinatura do usuário. Hoje é salva no aparelho (Hive); com backend,
/// passa a vir do servidor com cópia local para uso offline.
abstract class SubscriptionRepository {
  /// `Success(null)` = o usuário não tem assinatura (plano Grátis).
  Future<Result<SubscriptionEntity?>> get(String userId);

  Future<Result<void>> save(SubscriptionEntity subscription);

  Future<Result<void>> clear(String userId);
}
