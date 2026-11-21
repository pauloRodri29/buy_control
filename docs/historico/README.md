# Histórico da documentação

[Índice](../README.md) · [Manutenção](../manutencao.md)

Versão atual: **1.0.0** de **21/11/2026**

Cada atualização da documentação ganha uma versão e uma data. A versão atual também
aparece no topo do [índice](../README.md), e `node tool/docs_check.mjs` falha se as duas
não baterem com a primeira entrada de [Versões](#versões).

## Como versionar

Formato `MAJOR.MINOR.PATCH`. Suba **só um** número por atualização, o de maior impacto, e
zere os da direita (ex.: `1.2.3` → `1.3.0`).

| Sobe | Quando |
|---|---|
| MAJOR | Reorganização da documentação: pasta ou página movida/removida, índice reestruturado |
| MINOR | Página ou assunto novo; regra ou padrão novo ou alterado |
| PATCH | Conteúdo existente atualizado para refletir o código, correção de texto ou link, catálogo regenerado |

Ao fechar uma atualização:

1. Acrescente a entrada no **topo** de [Versões](#versões): `### <versão> — <dd/mm/aaaa>`, um
   resumo e a lista do que foi criado, alterado ou removido, com link para as páginas.
2. Atualize a **versão atual** acima e a linha de versão do [índice](../README.md).
3. Rode `node tool/docs_check.mjs`.

## Versões

### 1.0.0 — 21/11/2026

- **Novo:** documentação reorganizada no formato índice + áreas, conferida no código
  (substitui `ARCHITECTURE.md`, `FEATURES.md`, `FLOWS.md`, `MONETIZATION.md`,
  `CANDIDATE_FEATURES.md` e `FUTURE_IMPROVEMENTS.md`, apagados antes desta versão).
- **Novo:** [Fluxos](../fluxos/README.md) por módulo, incluindo [Planos](../fluxos/planos.md)
  (planos prontos, Personalizado, cupons e pagamento simulado) e [Backup](../fluxos/backup.md)
  no GitHub.
- **Novo:** [Configurações](../configuracoes/README.md): [navegação e estrutura](../configuracoes/navegacao.md),
  [armazenamento](../configuracoes/armazenamento.md), [planos e limites](../configuracoes/planos-e-limites.md),
  [rede](../configuracoes/rede.md) e [visual e idioma](../configuracoes/visual-e-idioma.md).
- **Novo:** [Componentes](../componentes/README.md) e [catálogo gerado](../componentes/catalogo/README.md)
  por `tool/docs_catalog.mjs`; verificação por `tool/docs_check.mjs`.
- **Novo:** [Padrões](../padroes/nomenclatura.md): nomenclatura, erros e resultados, testes.
