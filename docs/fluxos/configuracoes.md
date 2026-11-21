# Configurações

[Fluxos](README.md) · [Visual e idioma](../configuracoes/visual-e-idioma.md) · [Armazenamento](../configuracoes/armazenamento.md)

**Entrada:** Mais → Configurações (`SettingsPage`).

| Grupo | Item | Efeito atual |
|---|---|---|
| Conta | Perfil | [Autenticação e perfil](autenticacao.md) |
| Conta | Meu plano | [Planos](planos.md) |
| Conta | Sair | confirma e encerra a sessão |
| Dados | Backup e restauração | [Backup](backup.md) |
| Dados | Limpar dados | ver abaixo |
| Preferências | Tema | sheet: Automático (segue o sistema), Claro, Escuro; aplica na hora e grava `themeMode` |
| Preferências | Idioma | sheet: Português (Brasil), English; aplica na hora e grava `locale` |
| Sobre | Sobre o sistema | o que o app faz, como os dados são guardados, versão, compilação e licenças |

Sem escolha salva, o tema segue o sistema e o idioma segue o aparelho (português se for
português, senão inglês).

## Limpar dados

`ClearDataPage` tem sete opções, cada uma com confirmação explicando o impacto
(`ClearAppData` + `ClearDataScope`):

| Opção | Apaga | Mantém |
|---|---|---|
| Boxes | Boxes, lançamentos e Fechamentos | catálogo, planejamento |
| Produtos | catálogo de produtos | o resto |
| Histórico de compras | lançamentos e Fechamentos | Boxes e catálogo |
| Planejamento | quadros e itens | o resto |
| Relatórios salvos | filtros salvos | o resto |
| Preferências | volta o tema para o automático | idioma |
| Restaurar tudo | tudo acima + catálogos padrão recriados (`SeedDefaults`) + encerra a sessão | assinatura, cupons usados, idioma, configuração do GitHub e perfis salvos |

A limpeza trabalha direto nos data sources (é manutenção de armazenamento, não regra de
negócio): apaga de fato, sem passar pelo `deletedAt`.

| Alterar | Fonte |
|---|---|
| Tela e grupos | [settings_page.dart](../../lib/features/settings/presentation/pages/settings_page.dart) |
| Limpeza | [clear_app_data.dart](../../lib/features/settings/domain/usecases/clear_app_data.dart), [clear_data_page.dart](../../lib/features/settings/presentation/pages/clear_data_page.dart) |
| Tema | [theme_controller.dart](../../lib/app/theme/theme_controller.dart), [theme_mode_sheet.dart](../../lib/features/settings/presentation/widgets/theme_mode_sheet.dart) |
| Idioma | [locale_controller.dart](../../lib/app/i18n/locale_controller.dart), [language_sheet.dart](../../lib/features/settings/presentation/widgets/language_sheet.dart) |
| Sobre e licenças | [about_page.dart](../../lib/features/settings/presentation/pages/about_page.dart), [licenses_page.dart](../../lib/features/settings/presentation/pages/licenses_page.dart) |
