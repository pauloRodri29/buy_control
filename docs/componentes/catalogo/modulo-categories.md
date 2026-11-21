# Módulo: Categorias

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [category_form_sheet](#category-form-sheet)

<a id="category-form-sheet"></a>

## category_form_sheet

**Código:** [lib/features/categories/presentation/widgets/category_form_sheet.dart](../../../lib/features/categories/presentation/widgets/category_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### CategoryFormSheet

Formulário de criação/edição de categoria. Todo o estado fica local ao
widget (rascunho) — nada é persistido até o usuário tocar em Salvar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const CategoryFormSheet({super.key, this.category});

// Tipos dos campos públicos declarados nesta classe.
  final CategoryEntity? category;
```

</details>

**Onde usar como referência:**

- [lib/features/categories/presentation/pages/categories_page.dart](../../../lib/features/categories/presentation/pages/categories_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
CategoryFormSheet(category: category)
```

