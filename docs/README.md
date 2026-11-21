# Documentação do GastoLog

Versão **1.0.0** de **21/11/2026** · [Histórico de versões](historico/README.md)

Guias do GastoLog (pacote `buy_control`) conferidos no código. Cada página explica
um assunto e aponta os arquivos responsáveis por ele, descrevendo o comportamento
atual e separando o que é real, simulado (login fake, pagamento de teste) ou ainda
não implementado.

O app é **offline-first**: todos os dados ficam no aparelho (Hive). A única
comunicação com a internet é o backup opcional no GitHub.

## Como está organizada

| Pasta | Conteúdo |
|---|---|
| [fluxos/](fluxos/README.md) | Caminho do usuário em cada módulo e estado atual das features |
| [configuracoes/](configuracoes/README.md) | Inicialização, estrutura e DI, armazenamento, planos e limites, rede, visual e idioma |
| [componentes/](componentes/README.md) | Como montar telas e catálogo gerado de componentes |
| [padroes/](padroes/nomenclatura.md) | Convenções de código: [nomenclatura](padroes/nomenclatura.md), [erros e resultados](padroes/erros-e-resultados.md) e [testes](padroes/testes.md) |
| [historico/](historico/README.md) | Versões da documentação e o que mudou em cada uma |

## Por onde começar

| Quero entender ou alterar | Começar por |
|---|---|
| Caminho do usuário e o que cada tela faz | [Fluxos](fluxos/README.md) |
| Box, lançamento, fechamento de ciclo | [Boxes e lançamentos](fluxos/boxes-e-lancamentos.md), [Fechamento](fluxos/fechamento.md) |
| Inicialização, estrutura de pastas, navegação e DI | [Navegação e estrutura](configuracoes/navegacao.md) |
| Hive boxes, chaves e o que sobrevive ao reinício | [Armazenamento](configuracoes/armazenamento.md) |
| O que cada plano libera, limites e itens bloqueados | [Planos e limites](configuracoes/planos-e-limites.md) |
| Backup em arquivo ou no GitHub | [Backup](fluxos/backup.md), [Rede](configuracoes/rede.md) |
| Tema, cores, fonte, ícones e idioma | [Visual e idioma](configuracoes/visual-e-idioma.md) |
| Como montar uma tela | [Componentes](componentes/README.md) |
| Todos os componentes e parâmetros | [Catálogo](componentes/catalogo/README.md) |
| Como nomear classes, arquivos e pastas | [Nomenclatura](padroes/nomenclatura.md) |
| `Result`, falhas, `Money`, estados de tela | [Erros e resultados](padroes/erros-e-resultados.md) |

## Referências

- [Histórico de versões](historico/README.md): versão atual, regra de versionamento e mudanças.
- [Manutenção](manutencao.md): como atualizar estes documentos e qual página é dona de cada assunto.
- [Ferramentas](../tool/README.md): scripts que geram o catálogo, verificam a documentação e geram os assets da marca.
- [README do projeto](../README.md): identidade visual e como rodar.
