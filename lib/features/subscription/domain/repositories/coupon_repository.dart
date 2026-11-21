import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';

/// Cupons e quem já os usou. Hoje: lista de teste embarcada + resgates no
/// aparelho. Com backend, a validação passa a ser feita no servidor.
abstract class CouponRepository {
  /// `Success(null)` = código inexistente.
  Future<Result<Coupon?>> find(String code);

  Future<Result<bool>> wasRedeemed(String userId, String code);

  Future<Result<void>> markRedeemed(String userId, String code);

  /// Teste: esquece os cupons usados por [userId].
  Future<Result<void>> clearRedeemed(String userId);
}
