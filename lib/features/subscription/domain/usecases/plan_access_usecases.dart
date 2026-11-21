import 'package:buy_control/core/result/result.dart';
import 'package:buy_control/features/subscription/domain/access_policy.dart';
import 'package:buy_control/features/subscription/domain/entities/plan_keys.dart';
import 'package:buy_control/features/subscription/domain/resource_inventory.dart';
import 'package:buy_control/features/subscription/domain/usecases/quota_guard.dart';

/// Ids que ficaram inacessíveis em [resource] porque passam do limite do
/// plano em vigor (ver [AccessPolicy]).
class GetLockedIds {
  final EntitlementSource source;
  final ResourceInventory inventory;

  const GetLockedIds({required this.source, required this.inventory});

  Future<Set<String>> call(ResourceKey resource) async {
    final limit = source.entitlement.limitOf(resource);
    if (limit == null) return const {};

    final items = (await inventory.items(resource)).dataOrNull;
    if (items == null) return const {};

    if (resource != ResourceKey.planItemsPerBoard) return _locked(items, limit);

    final byGroup = <String?, List<ResourceItem>>{};
    for (final item in items) {
      byGroup.putIfAbsent(item.group, () => []).add(item);
    }
    return {for (final group in byGroup.values) ..._locked(group, limit)};
  }

  Set<String> _locked(List<ResourceItem> items, int limit) => AccessPolicy.lockedIds(
        items,
        limit: limit,
        id: (i) => i.id,
        orderBy: (i) => i.order,
        isExempt: (i) => i.exempt,
      );
}

/// Quanto o usuário usa de cada recurso, para a tela "Meu plano".
/// Itens por quadro = o quadro mais cheio.
class GetPlanUsage {
  final ResourceInventory inventory;

  const GetPlanUsage(this.inventory);

  Future<Result<Map<ResourceKey, int>>> call() async {
    final usage = <ResourceKey, int>{};
    for (final resource in ResourceKey.values) {
      final result = await inventory.items(resource);
      if (result case Failure(:final failure)) return Failure(failure);
      final counted = result.dataOrNull!.where((i) => !i.exempt);

      if (resource == ResourceKey.planItemsPerBoard) {
        final perGroup = <String?, int>{};
        for (final item in counted) {
          perGroup[item.group] = (perGroup[item.group] ?? 0) + 1;
        }
        usage[resource] = perGroup.values.fold(0, (max, v) => v > max ? v : max);
      } else {
        usage[resource] = counted.length;
      }
    }
    return Success(usage);
  }
}
