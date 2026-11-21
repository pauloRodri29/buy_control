import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/repositories/coupon_repository.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:get/get.dart';

/// Confere se o cupom existe e pode ser usado por este usuário. Não olha o
/// plano: isso é decidido na hora da compra ([Coupon.appliesTo]), para o
/// cupom poder ficar aplicado enquanto o usuário compara os planos.
class ValidateCoupon {
  final CouponRepository coupons;
  final SubscriptionRepository subscriptions;

  const ValidateCoupon({required this.coupons, required this.subscriptions});

  Future<Result<Coupon>> call(String code, {required String userId, DateTime? now}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return Failure(ValidationFailure('subscription.couponNotFound'.tr));

    final found = await coupons.find(normalized);
    if (found case Failure(:final failure)) return Failure(failure);
    final coupon = found.dataOrNull;
    if (coupon == null) return Failure(ValidationFailure('subscription.couponNotFound'.tr));

    if (coupon.isExpiredAt(now ?? DateTime.now())) {
      return Failure(ValidationFailure('subscription.couponExpired'.tr));
    }

    final redeemed = await coupons.wasRedeemed(userId, coupon.code);
    if (redeemed case Failure(:final failure)) return Failure(failure);
    if (redeemed.dataOrNull!) return Failure(ValidationFailure('subscription.couponAlreadyUsed'.tr));

    if (coupon.firstSubscriptionOnly) {
      final current = await subscriptions.get(userId);
      if (current case Failure(:final failure)) return Failure(failure);
      if (current.dataOrNull != null) return Failure(ValidationFailure('subscription.couponFirstOnly'.tr));
    }
    return Success(coupon);
  }
}
