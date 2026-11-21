# Rede

[Configurações](README.md) · [Backup](../fluxos/backup.md)

O app é offline-first. A **única** comunicação de rede é o backup no GitHub
([GithubBackupRemote](../../lib/features/backup/data/github_backup_remote.dart), pacote `http`),
disparada só por ação do usuário. Login, planos e cupons são locais.

## API do GitHub

| Operação (`BackupRemote`) | Chamada | Observações |
|---|---|---|
| `testConnection` | `GET /repos/{dono}/{repo}` | recusa repositório **público** |
| `fetchLatest` | `GET /repos/{dono}/{repo}/contents/{path}` | 404 = ainda não há backup |
| `upload` | `PUT /repos/{dono}/{repo}/contents/{path}` | conteúdo em base64 + `sha` esperado; 409/422 = alguém enviou antes, não sobrescreve |
| `history` | `GET /repos/{dono}/{repo}/commits?path=…&per_page=30` | 409 = repositório vazio |
| `download` | `GET …/contents/{path}?ref={sha}` | formato bruto (`application/vnd.github.raw+json`) |

Cabeçalhos: `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`,
`X-GitHub-Api-Version: 2022-11-28`, `User-Agent: GastoLog-App`. Host `api.github.com`,
caminho padrão do arquivo `gastolog-backup.json`.

**Timeout:** 25 s por chamada (`timeout` no construtor).

## Erros

Toda falha vira `NetworkFailure` com mensagem pronta para o usuário (o que aconteceu e o
que fazer):

| Situação | Mensagem (resumo) |
|---|---|
| 401 | token inválido ou revogado |
| 403 / 429 com limite zerado | limite de uso da API atingido |
| 403 | token sem permissão no repositório |
| 404 | repositório não encontrado |
| 5xx | GitHub instável, com o código |
| sem internet / falha TLS | sem conexão / não abriu conexão segura |
| resposta inesperada | `UnknownFailure` |

## Outro provedor

Implemente [BackupRemote](../../lib/features/backup/domain/repositories/backup_remote.dart)
(WebDAV, Drive...) e crie-o onde o `BackupController` monta o remoto (`_remote()`). O
roteiro de conferência, a cópia de segurança e o histórico continuam iguais.

Nunca coloque token em código, teste ou documentação; o token do usuário fica só no
armazenamento seguro.
