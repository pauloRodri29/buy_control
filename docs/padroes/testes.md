# Testes

[Índice](../README.md) · [Nomenclatura](nomenclatura.md)

```sh
flutter test
flutter analyze
```

`test/` espelha `lib/`: `test/features/<feature>/...`, `test/core/...`, `test/app/...`.

| Tipo | O que cobre | Exemplos |
|---|---|---|
| Unidade (domínio) | casos de uso com repositórios fake em memória: regras de negócio, imutabilidade dos Fechamentos, Planejamento, relatório, cotas, preço do Personalizado, cupons | [close_box_test.dart](../../test/features/box_closures/close_box_test.dart), [subscription_test.dart](../../test/features/subscription/subscription_test.dart), [get_consolidated_report_test.dart](../../test/features/reports/get_consolidated_report_test.dart) |
| Unidade (core) | `Money`, `BarcodeParser` | [money_test.dart](../../test/core/money/money_test.dart), [barcode_parser_test.dart](../../test/core/barcode/barcode_parser_test.dart) |
| Persistência | Entity → Model → `toMap`/`fromMap` → Entity, incluindo registros gravados antes de campos novos | [transaction_persistence_test.dart](../../test/features/transactions/transaction_persistence_test.dart) |
| Backup | diff, controller com prévia substituída, remoto GitHub com cliente HTTP falso | [test/features/backup](../../test/features/backup/) |
| Widget | tema, componentes compartilhados nos dois temas, calendário, tratamento de erros, splash | [test/app](../../test/app/) |
| Fumaça das telas | Hive real com dados de exemplo; abre as abas e as telas do Mais nos temas claro e escuro, em tamanho de celular; falha com exceção de build ou overflow | [screens_smoke_test.dart](../../test/app/screens_smoke_test.dart) |
| Traduções | chaves usadas em `lib/` existem nos JSON, mesmas chaves e parâmetros nos idiomas | [translations_test.dart](../../test/core/i18n/translations_test.dart) |

[flutter_test_config.dart](../../test/flutter_test_config.dart) roda antes de cada arquivo:
carrega `assets/i18n` e deixa o português ativo, então os testes veem os textos reais.

## Ao mudar código

- Regra nova ou alterada no domínio → teste de unidade do caso de uso.
- Tela nova → acrescente ao `screens_smoke_test.dart`.
- Texto novo → chave nos dois JSON (o teste de traduções cobra).
- Componente compartilhado novo → teste nos dois temas e `node tool/docs_catalog.mjs`.
