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
2. Dentro da Box: "Adicionar itens" → **Selecionar produtos** (busca + filtro por categoria) **ou** "Lançamento avulso" (título, valor via `AppMoneyField`, quantidade, unidade, promoção, categoria/tipo opcionais, data, observação).
3. Produtos: editor de itens (`ItemDetailsStep`) → quantidade (− / +), preço, unidade, promoção, acréscimo; remover item; "Adicionar produto" reabre o catálogo. → Resumo (`PurchaseSummaryStep`): desconto/acréscimo gerais; "Editar itens" (ou tocar num item) volta ao editor sem perder nada. → "Confirmar" grava. Todo o estado em edição vive num `PurchaseDraft`.
4. Lançamento é criado com `closureId = null` (aberto). Tocar nele no detalhe da Box reabre o mesmo fluxo para editar (`openEditTransactionFlow` → `UpdateTransaction`); avulso abre o formulário avulso preenchido.
5. Quando o ciclo de compras termina: ícone de cadeado no topo da Box →
   - Se não há lançamentos abertos, o app avisa que não há nada para fechar.
   - Escolhe a **data de referência** (só a data, padrão hoje).
   - Diálogo de confirmação com quantidade de itens e total, avisando que é definitivo.
6. Ao confirmar, `CloseBox` (tudo ou nada — qualquer falha desfaz o que já foi gravado):
   - Cria o `BoxClosureEntity` com `referenceDate`, total e contagens.
   - Marca `closureId` + `closureReferenceDate` em cada lançamento aberto (congelado para sempre).
   - **Copia** cada lançamento fechado como novo lançamento aberto (mesmos itens, quantidades, preços e promoções; ids novos; data de hoje). A Box não esvazia: o próximo ciclo já começa com a lista de compras de sempre, e o usuário só ajusta o que mudou.
7. Ícone de histórico → `BoxClosuresPage` lista os Fechamentos (data de referência, nº de itens, total) → tocar em um abre `BoxClosureDetailPage`: lista de produtos somente leitura.
8. Fechamentos são definitivos: não há reabrir nem editar.

### Leitura de código de barras (câmera, tudo local)

Entradas: "Adicionar itens" → **Escanear produtos (câmera)**; botão **Escanear** no editor de itens (compra nova); ícone de câmera no campo "Códigos de barras" do cadastro de produto.

`BarcodeScannerPage` (pacote `mobile_scanner`) lê EAN-13, EAN-8 e UPC-A, confere o dígito verificador (`BarcodeParser`) e ignora o mesmo código por 3 s. No modo carrinho (`scanIntoDraft`) cada leitura vai para o `PurchaseDraft`:

- **Código conhecido** (`FindProductByBarcode`) → adiciona o produto ou soma +1.
- **Etiqueta de balança** (EAN-13 começando com 2: `2 CCCCCC VVVVV D`) → `ScaleLabelSheet`: o usuário confirma se o número é **preço** ou **peso** (pode corrigir) e vincula a etiqueta a um produto. A parte fixa (`2CCCCCC`) fica salva no produto e as próximas etiquetas, com qualquer valor, são reconhecidas. Cada etiqueta vira um item separado.
- **Código desconhecido** → cadastrar produto novo (formulário já com o código), vincular a produto existente (`LinkBarcodeToProduct`), lançar avulso (pede o nome) ou ignorar.

Produtos têm **vários códigos** (`ProductEntity.barcodes`); um código só pode pertencer a um produto (`ProductBarcodes.findConflict`). Registros antigos com um único `barcode` continuam sendo lidos. Se as balanças do mercado usarem outra divisão da etiqueta, ajuste `BarcodeParser.scaleKeyLength`/`scaleValueLength`.

### Promoções (desconto por item)

`DiscountRule` (`transactions/domain/entities/discount_rule.dart`) calcula o desconto a partir de quantidade e preço — o usuário nunca faz conta de cabeça:

| Tipo | Exemplo |
|---|---|
| Valor fixo | R$ 2,00 de desconto |
| Percentual | 10% |
| Leve N por R$ X | Leve 4 por R$ 10,00 (o que sobra fora do grupo sai pelo preço normal) |
| Leve N, pague M | Leve 3, pague 2 |
| Preço a partir de N un. | A partir de 6 un., R$ 3,49 cada |

O valor calculado é gravado em `TransactionItemEntity.discount` (snapshot) junto da regra, e recalculado sempre que quantidade/preço mudam no editor.

### Balanço e relatórios

Dashboard, Relatórios e totais por Box consideram **só lançamentos fechados**, datados por `TransactionEntity.accountingDate` (= data de referência do Fechamento; Fechamentos antigos usam a data do lançamento). O cabeçalho da Box mostra o total do ciclo aberto.

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
