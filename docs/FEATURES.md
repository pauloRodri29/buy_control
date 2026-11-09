# Funcionalidades

## Autenticação (fake)

Login com e-mail + senha (validação apenas de formato: e-mail válido, senha com 4+ caracteres — não há verificação real de credenciais). No primeiro login com um e-mail, um perfil é criado automaticamente (nome derivado do e-mail, data de cadastro = agora); logins seguintes com o mesmo e-mail recuperam o mesmo perfil. A sessão persiste entre reaberturas do app (Hive), sem precisar logar de novo. Estrutura pronta para uma futura `ApiAuthRepository` substituir a implementação fake sem tocar em tela alguma.

## Perfil

Mostra nome, e-mail, avatar (placeholder com iniciais) e data de cadastro. "Editar perfil" abre uma sheet para alterar nome/e-mail. "Sair" desloga (com confirmação) e volta para a tela de login.

## Boxes (caixas de gasto)

Uma Box é um contexto nomeado de gastos (ex.: "Mercado", "Farmácia"). Suporta busca, ordenação (recentes/nome/valor) e exclusão lógica (soft delete — o registro nunca é apagado de fato, só marcado). Uma Box permanece disponível para novos lançamentos para sempre, mesmo depois de "fechada".

## Lançamentos (transações)

Dentro de uma Box, o usuário registra compras de duas formas:
- **Selecionar produtos**: escolhe produtos do catálogo (com busca e filtro por categoria), define quantidade/preço unitário/desconto/acréscimo por item — o preço já vem pré-preenchido do preço de referência do produto, mas é editável.
- **Lançamento avulso**: título livre, valor, quantidade, unidade, categoria/tipo opcionais, data e observação — para gastos que não correspondem a um produto cadastrado.

Todo lançamento tem um total calculado (soma dos itens − desconto + acréscimo, nunca negativo) e pode ser buscado/ordenado dentro da Box.

## Fechamento de Box

Fechar a Box é uma ação explícita. O usuário escolhe a data de referência e confirma num aviso que mostra quantos itens e qual valor serão congelados. O fechamento gera um registro imutável com data, total e contagem de lançamentos e itens.

Os lançamentos daquele momento ficam congelados e não podem mais ser editados nem excluídos. Os que estão marcados como "Repetir no próximo ciclo" são copiados como novos lançamentos abertos. A Box continua existindo e recebendo lançamentos.

O histórico de Fechamentos de uma Box pode ser consultado a qualquer momento. Fechamentos são definitivos: não há como reabrir.

## Produtos, Categorias, Tipos de Produto, Unidades

Catálogo reutilizável entre Boxes: um Produto tem nome, código opcional, categoria, tipo e um preço de referência (usado para pré-preencher lançamentos). Categorias, Tipos de Produto e Unidades são entidades completas (CRUD próprio), não apenas enums fixos — o app já vem com um conjunto padrão semeado na primeira execução (`SeedDefaults`), mas o usuário pode criar/editar/remover os seus.

## Dashboard (Início)

Visão geral do período. Como nos Relatórios, considera **só lançamentos fechados**, datados pela data de referência do Fechamento. Mostra o total do mês, a média diária, a contagem de lançamentos e de Boxes ativas, as Boxes com maior gasto, os gastos recentes e gráficos com `fl_chart` (evolução mensal, por categoria e por Box). As cores dos gráficos vêm do tema (`AppSemanticColors.chartSeries`).

## Planejamento (aba "Planejar")

Quadros no estilo kanban para compras futuras. Cada quadro é um contexto, como "Dezembro" ou "Fim de ano", e tem:
- título e descrição opcional;
- data de previsão, que define a ordem dos quadros;
- meta de gasto opcional;
- N itens.

Cada item tem título, descrição opcional e valor estimado opcional. Itens sem quadro ficam na coluna "Sem quadro".

- **Organizar:** segurar e arrastar um item move ele entre quadros e posições. Arrastar até a borda da tela rola os quadros sozinho.
- **Acompanhar a meta:** o cabeçalho de cada quadro mostra o planejado, o já comprado e o progresso da meta, e avisa quando a meta é ultrapassada.
- **Comprar:** cada item pode ser marcado como comprado individualmente.
- **Fechar o quadro:** um bottom sheet de confirmação mostra o resumo, avisa sobre itens sem valor e pede a data da compra. Ao confirmar, todos os itens pendentes são marcados como comprados.
- **Depois de fechado:** o quadro pode ser reaberto, arquivado ou excluído. Ao excluir, o usuário escolhe se apaga os itens junto ou se eles vão para "Sem quadro".

