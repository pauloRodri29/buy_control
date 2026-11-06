import 'package:buy_control/core/money/money.dart';
import 'package:buy_control/core/utils/id_generator.dart';
import 'package:buy_control/features/products/domain/entities/product_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_entity.dart';
import 'package:buy_control/features/transactions/domain/entities/transaction_item_entity.dart';

/// Estado em memória de uma compra enquanto ela é montada ou editada.
/// É compartilhado (e mutado) entre as etapas do fluxo — editor de itens
/// e resumo — para que o usuário possa ir e voltar entre elas sem perder
/// nada. Só vira dado persistido quando o resumo é confirmado.
class PurchaseDraft {
  final String boxId;

  /// Lançamento que está sendo editado; `null` quando é uma compra nova.
  final TransactionEntity? original;

  String? title;
  DateTime occurredAt;
  String? notes;
  Money discount;
  Money additionalCost;
  List<TransactionItemEntity> items;

  /// "Repetir no próximo ciclo" — ver [TransactionEntity.carryOver].
  bool carryOver;

  PurchaseDraft({
    required this.boxId,
    this.original,
    this.title,
    required this.occurredAt,
    this.notes,
    this.discount = Money.zero,
    this.additionalCost = Money.zero,
    List<TransactionItemEntity>? items,
    this.carryOver = true,
  }) : items = items ?? [];

  factory PurchaseDraft.fromTransaction(TransactionEntity transaction) {
    return PurchaseDraft(
      boxId: transaction.boxId,
      original: transaction,
      title: transaction.title,
      occurredAt: transaction.occurredAt,
      notes: transaction.notes,
      discount: transaction.discount,
      additionalCost: transaction.additionalCost,
      items: [...transaction.items],
      carryOver: transaction.carryOver,
    );
  }

  bool get isEditing => original != null;

  Money get itemsTotal => items.fold(Money.zero, (sum, item) => sum + item.total);
  Money get total => itemsTotal - discount + additionalCost;

  /// Item novo (ainda sem lançamento) a partir de um produto do catálogo,
  /// já com o preço de referência e a unidade padrão do produto.
  static TransactionItemEntity itemFromProduct(ProductEntity product) {
    return TransactionItemEntity(
      id: IdGenerator.generate(),
      transactionId: '',
      productId: product.id,
      nameSnapshot: product.name,
      categoryId: product.categoryId,
      productTypeId: product.productTypeId,
      unitId: product.defaultUnitId,
      quantity: 1,
      unitPrice: product.referencePrice ?? Money.zero,
    );
  }

  /// Acrescenta um item já montado (etiqueta de balança, produto sem
  /// cadastro). Não junta com itens iguais: cada etiqueta de balança é uma
  /// embalagem diferente, com peso/preço próprio.
  void addItem(TransactionItemEntity item) => items.add(item);

  /// Quantidade atual do produto na compra (0 se não estiver).
  double quantityOf(String productId) =>
      items.where((i) => i.productId == productId).fold(0, (sum, i) => sum + i.quantity);

  /// Junta produtos escolhidos no catálogo à lista atual. Produto que já
  /// está na compra não é duplicado: soma 1 à quantidade dele.
  void addProducts(List<ProductEntity> products) {
    for (final product in products) {
      final index = items.indexWhere((i) => i.productId == product.id);
      if (index >= 0) {
        final current = items[index];
        items[index] = current.copyWith(quantity: current.quantity + 1).withRecalculatedDiscount();
      } else {
        items.add(itemFromProduct(product));
      }
    }
  }
}
