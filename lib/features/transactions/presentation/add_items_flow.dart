import 'package:buy_control/app/widgets/app_bottom_sheet.dart';
import 'package:buy_control/features/boxes/domain/usecases/get_box_by_id.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/presentation/pages/add_items_choice_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/item_details_step.dart';
import 'package:buy_control/features/transactions/presentation/pages/product_picker_sheet.dart';
import 'package:buy_control/features/transactions/presentation/pages/purchase_summary_step.dart';
import 'package:buy_control/features/transactions/presentation/pages/standalone_entry_sheet.dart';
import 'package:buy_control/features/transactions/presentation/purchase_draft.dart';
import 'package:buy_control/features/transactions/presentation/scan_items_flow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Ponto de entrada do fluxo "Adicionar itens" a partir do detalhe de uma
/// Box. Cada etapa é um bottom sheet; se o usuário fechar/voltar em
/// qualquer etapa, nada é persistido — só o "Confirmar" do resumo (ou do
/// lançamento avulso) grava.
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

  if (choice == AddItemsChoice.scan) {
    final draft = PurchaseDraft(boxId: boxId, occurredAt: DateTime.now());
    await scanIntoDraft(context, draft);
    if (draft.items.isEmpty || !context.mounted) return;
    await _runEditorLoop(context, draft);
    return;
  }

  final selectedProducts = await AppBottomSheet.show<List<ProductEntity>>(
    context,
    height: MediaQuery.of(context).size.height * 0.92,
    child: const ProductPickerSheet(),
  );
  if (selectedProducts == null || selectedProducts.isEmpty || !context.mounted) return;

  final draft = PurchaseDraft(boxId: boxId, occurredAt: DateTime.now())..addProducts(selectedProducts);
  await _runEditorLoop(context, draft);
}

/// Edita um lançamento ainda aberto (não pertencente a nenhum Fechamento).
/// Lançamento avulso abre o formulário avulso já preenchido; compra de
/// produtos abre o editor de itens com tudo como foi lançado.
Future<bool> openEditTransactionFlow(BuildContext context, TransactionEntity transaction) async {
  if (transaction.isClosed) return false;

  if (isStandaloneTransaction(transaction)) {
    final saved = await AppBottomSheet.show<bool>(
      context,
      child: StandaloneEntrySheet(boxId: transaction.boxId, initial: transaction),
    );
    return saved == true;
  }

  return _runEditorLoop(context, PurchaseDraft.fromTransaction(transaction));
}

/// Lançamento avulso = um único item sem vínculo com o catálogo.
bool isStandaloneTransaction(TransactionEntity transaction) {
  return transaction.items.length == 1 && transaction.items.first.productId == null;
}

/// Alterna entre editor de itens e resumo até o usuário confirmar (true)
/// ou desistir (false). "Editar itens" no resumo volta ao editor com o
/// rascunho intacto.
Future<bool> _runEditorLoop(BuildContext context, PurchaseDraft draft) async {
  final boxResult = await Get.find<GetBoxById>()(draft.boxId);
  final boxName = boxResult.dataOrNull?.name ?? '';

  while (true) {
    if (!context.mounted) return false;
    final continued = await AppBottomSheet.show<bool>(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ItemDetailsStep(draft: draft),
    );
    if (continued != true || !context.mounted) return false;

    final result = await AppBottomSheet.show<PurchaseSummaryResult>(
      context,
      child: PurchaseSummaryStep(draft: draft, boxName: boxName),
    );
    if (result == PurchaseSummaryResult.confirmed) return true;
    if (result != PurchaseSummaryResult.editItems) return false;
  }
}
