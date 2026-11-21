# Módulo: Produtos

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [product_form_sheet](#product-form-sheet)

<a id="product-form-sheet"></a>

## product_form_sheet

**Código:** [lib/features/products/presentation/widgets/product_form_sheet.dart](../../../lib/features/products/presentation/widgets/product_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ProductFormSheet

Formulário de criação/edição de produto. Todo o estado fica local ao
widget (rascunho) — nada é persistido até o usuário tocar em Salvar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ProductFormSheet({
    super.key,
    this.product,
    this.initialBarcodes = const [],
    this.initialName,
    this.onCreated,
  });

// Tipos dos campos públicos declarados nesta classe.
  final ProductEntity? product;
  final List<String> initialBarcodes;
  final String? initialName;
  final void Function(ProductEntity product)? onCreated;
```

</details>

**Onde usar como referência:**

- [lib/features/products/presentation/pages/products_page.dart](../../../lib/features/products/presentation/pages/products_page.dart)
- [lib/features/transactions/presentation/pages/product_picker_sheet.dart](../../../lib/features/transactions/presentation/pages/product_picker_sheet.dart)
- [lib/features/transactions/presentation/scan_items_flow.dart](../../../lib/features/transactions/presentation/scan_items_flow.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ProductFormSheet(product: product)
```

