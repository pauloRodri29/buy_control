# Próximas melhorias

Ideias fora do escopo atual, organizadas por área. Nenhuma delas exige mudança estrutural na arquitetura já existente — o app foi construído para crescer nessas direções sem retrabalho.

## Sincronização e multiusuário
- **Sincronização em nuvem**: `SyncableFields`/`SyncStatus` já existem em toda entidade persistida (`id`, `createdAt`, `updatedAt`, `deletedAt`, `syncStatus`, `version`) especificamente para isso — falta apenas o transporte (API/websocket) e a resolução de conflitos.
- **Múltiplos usuários / compartilhamento de Box**: hoje uma Box pertence implicitamente ao único usuário do dispositivo; compartilhar uma Box exigiria um conceito de "membros da Box" e permissões.
- **Autenticação real**: substituir `FakeAuthRepository` por uma `ApiAuthRepository` (JWT ou similar) implementando a mesma interface `AuthRepository` — nenhuma tela muda.
- **Backup automático** (em vez de exportação manual): agendar `ExportBackup` periodicamente e enviar para um armazenamento remoto.

## Relatórios e dashboards
- **Gráficos adicionais no módulo de Relatórios** (hoje só a tabela de evolução mensal existe ali; o Dashboard já tem gráficos via `fl_chart` — extrapolar para Relatórios é direto, dado que `ConsolidatedReport` já centraliza os dados).
- **Exportação em CSV** e **backup-em-JSON a partir de um relatório filtrado**: contrato (`ReportExporter`) já preparado, faltam as implementações concretas (hoje retornam `NotImplementedFailure`).
- **Metas de gastos** (por Box, categoria ou geral, com alerta ao se aproximar/ultrapassar).

## Notificações
- Lembrete para fechar uma Box com lançamentos antigos ainda abertos.
- Alerta de meta de gastos.

## Preferências
- **Tema manual** (claro/escuro/automático): a linha já existe em Configurações → Preferências, hoje "Em breve" — falta persistir a escolha e plugar no `ThemeMode` do `GetMaterialApp`.

## Dados
- **Importação de outros formatos** além do JSON próprio (ex.: CSV de outro app de controle financeiro) — decisão consciente de não implementar agora, por não ser um formato estruturado confiável para reconstruir relações entre entidades.
- **Mesclar em vez de substituir** na importação de backup (hoje é sempre substituição total, por simplicidade e previsibilidade).

## API / offline-first
- Introduzir uma camada de repositório remoto (`ApiXRepository`) ao lado da local, com uma estratégia offline-first (grava local imediatamente, sincroniza quando há rede) — a separação `domain`/`data` já existente é o que torna essa transição possível sem tocar em `presentation`.
