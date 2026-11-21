# Como manter a documentação

[Índice](README.md)

Os scripts auxiliares ficam em `tool`. Veja [para que servem e como executá-los](../tool/README.md).

## Um assunto, um lugar

| Mudou no código | Atualizar |
|---|---|
| Etapas, entrada, saída, validação ou dados de um módulo | `fluxos/<modulo>.md` |
| Hive box nova, chave nova no `app_meta`, formato gravado, limpeza | `configuracoes/armazenamento.md` |
| Plano, limite, módulo (`FeatureKey`/`ResourceKey`), preço, cupom | `configuracoes/planos-e-limites.md` e [Planos](fluxos/planos.md) |
| Aba, item do menu Mais, binding ou registro no `InitialBinding` | `configuracoes/navegacao.md` |
| Chamada HTTP, timeout, cabeçalho ou outro destino remoto | `configuracoes/rede.md` |
| Cor, fonte, ícone, espaçamento, idioma, formato de data/moeda | `configuracoes/visual-e-idioma.md` |
| Nova falha, mudança em `Result`, `Money` ou estados de tela | `padroes/erros-e-resultados.md` |
| Nova camada, sufixo ou pasta | `padroes/nomenclatura.md` |
| Modo de usar componente | `componentes/README.md` |
| Assinatura/default/novo componente | regenerar catálogo |
| Novo módulo ou nova página de docs | índice da área e, se necessário, índice geral |
| Coleção nova no backup | [Backup](fluxos/backup.md) e `configuracoes/armazenamento.md` |

Não copie a mesma regra para várias páginas: explique no documento dono e coloque
link nas demais. Não trate comentário antigo como evidência quando o código difere
(ex.: comentários que ainda citam `docs/MONETIZATION.md`, que não existe mais).
Descreva o comportamento atual, separando o que é real, simulado e não implementado.

## Formato de uma página de fluxo

```markdown
# Nome do módulo

[Fluxos](README.md) · [Configuração relacionada](../configuracoes/README.md)

**Entrada:** de onde o usuário chega.

1. Primeira ação.
2. Próxima etapa e validação.
3. Resultado e retorno.

**Dados atuais:** origem, persistência e limitações observadas.

| Alterar | Fonte |
|---|---|
| Regra/tela/dados | link relativo para o arquivo dono |
```

Use links relativos para arquivos, não números de linha que envelhecem.
Exemplos de código devem usar a API atual, variáveis com significado e nenhum
token/credencial real. Catálogo técnico é referência; guias manuais explicam a escolha.

## Atualizar o catálogo

```sh
node tool/docs_catalog.mjs
node tool/docs_check.mjs
```

O gerador percorre os `.dart` de `lib/app/widgets/` e das pastas
`lib/features/<feature>/presentation/widgets/`; não inclui `.g.dart`. Produz famílias
em `componentes/catalogo/`, assinaturas/defaults, links de uso e `inventario.json`.
Não edite os arquivos gerados à mão: anote a explicação no guia manual ou no
comentário `///` do componente e regenere.

`lib/app/widgets/` não tem subpastas, então a família de cada arquivo vem do mapa
`sharedFamilies` em `tool/docs_catalog.mjs`. Componente compartilhado novo fora do
mapa cai em "Outros compartilhados"; acrescente-o ao mapa. Feature nova recebe título
no mapa `titles`.

A extração usa busca textual, não análise semântica Dart: referências encontradas
precisam de revisão; ausência de chamada não autoriza apagar API. Componentes
em `presentation/pages/` (sheets e passos de fluxo) não entram no catálogo: são
explicados nos [fluxos](fluxos/README.md).

O verificador confere arquivos dos links, âncoras locais, cobertura do inventário
e a versão. Ele não substitui revisão das regras descritas.

## Versionar a atualização

Toda atualização da documentação sobe a versão e ganha data e entrada no
[histórico](historico/README.md), que explica quando subir MAJOR, MINOR ou PATCH.
A versão aparece em dois lugares, o histórico e o topo do [índice](README.md), e o
verificador confere se os dois batem.

## Verificação antes de entregar

1. Compare o documento com caso de uso, repositório, controller e binding atuais.
2. Abra o índice e siga o caminho de leitura até a página alterada.
3. Registre a versão no [histórico](historico/README.md) e no índice.
4. Rode o verificador; para alteração de código, rode também `flutter analyze` e `flutter test`.
5. Se só mudou Markdown, não precisa compilar o app.
