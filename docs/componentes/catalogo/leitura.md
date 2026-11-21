# Leitura de código de barras

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [barcode_scanner_page](#barcode-scanner-page)

<a id="barcode-scanner-page"></a>

## barcode_scanner_page

**Código:** [lib/app/widgets/barcode_scanner_page.dart](../../../lib/app/widgets/barcode_scanner_page.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### BarcodeScannerPage

Leitor de código de barras em tela cheia.

- [scanOnce]: lê um código e volta com ele (ex.: cadastro de produto).
- [scanContinuous]: "modo carrinho" — cada leitura chama [OnBarcodeScanned]
  e a câmera continua aberta até o usuário tocar em "Concluir".

Só lê códigos **dentro do retângulo** (`scanWindow` do `MobileScanner`);
a moldura fica verde enquanto há um código válido nele. Só aceita
códigos de produto válidos (dígito verificador conferido) e ignora o
mesmo código por alguns segundos, para não contar duas vezes a mesma
embalagem parada na frente da câmera.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
static Future<ScannedCode?> scanOnce(BuildContext context, {String title = 'common.scanBarcode'});

static Future<void> scanContinuous(
    BuildContext context, {
    required OnBarcodeScanned onScanned,
    String title = 'common.scanProducts',
  });

// Tipos dos campos públicos declarados nesta classe.
  final String title;
  final OnBarcodeScanned? onScanned;
```

</details>

**Onde usar como referência:**

- [lib/features/products/presentation/widgets/product_form_sheet.dart](../../../lib/features/products/presentation/widgets/product_form_sheet.dart)
- [lib/features/transactions/presentation/pages/standalone_entry_sheet.dart](../../../lib/features/transactions/presentation/pages/standalone_entry_sheet.dart)
- [lib/features/transactions/presentation/scan_items_flow.dart](../../../lib/features/transactions/presentation/scan_items_flow.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
BarcodeScannerPage.scanOnce(context)
```

