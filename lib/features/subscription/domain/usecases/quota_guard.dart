import 'package:get/get.dart';
import 'package:buy_control/core/errors/app_failure.dart';
import 'package:buy_control/features/subscription/domain/entities/entitlement.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/resource_inventory.dart';

/// Fonte do plano em vigor (implementada pelo controller da assinatura,
/// que mantém o entitlement carregado em memória).
abstract interface class EntitlementSource {
  Entitlement get entitlement;
}

/// Trava de criação: antes de gravar um registro novo, os casos de uso
/// `Create*` perguntam se o plano ainda comporta mais um.
class QuotaGuard {
  final EntitlementSource source;
  final ResourceInventory inventory;

  const QuotaGuard({required this.source, required this.inventory});

  /// `null` quando pode criar; senão a falha a devolver ao chamador.
  /// [group] = o quadro de destino, para o limite de itens por quadro.
  Future<AppFailure?> ensureCanAdd(ResourceKey resource, {String? group}) async {
    final entitlement = source.entitlement;
    final limit = entitlement.limitOf(resource);
    if (limit == null) return null;

    final result = await inventory.items(resource);
    final failure = result.failureOrNull;
    if (failure != null) return failure;

    final count = result.dataOrNull!
        .where((i) => !i.exempt && (resource != ResourceKey.planItemsPerBoard || i.group == group))
        .length;
    if (count < limit) return null;
    return PlanLimitFailure(limitMessage(entitlement, resource, limit));
  }

  static String limitMessage(Entitlement entitlement, ResourceKey resource, int limit) {
    final noun = limit == 1 ? resource.singular : resource.plural;
    final scope = resource == ResourceKey.planItemsPerBoard ? 'subscription.perBoard'.tr : '';
    return 'subscription.planAllowsUpNameLimitNounScope'.trParams({'name': entitlement.plan.name, 'limit': '$limit', 'noun': noun, 'scope': scope});
  }
}
