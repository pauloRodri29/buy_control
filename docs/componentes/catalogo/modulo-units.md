# Módulo: Unidades

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [unit_form_sheet](#unit-form-sheet)

<a id="unit-form-sheet"></a>

## unit_form_sheet

**Código:** [lib/features/units/presentation/widgets/unit_form_sheet.dart](../../../lib/features/units/presentation/widgets/unit_form_sheet.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### UnitFormSheet

Formulário de criação/edição de unidade. Todo o estado fica local ao
widget (rascunho) — nada é persistido até o usuário tocar em Salvar.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const UnitFormSheet({super.key, this.unit});

// Tipos dos campos públicos declarados nesta classe.
  final UnitEntity? unit;
```

</details>

**Onde usar como referência:**

- [lib/features/units/presentation/pages/units_page.dart](../../../lib/features/units/presentation/pages/units_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
UnitFormSheet(unit: unit)
```

