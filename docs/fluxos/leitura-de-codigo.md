# Leitura de código de barras

[Fluxos](README.md) · [Boxes e lançamentos](boxes-e-lancamentos.md) · [Produtos](catalogos.md)

Tudo local: a câmera lê, o app interpreta e procura no catálogo do aparelho.

**Entradas:**

- "Adicionar itens" → **Escanear produtos**;
- botão **Escanear** no editor de itens (compra nova);
- ícone de câmera no campo "Códigos de barras" do cadastro de produto (lê um código e volta).

## Leitor

`BarcodeScannerPage` (`mobile_scanner`) lê só dentro do retângulo; a moldura fica verde com
um código válido. Aceita EAN-13, EAN-8, UPC-A e GTIN-14 com dígito verificador conferido
(`BarcodeParser`) e ignora o mesmo código por alguns segundos.

- `scanOnce`: lê um código e devolve (cadastro de produto).
- `scanContinuous` ("modo carrinho"): cada leitura vai para o `PurchaseDraft`; a câmera
  continua aberta até "Concluir". Nada vira lançamento até o "Confirmar" do resumo.

## O que acontece com cada código

| Código lido | Resultado |
|---|---|
| Conhecido (`FindProductByBarcode`) | adiciona o produto ou soma +1 |
| Produto bloqueado pelo plano | aviso em vez de usar ([itens inacessíveis](../configuracoes/planos-e-limites.md#itens-inacessíveis)) |
| Etiqueta de balança | `ScaleLabelSheet` — exige o módulo `scaleLabel` (Pro); ver abaixo |
| Desconhecido | `UnknownBarcodeSheet`: cadastrar produto (já com o código), vincular a produto existente (`LinkBarcodeToProduct`), lançar avulso ou ignorar |

Cadastrar produto e vincular código são gravados na hora (são catálogo, não compra).

## Etiqueta de balança

EAN-13 começando com `2`, no layout `2 CCCCCC VVVVV D` (prefixo, código interno da loja,
valor, dígito). O usuário confirma se o valor é **preço** (centavos) ou **peso** (gramas),
pode corrigir e vincula a etiqueta a um produto. A parte fixa (`2CCCCCC`) fica salva no
produto e as próximas etiquetas, com qualquer valor, são reconhecidas. Cada etiqueta vira
um item separado.

Se as balanças do mercado usarem outra divisão, ajuste
`BarcodeParser.scaleKeyLength`/`scaleValueLength`.

## Vários códigos por produto

`ProductEntity.barcodes` guarda vários códigos já normalizados; um código só pode pertencer
a um produto (`ProductBarcodes.findConflict`). Registros antigos com um único `barcode`
continuam sendo lidos.

| Alterar | Fonte |
|---|---|
| Interpretação e layout da etiqueta | [barcode_parser.dart](../../lib/core/barcode/barcode_parser.dart) |
| Câmera e janela de leitura | [barcode_scanner_page.dart](../../lib/app/widgets/barcode_scanner_page.dart) |
| Modo carrinho | [scan_items_flow.dart](../../lib/features/transactions/presentation/scan_items_flow.dart) |
| Sheets | [scale_label_sheet.dart](../../lib/features/transactions/presentation/pages/scale_label_sheet.dart), [unknown_barcode_sheet.dart](../../lib/features/transactions/presentation/pages/unknown_barcode_sheet.dart) |
| Conflito de códigos | [product_barcodes.dart](../../lib/features/products/domain/product_barcodes.dart) |
| Testes | [barcode_parser_test.dart](../../test/core/barcode/barcode_parser_test.dart), [product_barcodes_test.dart](../../test/features/products/product_barcodes_test.dart) |
