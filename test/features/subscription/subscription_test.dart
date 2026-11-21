import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/access_policy.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/entities/subscription_entity.dart';
import 'package:buy_control/features/subscription/domain/plan_catalog.dart';
import 'package:buy_control/features/subscription/domain/repositories/billing_gateway.dart';
import 'package:buy_control/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:buy_control/features/subscription/domain/resource_inventory.dart';
import 'package:buy_control/features/subscription/domain/usecases/plan_access_usecases.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';
import 'package:buy_control/features/subscription/domain/usecases/subscription_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements EntitlementSource {
  @override
  Entitlement entitlement;
  _Source(this.entitlement);
}

/// Inventário em memória: só [items] importa para as regras.
class _Inventory implements ResourceInventory {
  final Map<ResourceKey, List<ResourceItem>> data;
  _Inventory(this.data);

  @override
  Future<Result<List<ResourceItem>>> items(ResourceKey resource) async => Success(data[resource] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements SubscriptionRepository {
  final store = <String, SubscriptionEntity>{};

  @override
  Future<Result<SubscriptionEntity?>> get(String userId) async => Success(store[userId]);

  @override
  Future<Result<void>> save(SubscriptionEntity s) async {
    store[s.userId] = s;
    return const Success(null);
  }

  @override
  Future<Result<void>> clear(String userId) async {
    store.remove(userId);
    return const Success(null);
  }
}

class _Billing implements BillingGateway {
  Result<PurchaseReceipt> next;
  _Billing(this.next);

  @override
  bool get isSimulated => true;

  @override
  Future<Result<PurchaseReceipt>> purchase(PurchaseRequest request) async => next;
}

ResourceItem _item(String id, int day, {bool exempt = false, String? group}) =>
    ResourceItem(id: id, order: DateTime(2026, 1, day), exempt: exempt, group: group);

Entitlement _on(String planId) => Entitlement(
      plan: PlanCatalog.byId(planId),
      subscription: SubscriptionEntity(
        userId: 'u',
        planId: planId,
        period: BillingPeriod.monthly,
        pricePaid: PlanCatalog.byId(planId).monthlyPrice,
        startedAt: DateTime(2026),
        expiresAt: DateTime(2100),
      ),
    );

void main() {
  group('PlanCatalog', () {
    test('plano maior inclui todos os módulos e limites iguais ou maiores que o anterior', () {
      for (var i = 1; i < PlanCatalog.all.length; i++) {
        final lower = PlanCatalog.all[i - 1];
        final higher = PlanCatalog.all[i];
        expect(higher.rank, greaterThan(lower.rank));
        expect(higher.features.containsAll(lower.features), isTrue, reason: '${higher.name} ⊇ ${lower.name}');
        for (final resource in ResourceKey.values) {
          final a = lower.limitOf(resource);
          final b = higher.limitOf(resource);
          expect(b == null || (a != null && b >= a), isTrue, reason: '${resource.name}: ${higher.name} ≥ ${lower.name}');
        }
      }
    });

    test('Grátis mantém o uso central: planejamento, leitor, backup manual e repetir ciclo', () {
      expect(
        PlanCatalog.free.features,
        containsAll([FeatureKey.planning, FeatureKey.barcodeScanner, FeatureKey.backupManual, FeatureKey.carryOver]),
      );
    });
  });

  group('AccessPolicy', () {
    test('libera os N mais antigos e bloqueia o resto, independente da ordem da lista', () {
      final items = [_item('c', 3), _item('a', 1), _item('e', 5), _item('b', 2), _item('d', 4)];
      final locked = AccessPolicy.lockedIds(items, limit: 3, id: (i) => i.id, orderBy: (i) => i.order);
      expect(locked, {'d', 'e'});
    });

    test('itens padrão não contam nem são bloqueados', () {
      final items = [_item('padrao1', 1, exempt: true), _item('padrao2', 1, exempt: true), _item('a', 2), _item('b', 3)];
      final locked = AccessPolicy.lockedIds(
        items,
        limit: 1,
        id: (i) => i.id,
        orderBy: (i) => i.order,
        isExempt: (i) => i.exempt,
      );
      expect(locked, {'b'});
    });

    test('ilimitado ou dentro do limite: nada bloqueado', () {
      final items = [_item('a', 1), _item('b', 2)];
      expect(AccessPolicy.lockedIds(items, limit: null, id: (i) => i.id, orderBy: (i) => i.order), isEmpty);
      expect(AccessPolicy.lockedIds(items, limit: 2, id: (i) => i.id, orderBy: (i) => i.order), isEmpty);
    });
  });

  group('Entitlement', () {
    test('sem assinatura = Grátis', () {
      expect(Entitlement.resolve(null).plan.id, PlanCatalog.freeId);
    });

    test('assinatura vencida volta ao Grátis e marca expired', () {
      final sub = SubscriptionEntity(
        userId: 'u',
        planId: PlanCatalog.proId,
        period: BillingPeriod.monthly,
        pricePaid: PlanCatalog.pro.monthlyPrice,
        startedAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 2, 1),
      );
      final active = Entitlement.resolve(sub, now: DateTime(2026, 1, 15));
      final expired = Entitlement.resolve(sub, now: DateTime(2026, 2, 1));
      expect(active.plan.id, PlanCatalog.proId);
      expect(expired.plan.id, PlanCatalog.freeId);
      expect(expired.expired, isTrue);
    });
  });

  group('QuotaGuard', () {
    test('bloqueia ao atingir o limite do plano e libera depois do upgrade', () async {
      final boxes = [for (var i = 1; i <= 3; i++) _item('b$i', i)];
      final source = _Source(Entitlement.free);
      final guard = QuotaGuard(source: source, inventory: _Inventory({ResourceKey.boxes: boxes}));

      final blocked = await guard.ensureCanAdd(ResourceKey.boxes);
      expect(blocked, isA<PlanLimitFailure>());
      expect(blocked!.message, contains('3 Boxes'));

      source.entitlement = _on(PlanCatalog.essentialId);
      expect(await guard.ensureCanAdd(ResourceKey.boxes), isNull);
    });

    test('itens padrão não ocupam a cota de categorias', () async {
      final categories = [
        for (var i = 1; i <= 10; i++) _item('padrao$i', 1, exempt: true),
        for (var i = 1; i <= 4; i++) _item('minha$i', i + 1),
      ];
      final guard = QuotaGuard(
        source: _Source(Entitlement.free),
        inventory: _Inventory({ResourceKey.categories: categories}),
      );
      expect(await guard.ensureCanAdd(ResourceKey.categories), isNull);
    });

    test('limite de itens é por quadro', () async {
      final items = [for (var i = 0; i < 15; i++) _item('x$i', 1, group: 'cheio'), _item('y', 1, group: 'vazio')];
      final guard = QuotaGuard(
        source: _Source(Entitlement.free),
        inventory: _Inventory({ResourceKey.planItemsPerBoard: items}),
      );
      expect(await guard.ensureCanAdd(ResourceKey.planItemsPerBoard, group: 'cheio'), isA<PlanLimitFailure>());
      expect(await guard.ensureCanAdd(ResourceKey.planItemsPerBoard, group: 'vazio'), isNull);
    });
  });

  group('GetLockedIds', () {
    test('rebaixar para o Grátis bloqueia os mais novos; voltar ao Pro libera tudo', () async {
      final products = [for (var i = 1; i <= 62; i++) _item('p$i', 1 + i % 28).copyWithOrder(i)];
      final source = _Source(_on(PlanCatalog.proId));
      final getLocked = GetLockedIds(source: source, inventory: _Inventory({ResourceKey.products: products}));

      expect(await getLocked(ResourceKey.products), isEmpty);

      source.entitlement = Entitlement.free;
      expect(await getLocked(ResourceKey.products), {'p61', 'p62'});

      source.entitlement = _on(PlanCatalog.proId);
      expect(await getLocked(ResourceKey.products), isEmpty);
    });

    test('itens por quadro: bloqueia o excedente de cada quadro pela posição', () async {
      final items = [
        for (var i = 0; i < 17; i++) ResourceItem(id: 'a$i', order: i.toDouble(), group: 'A'),
        for (var i = 0; i < 3; i++) ResourceItem(id: 'b$i', order: i.toDouble(), group: 'B'),
      ];
      final getLocked = GetLockedIds(
        source: _Source(Entitlement.free),
        inventory: _Inventory({ResourceKey.planItemsPerBoard: items}),
      );
      expect(await getLocked(ResourceKey.planItemsPerBoard), {'a15', 'a16'});
    });
  });

  group('Assinatura simulada', () {
    final receipt = Success(PurchaseReceipt(
      transactionId: 't',
      purchasedAt: DateTime(2026, 3, 10),
      source: SubscriptionSource.simulated,
    ));

    test('compra aprovada grava a assinatura com vencimento em 1 mês', () async {
      final repo = _Repo();
      final result = await PurchasePlan(repository: repo, billing: _Billing(receipt))(
        userId: 'u',
        plan: PlanCatalog.pro,
        period: BillingPeriod.monthly,
      );
      expect(result.isSuccess, isTrue);
      expect(repo.store['u']!.planId, PlanCatalog.proId);
      expect(repo.store['u']!.expiresAt, DateTime(2026, 4, 10));
    });

    test('pagamento recusado não grava nada', () async {
      final repo = _Repo();
      final result = await PurchasePlan(repository: repo, billing: _Billing(const Failure(PurchaseDeclinedFailure())))(
        userId: 'u',
        plan: PlanCatalog.pro,
        period: BillingPeriod.yearly,
      );
      expect(result.failureOrNull, isA<PurchaseDeclinedFailure>());
      expect(repo.store, isEmpty);
    });

    test('com renovação ligada, a assinatura vencida renova; desligada, volta ao Grátis', () async {
      final repo = _Repo();
      final getEntitlement = GetEntitlement(repository: repo, billing: _Billing(receipt));
      final sub = SubscriptionEntity(
        userId: 'u',
        planId: PlanCatalog.essentialId,
        period: BillingPeriod.monthly,
        pricePaid: PlanCatalog.essential.monthlyPrice,
        startedAt: DateTime(2026, 1, 5),
        expiresAt: DateTime(2026, 2, 5),
      );

      await repo.save(sub);
      final renewed = (await getEntitlement('u', now: DateTime(2026, 4, 20))).dataOrNull!;
      expect(renewed.plan.id, PlanCatalog.essentialId);
      expect(repo.store['u']!.expiresAt, DateTime(2026, 5, 5));

      await repo.save(sub.copyWith(autoRenew: false));
      final lapsed = (await getEntitlement('u', now: DateTime(2026, 4, 20))).dataOrNull!;
      expect(lapsed.plan.id, PlanCatalog.freeId);
      expect(lapsed.expired, isTrue);
    });
  });
}

extension on ResourceItem {
  /// Ordem explícita (criação em sequência), para o teste não depender de datas.
  ResourceItem copyWithOrder(int n) => ResourceItem(id: id, order: n, exempt: exempt, group: this.group);
}
