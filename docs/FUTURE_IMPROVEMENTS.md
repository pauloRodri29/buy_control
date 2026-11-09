# Próximas melhorias

Ideias estruturais e de longo prazo, organizadas por área. Nenhuma delas exige mudar a arquitetura atual, que foi pensada para crescer nessas direções sem retrabalho.

> As funcionalidades avaliadas e priorizadas para as próximas versões (histórico de preços, previsão automática, metas por Box e categoria, lembretes, backup automático, NFC-e etc.) estão em [CANDIDATE_FEATURES.md](CANDIDATE_FEATURES.md).

## Sincronização e multiusuário
- **Sincronização em nuvem:** toda entidade persistida já tem `SyncableFields`/`SyncStatus` (`id`, `createdAt`, `updatedAt`, `deletedAt`, `syncStatus`, `version`) justamente para isso. Faltam o transporte (API ou websocket) e a resolução de conflitos.
- **Vários usuários e Box compartilhada:** hoje uma Box pertence implicitamente ao único usuário do aparelho. Compartilhar uma Box exigiria um conceito de "membros da Box" e permissões.
- **Autenticação real:** trocar o `FakeAuthRepository` por um `ApiAuthRepository` (JWT ou similar) que implemente a mesma interface `AuthRepository`. Nenhuma tela muda.

## Relatórios
- **Mais gráficos nos Relatórios:** o Dashboard já tem gráficos com `fl_chart`, e o `ConsolidatedReport` já reúne os dados. Levar os gráficos para os Relatórios é direto.
- **Backup em JSON a partir de um relatório filtrado:** o contrato (`ReportExporter`) está pronto, mas a implementação ainda devolve `NotImplementedFailure`. O mesmo vale para o CSV, ver [CANDIDATE_FEATURES.md](CANDIDATE_FEATURES.md).

## Dados
- **Importar outros formatos** além do JSON próprio (por exemplo, o CSV de outro app de controle financeiro). Foi uma decisão consciente não implementar agora: esses formatos não são estruturados o bastante para reconstruir as relações entre as entidades.
- **Mesclar em vez de substituir** na importação de backup. Hoje é sempre substituição total, por simplicidade e previsibilidade.

## API e offline-first
- Criar uma camada de repositório remoto (`ApiXRepository`) ao lado da local, com uma estratégia offline-first: grava no aparelho na hora e sincroniza quando houver rede. A separação entre `domain` e `data` é o que permite essa mudança sem tocar em `presentation`.
