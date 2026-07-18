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

Ação explícita ("Fechar Box", com confirmação mostrando quantos lançamentos e qual valor serão congelados). Gera um snapshot imutável (data, total, contagem de lançamentos/itens) e marca os lançamentos daquele momento como congelados — eles somem da lista de lançamentos abertos e não podem mais ser editados ou excluídos. A Box continua existindo e recebendo novos lançamentos. O histórico de Fechamentos de uma Box é acessível a qualquer momento; cada Fechamento pode ser reaberto (com confirmação forte), o que devolve os lançamentos ao estado editável e remove o Fechamento.

## Produtos, Categorias, Tipos de Produto, Unidades

Catálogo reutilizável entre Boxes: um Produto tem nome, código opcional, categoria, tipo e um preço de referência (usado para pré-preencher lançamentos). Categorias, Tipos de Produto e Unidades são entidades completas (CRUD próprio), não apenas enums fixos — o app já vem com um conjunto padrão semeado na primeira execução (`SeedDefaults`), mas o usuário pode criar/editar/remover os seus.

## Dashboard (Início)

Visão "como estou indo agora": soma **todos** os lançamentos do período (abertos e já fechados) — ao contrário de Relatórios, que só considera Fechamentos. Mostra total do mês, média diária, contagem de lançamentos/Boxes ativas, Boxes com maior gasto, gastos recentes e gráficos (evolução mensal, por categoria, por Box) via `fl_chart`.

## Relatórios

Módulo de análise histórica com filtros (período com presets ou intervalo customizado, uma ou várias Boxes, categoria, tipo de produto, produto específico, faixa de valor) e indicadores (total consolidado, médias por Box/dia, contagem de lançamentos/itens, Box/categoria/produto com maior gasto, produto mais comprado, evolução mensal, tabela completa de produtos). Suporta modo de comparação lado a lado (Lado A vs. Lado B, cada um com seu próprio conjunto de filtros). Combinações de filtro podem ser salvas com nome e persistem entre sessões.

**Regra central**: Relatórios só consideram lançamentos que pertencem a um Fechamento — nunca o estado "ao vivo" de uma Box. Isso torna um relatório gerado hoje historicamente estável: editar um lançamento aberto amanhã não muda um relatório de ontem.

## Exportação de Relatório

A partir de um relatório consolidado: PDF (título, período, filtros aplicados, resumo financeiro, tabela de produtos, total geral, data de geração), Compartilhar e Imprimir (via pacote `printing`, reaproveitando o mesmo PDF). CSV e backup-em-JSON-a-partir-do-relatório ainda não implementados (stub com mensagem clara), com o contrato já pronto para receber essas implementações sem mudar a UI.

## Backup e Importação (JSON)

Em Configurações → Dados: "Exportar dados" gera um único arquivo JSON com todo o conteúdo do app (Boxes, Produtos, Categorias, Tipos, Unidades, Transações, Fechamentos — incluindo registros excluídos logicamente) e abre a tela nativa de compartilhamento. "Importar dados" pede confirmação (a importação **substitui** todos os dados atuais, não mescla), permite escolher um arquivo `.json` e repopula o app a partir dele.

## Configurações

Organizadas em grupos:
- **Conta**: Perfil, Sair.
- **Dados**: Exportar dados, Importar dados, Limpar dados.
- **Preferências**: Tema (estrutura pronta, ainda "Em breve" — hoje segue o tema do sistema).
- **Sobre**: Versão do app (via `package_info_plus`), Licenças (tela nativa do Flutter).

### Limpar dados

Seis opções independentes, cada uma atrás de uma confirmação explicando o impacto: Boxes (+ lançamentos e fechamentos), Produtos, Histórico de compras (lançamentos + fechamentos, mantém Boxes e catálogo), Relatórios salvos (combinações de filtro), Preferências (hoje sem efeito — nada persistido ainda) e Restaurar tudo (apaga todos os dados, recria os catálogos padrão e encerra a sessão).

## "Mais"

Hub de navegação secundária: card de conta no topo (toca para abrir o Perfil), Categorias, Tipos de Produto, Unidades, Configurações. Sincronização aparece como "Em breve" (funcionalidade futura, ver `FUTURE_IMPROVEMENTS.md`).