Um item só entra nos Relatórios depois de marcado como comprado, no mês da data da compra.

## Relatórios

Módulo de análise histórica com filtros (período com presets ou intervalo customizado, uma ou várias Boxes, categoria, tipo de produto, produto específico, faixa de valor) e indicadores (total consolidado, médias por Box/dia, contagem de lançamentos/itens, Box/categoria/produto com maior gasto, produto mais comprado, evolução mensal, tabela completa de produtos). Suporta modo de comparação lado a lado (Lado A vs. Lado B, cada um com seu próprio conjunto de filtros). Combinações de filtro podem ser salvas com nome e persistem entre sessões.

Ficam em Mais → Relatórios.

**Regra central:** dos lançamentos das Boxes, os Relatórios só consideram os que pertencem a um Fechamento, nunca o estado "ao vivo" de uma Box. Assim, um relatório gerado hoje continua o mesmo amanhã: editar um lançamento aberto não muda um relatório já feito.

**Planejamento no relatório:** um card próprio mostra os itens comprados no período (por quadro), a previsão dos itens pendentes e a comparação com as metas dos quadros. Os itens comprados entram no total e na evolução mensal pela data da compra. Quando há filtro de Box, categoria, tipo ou produto, o Planejamento fica de fora, porque os itens dos quadros não têm essas informações.

## Exportação de Relatório

A partir de um relatório consolidado: PDF (título, período, filtros aplicados, resumo financeiro, tabela de produtos, total geral, data de geração), Compartilhar e Imprimir (via pacote `printing`, reaproveitando o mesmo PDF). CSV e backup-em-JSON-a-partir-do-relatório ainda não implementados (stub com mensagem clara), com o contrato já pronto para receber essas implementações sem mudar a UI.

## Backup e Importação (JSON)

Em Configurações → Dados: "Exportar dados" gera um único arquivo JSON com todo o conteúdo do app (Boxes, Produtos, Categorias, Tipos, Unidades, Transações, Fechamentos, quadros e itens do Planejamento — incluindo registros excluídos logicamente; backups antigos sem Planejamento continuam importáveis e não apagam os quadros existentes) e abre a tela nativa de compartilhamento. "Importar dados" pede confirmação (a importação **substitui** todos os dados atuais, não mescla), permite escolher um arquivo `.json` e repopula o app a partir dele.

## Configurações

Organizadas em grupos:
- **Conta**: Perfil, Sair.
- **Dados**: Exportar dados, Importar dados, Limpar dados.
- **Preferências**: Tema — Automático (segue o sistema), Claro ou Escuro. A escolha é salva no `AppMetaStore` e aplicada na hora pelo `ThemeController`.
- **Sobre**: "Sobre o sistema" abre uma tela com o que o app faz, como os dados são guardados (no aparelho, sem internet, backup manual), versão, compilação e licenças de código aberto.

### Limpar dados

Sete opções independentes, cada uma com uma confirmação que explica o impacto:
- **Boxes:** apaga as Boxes com seus lançamentos e fechamentos.
- **Produtos:** apaga o catálogo de produtos.
- **Histórico de compras:** apaga lançamentos e fechamentos, mas mantém as Boxes e o catálogo.
- **Planejamento:** apaga os quadros e os itens.
- **Relatórios salvos:** apaga as combinações de filtro salvas.
- **Preferências:** volta o tema para o automático.
- **Restaurar tudo:** apaga todos os dados, restaura as preferências, recria os catálogos padrão e encerra a sessão.

## Navegação

Barra inferior com cinco abas: **Início**, **Boxes**, **Produtos**, **Planejar** e **Mais**.

O menu **Mais** é o ponto de entrada das telas secundárias. No topo há o card da conta, que abre o Perfil. Abaixo vêm Relatórios, Categorias, Tipos de Produto, Unidades e Configurações. Sincronização aparece como "Em breve".

## Tema e feedback

Todo o visual vem do tema nativo do Material 3 (`ColorScheme`, `TextTheme` e os temas de cada componente), em versões clara e escura. Os avisos usam o `SnackBar` nativo, e as confirmações usam `AlertDialog` e bottom sheets nativos.

As melhorias candidatas para as próximas versões estão em [CANDIDATE_FEATURES.md](CANDIDATE_FEATURES.md).
