# Fluxos

## Login

1. App abre → `AuthGate` chama `GetCurrentUser` para checar se já existe sessão salva.
2. Sem sessão → `LoginPage`: usuário informa e-mail + senha (mínimo 4 caracteres).
3. `Login` (usecase) valida formato e delega a `FakeAuthRepository`:
   - E-mail já usado antes → recupera o perfil existente.
   - E-mail novo → cria um `UserEntity` (nome derivado do e-mail, data de cadastro = agora) e salva.
4. `AuthController` atualiza `status` para `success` → `AuthGate` troca automaticamente para `MainShell`.
5. Em uma reabertura futura do app, o passo 2 é pulado: a sessão salva é encontrada e o usuário cai direto no `MainShell`.

## Perfil

1. Mais → card de conta (ou Configurações → Perfil) → `ProfilePage`.
2. Mostra nome, e-mail, avatar (iniciais), data de cadastro.
3. "Editar perfil" → sheet com nome/e-mail → `UpdateProfile` valida e persiste → `AuthController.currentUser` atualizado.
4. "Sair" → confirmação → `Logout` limpa a sessão ativa (mantém o perfil salvo, para um login futuro com o mesmo e-mail recuperar os dados) → `AuthGate` volta para `LoginPage`.

## Boxes → Lançamento → Fechamento

1. Boxes → criar/abrir uma Box.
2. Dentro da Box: "Adicionar itens" → **Selecionar produtos** (busca + filtro por categoria, define quantidade/preço/desconto por item) **ou** "Lançamento avulso" (título, valor via `AppMoneyField`, quantidade, unidade, categoria/tipo opcionais, data, observação).
3. Lançamento é criado com `closureId = null` (aberto — editável/excluível normalmente).
4. Quando o ciclo de compras termina: ícone de cadeado no topo da Box → "Fechar Box".
   - Se não há lançamentos abertos, o app avisa que não há nada para fechar.
   - Caso contrário, mostra quantos lançamentos e qual valor total serão congelados, pedindo confirmação.
5. Ao confirmar, `CloseBox`:
   - Busca os lançamentos abertos da Box.
   - Calcula total/contagens.
   - Cria o `BoxClosureEntity` (snapshot leve).
   - Marca `closureId` em cada lançamento envolvido.
6. A lista de lançamentos abertos da Box fica vazia (ou só com o que veio depois do fechamento); a Box continua recebendo novos lançamentos normalmente.
7. Ícone de histórico → `BoxClosuresPage` lista todos os Fechamentos da Box → tocar em um abre `BoxClosureDetailPage` (cabeçalho + lançamentos congelados, somente leitura).
8. "Reabrir" (no detalhe do Fechamento) → confirmação forte → `ReopenBoxClosure` limpa `closureId` dos lançamentos (voltam a ser editáveis) e apaga logicamente o Fechamento.

### Guard de imutabilidade

Independente da tela, `UpdateTransaction`/`DeleteTransaction` rejeitam qualquer tentativa de alterar um lançamento com `closureId != null` — a imutabilidade é garantida no domínio, não apenas escondida na UI.

## Relatórios

1. Relatórios (aba) → filtros no topo (período, Box(es), categoria, tipo, produto, faixa de valor).
2. `GetConsolidatedReport` agrega **somente** lançamentos com `closureId != null` (pertencentes a algum Fechamento).
3. Indicadores calculados: total, médias, destaques (Box/categoria/produto), tabela de produtos, evolução mensal.
4. Botão de comparação → ativa Lado A/Lado B, cada lado com seu próprio conjunto de filtros, indicadores exibidos lado a lado.
5. Salvar uma combinação de filtros → nomeia e persiste (Hive) → reaparece em sessões futuras; pode ser removida em Configurações → Dados → Limpar dados → Relatórios salvos.
6. Ícone de exportação → sheet com PDF / CSV / Compartilhar / Imprimir / Backup em JSON:
   - **PDF**: gera o arquivo, salva no armazenamento do app.
   - **Compartilhar/Imprimir**: geram o mesmo PDF e abrem a folha de compartilhamento/impressão nativa.
   - **CSV** e **Backup em JSON** (a partir do relatório): ainda não implementados.

## Exportação (Backup completo)

1. Configurações → Dados → "Exportar dados".
2. `ExportBackup` lê todos os repositórios/data sources (Boxes, Produtos, Categorias, Tipos, Unidades, Transações, Fechamentos — incluindo excluídos logicamente) e serializa tudo em um único JSON com `version` + `exportedAt`.
3. O arquivo é salvo no armazenamento do app com nome `buy_control_backup_<timestamp>.json` e a folha de compartilhamento nativa abre para o usuário salvar/enviar onde quiser.

## Importação

1. Configurações → Dados → "Importar dados".
2. Confirmação explícita: a importação **substitui** todos os dados atuais atuais e não pode ser desfeita.
3. Usuário escolhe um arquivo `.json` (via seletor de arquivos nativo).
4. `ImportBackup` valida o formato (rejeita arquivos sem a chave `version`), limpa cada coleção local e repopula a partir do conteúdo do arquivo.
5. Recomenda-se reiniciar o app após importar, para garantir que todas as telas reflitam os novos dados.

## Limpar dados

1. Configurações → Dados → "Limpar dados".
2. Seis opções, cada uma com sua própria confirmação (mensagem explica exatamente o que será apagado e o que permanece):
   - **Boxes**: remove Boxes + seus lançamentos + Fechamentos.
   - **Produtos**: remove só o catálogo de produtos.
   - **Histórico de compras**: remove lançamentos + Fechamentos, mantém Boxes e catálogo.
   - **Relatórios salvos**: remove combinações de filtro salvas.
   - **Preferências**: hoje sem efeito (nada persistido ainda nessa categoria).
   - **Restaurar tudo**: executa todas as limpezas acima, recria os catálogos padrão (`SeedDefaults`) e encerra a sessão (volta para o login).
