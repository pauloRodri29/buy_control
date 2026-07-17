import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_by_id.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/presentation/pages/add_items_choice_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/item_details_step.dart';
import 'package:buy_control/features/transactions/presentation/pages/product_picker_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/purchase_summary_step.dart';
import 'package:buy_control/features/transactions/presentation/pages/standalone_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Ponto de entrada do fluxo "Adicionar itens" a partir do detalhe de uma
/// caixa. Cada etapa é um bottom sheet independente que só devolve dado
/// via `Navigator.pop`; se o usuário fechar/voltar em qualquer etapa, esta
/// função simplesmente retorna sem chamar nenhum caso de uso de escrita —
/// nada é persistido até `PurchaseSummaryStep` ou `StandaloneEntrySheet`
/// chamarem `CreateTransaction` no toque em "Confirmar".
Future<void> openAddItemsFlow(BuildContext context, String boxId) async {
  final choice = await AppBottomSheet.show<AddItemsChoice>(
    context,
    child: const AddItemsChoiceSheet(),
  );
  if (choice == null || !context.mounted) return;

  if (choice == AddItemsChoice.standalone) {
    await AppBottomSheet.show<bool>(context, child: StandaloneEntrySheet(boxId: boxId));
    return;
  }

  final selectedProducts = await AppBottomSheet.show<List<ProductEntity>>(
    context,
    height: MediaQuery.of(context).size.height * 0.92,
    child: const ProductPickerSheet(),
  );
  if (selectedProducts == null || selectedProducts.isEmpty || !context.mounted) return;

  final itemsDraft = await AppBottomSheet.show<ItemsDraftResult>(
    context,
    height: MediaQuery.of(context).size.height * 0.92,
    child: ItemDetailsStep(products: selectedProducts),
  );
  if (itemsDraft == null || !context.mounted) return;

  final boxResult = await Get.find<GetBoxById>()(boxId);
  final boxName = boxResult.dataOrNull?.name ?? '';
  if (!context.mounted) return;

  await AppBottomSheet.show<bool>(
    context,
    child: PurchaseSummaryStep(
      boxId: boxId,
      boxName: boxName,
      items: itemsDraft.items,
      occurredAt: itemsDraft.occurredAt,
      notes: itemsDraft.notes,
    ),
  );
}
