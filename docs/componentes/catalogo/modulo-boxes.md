# Módulo: Boxes

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [box_form_sheet](#box-form-sheet)

<a id="box-form-sheet"></a>

## box_form_sheet

**Código:** [lib/features/boxes/presentation/widgets/box_form_sheet.dart](../../../lib/features/boxes/presentation/widgets/box_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### BoxFormSheet

Formulário de criação/edição de caixa. Todo o estado fica local ao
widget (rascunho) — nada é persistido até o usuário tocar em Salvar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const BoxFormSheet({super.key, this.box});

// Tipos dos campos públicos declarados nesta classe.
  final BoxEntity? box;
```

</details>

**Onde usar como referência:**

- [lib/features/boxes/presentation/pages/boxes_page.dart](../../../lib/features/boxes/presentation/pages/boxes_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
BoxFormSheet(box: box)
```

