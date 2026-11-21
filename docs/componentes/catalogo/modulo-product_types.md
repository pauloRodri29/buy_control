# Módulo: Tipos de produto

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [product_type_form_sheet](#product-type-form-sheet)

<a id="product-type-form-sheet"></a>

## product_type_form_sheet

**Código:** [lib/features/product_types/presentation/widgets/product_type_form_sheet.dart](../../../lib/features/product_types/presentation/widgets/product_type_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### ProductTypeFormSheet

Formulário de criação/edição de tipo de produto. Todo o estado fica
local ao widget (rascunho) — nada é persistido até o usuário tocar em
Salvar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const ProductTypeFormSheet({super.key, this.productType});

// Tipos dos campos públicos declarados nesta classe.
  final ProductTypeEntity? productType;
```

</details>

**Onde usar como referência:**

- [lib/features/product_types/presentation/pages/product_types_page.dart](../../../lib/features/product_types/presentation/pages/product_types_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
ProductTypeFormSheet(productType: type)
```

