import 'package:buy_control/core/database/hive_box_registry.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/custom_plan_pricing.dart';
import 'package:buy_control/features/subscription/domain/entities/coupon.dart';
import 'package:buy_control/features/subscription/domain/repositories/coupon_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cupons de teste embarcados e resgates guardados no aparelho (na box da
/// assinatura, sob `coupons:<userId>`). Com backend, a lista e o controle
/// de uso passam para o servidor.
class LocalCouponRepository implements CouponRepository {
  /// Cupons disponíveis no modo de teste.
  static final testCoupons = <Coupon>[
    const Coupon(code: 'BEMVINDO10', kind: CouponKind.percent, percent: 10),
    const Coupon(code: 'GASTOLOG20', kind: CouponKind.percent, percent: 20),
    const Coupon(
      code: 'PRIMEIRA50',
      kind: CouponKind.percent,
      percent: 50,
      firstSubscriptionOnly: true,
    ),
    const Coupon(
      code: 'MONTE30',
      kind: CouponKind.percent,
      percent: 30,
      planIds: {CustomPlanPricing.planId},
    ),
    const Coupon(code: 'MENOS5', kind: CouponKind.fixed, amount: Money(500)),
    Coupon(code: 'VENCIDO', kind: CouponKind.percent, percent: 90, validUntil: DateTime(2020)),
  ];

  Box get _box => Hive.box(HiveBoxRegistry.subscription);

  String _key(String userId) => 'coupons:$userId';

  @override
  Future<Result<Coupon?>> find(String code) async {
    final normalized = code.trim().toUpperCase();
    return Success(testCoupons.where((c) => c.code == normalized).firstOrNull);
  }

  @override
  Future<Result<bool>> wasRedeemed(String userId, String code) async {
    try {
      final used = (_box.get(_key(userId)) as List?)?.cast<String>() ?? const [];
      return Success(used.contains(code));
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> markRedeemed(String userId, String code) async {
    try {
      final used = (_box.get(_key(userId)) as List?)?.cast<String>() ?? const [];
      await _box.put(_key(userId), [...used, code]);
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }

  @override
  Future<Result<void>> clearRedeemed(String userId) async {
    try {
      await _box.delete(_key(userId));
      return const Success(null);
    } catch (_) {
      return const Failure(CacheFailure());
    }
  }
}
