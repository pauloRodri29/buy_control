# Backup e restauração

[Fluxos](README.md) · [Rede](../configuracoes/rede.md) · [Armazenamento](../configuracoes/armazenamento.md)

**Entrada:** Mais → Configurações → Dados → **Backup e restauração** (`BackupPage`).
Backup manual é do plano Grátis em diante (`backupManual`): o usuário sempre consegue
levar os próprios dados.

## O que entra no backup

Um único JSON (`ExportBackup`) com `version` (`backupFormatVersion = 1`), `exportedAt` e uma
chave por coleção, **incluindo registros excluídos logicamente**:

| Chave | Conteúdo |
|---|---|
| `boxes` | Boxes |
| `transactions` | lançamentos |
| `boxClosures` | Fechamentos |
| `products` | produtos |
| `categories`, `productTypes`, `units` | catálogos |
| `planBoards`, `planItems` | Planejamento (opcionais: backups antigos sem elas mantêm o Planejamento local) |

**Não entram:** sessão, assinatura e cupons (box `subscription`), filtros de relatório salvos,
preferências (`app_meta`) e a configuração do GitHub.

## Roteiro comum: ler → comparar → conferir → agir

Toda operação que muda dados segue o mesmo caminho no `BackupController`:

1. lê o que chega (arquivo, versão da nuvem ou cópia de segurança) e valida (`BackupSnapshot.parse`);
2. compara por id com o que existe (`BackupDiff`);
3. abre **Conferir** (`BackupPreviewPage`): totais do que entra / muda / sai, lista por tipo
   de dado e avisos (backup mais antigo que a última alteração local, registros locais mais
   novos que seriam trocados, registros que serão apagados, coleções mantidas);
4. só age depois de confirmar.

## Arquivo

| Ação | Efeito |
|---|---|
| Exportar para arquivo | gera `gastolog_backup_<data-hora>.json` e abre o compartilhamento nativo |
| Importar de arquivo | escolhe um `.json` (`file_picker`) → roteiro comum → **substitui** os dados |

## Nuvem (GitHub)

**Configurar** (`GithubSettingsPage`): link do repositório (`dono/repo`, URL com ou sem `.git`)
e token *fine-grained* com "Contents: Read and write" só nesse repositório. "Testar" valida
acesso; **repositório público é recusado**. O token vai para o armazenamento seguro do sistema
(`flutter_secure_storage`); dono, repositório e caminho ficam no `app_meta`.

| Ação | Etapas |
|---|---|
| Enviar agora | lê o backup atual da nuvem → Conferir (nuvem × aparelho) → envia com o `sha` lido. Se alguém enviou de outro aparelho no meio, o GitHub recusa (409/422) em vez de sobrescrever |
| Histórico | lista os commits do arquivo `gastolog-backup.json` (até 30); qualquer versão pode ser restaurada |
| Restaurar | baixa a versão escolhida → roteiro comum → substitui |
| Desconectar | apaga token e configuração |

Cada envio é um commit; a mensagem tem título com data/hora e um resumo das contagens.
O card mostra o último envio com sucesso e, se a última tentativa falhou, a mensagem de erro.

## Substituir é reversível

- Importar **substitui** cada coleção (não mescla), de propósito: mesclar exigiria resolver
  conflitos de id/versão de forma ambígua.
- Antes de substituir, o app grava uma **cópia de segurança** dos dados atuais
  (`SafetySnapshotStore`, só a última). "Desfazer última importação" restaura essa cópia.
- Se a importação falhar no meio, os dados anteriores são restaurados automaticamente.
- Não há atualização global depois de importar: o aviso recomenda reiniciar o app.

**Atividade recente:** as últimas 30 operações (sucesso ou erro) ficam em `app_meta`
(`backup.log`).

| Alterar | Fonte |
|---|---|
| Coleções e descrição de cada registro | [backup_collections.dart](../../lib/features/backup/domain/entities/backup_collections.dart) |
| Formato e versão | [export_backup.dart](../../lib/features/backup/domain/usecases/export_backup.dart), [import_backup.dart](../../lib/features/backup/domain/usecases/import_backup.dart) |
| Comparação | [backup_diff.dart](../../lib/features/backup/domain/entities/backup_diff.dart), [backup_snapshot.dart](../../lib/features/backup/domain/entities/backup_snapshot.dart) |
| Roteiro e mensagens | [backup_controller.dart](../../lib/features/backup/presentation/controllers/backup_controller.dart) |
| Destino remoto | [backup_remote.dart](../../lib/features/backup/domain/repositories/backup_remote.dart), [github_backup_remote.dart](../../lib/features/backup/data/github_backup_remote.dart) |
| Configuração, token e registro | [backup_settings_store.dart](../../lib/features/backup/data/backup_settings_store.dart) |
| Cópia de segurança | [safety_snapshot_store.dart](../../lib/features/backup/data/safety_snapshot_store.dart) |
| Testes | [test/features/backup](../../test/features/backup/) |
