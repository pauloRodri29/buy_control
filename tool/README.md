# Para que serve a pasta `tool`

Esta pasta guarda scripts que automatizam a manutenção do projeto: assets da marca,
catálogo de componentes e verificação da documentação.

**O aplicativo não precisa executar esses scripts para abrir ou funcionar.**
Eles não são telas nem serviços do app; evitam trabalho manual e encontram
inconsistências durante o desenvolvimento. Mantenha-os versionados para que qualquer
pessoa consiga repetir as mesmas tarefas.

## Scripts disponíveis

Execute os comandos na raiz do projeto, onde está o `pubspec.yaml`.
Os scripts `.mjs` precisam de Node.js; o de marca, do Flutter.

| Script | Quando usar | O que faz | Altera arquivos? |
|---|---|---|---|
| [docs_catalog.mjs](docs_catalog.mjs) | Após criar/remover componentes ou mudar parâmetros | Gera a referência de componentes com assinaturas, padrões e links de uso; remove páginas de famílias que ficaram vazias | Sim: `docs/componentes/catalogo/` |
| [docs_check.mjs](docs_check.mjs) | Após alterar documentação ou regenerar o catálogo | Confere links locais, âncoras, cobertura do inventário de componentes e se a versão bate entre o [histórico](../docs/historico/README.md) e o índice | Não |
| [brand/render_brand_assets_test.dart](brand/render_brand_assets_test.dart) | Após mudar o desenho ou as cores do logo | Desenha o `AppLogoPainter` e grava os PNGs do ícone e da splash | Sim: `assets/brand/` |

## Catálogo de componentes

```sh
node tool/docs_catalog.mjs
node tool/docs_check.mjs
```

O primeiro comando atualiza o catálogo; o segundo confere o resultado. O gerador cobre
`lib/app/widgets/` e as pastas `presentation/widgets/` das features. Ele não reescreve os
guias manuais. Regras de família e títulos: [Manutenção](../docs/manutencao.md#atualizar-o-catálogo).

Não edite as páginas geradas à mão: explique no guia ou no comentário `///` do código e
regenere. A busca é textual; não interprete ausência de chamada como autorização para
apagar código.

<a id="marca-ícone-e-splash"></a>

## Marca: ícone e splash

```sh
flutter test tool/brand/render_brand_assets_test.dart   # gera os PNGs em assets/brand
dart run flutter_launcher_icons                         # ícones de todas as plataformas
dart run flutter_native_splash:create                   # splash nativa
```

O ícone é desenhado em código (`AppLogoPainter`, em `lib/app/brand/app_logo.dart`), o
mesmo usado nas telas. As configurações de ícone e splash ficam no `pubspec.yaml`.

## Se esta pasta for removida

O app continua funcionando, mas você perde as automações: catálogo, verificação da
documentação e geração dos assets da marca passam a ser manuais.

Para acrescentar um script, explique nesta tabela sua finalidade, comando e arquivos
alterados. Para regras de atualização dos documentos, consulte [Manutenção](../docs/manutencao.md).
