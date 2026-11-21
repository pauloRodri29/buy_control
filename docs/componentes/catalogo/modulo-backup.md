# Módulo: Backup

[Catálogo](README.md) · [Como usar componentes](../README.md)

- [backup_busy_overlay](#backup-busy-overlay)

<a id="backup-busy-overlay"></a>

## backup_busy_overlay

**Código:** [lib/features/backup/presentation/widgets/backup_busy_overlay.dart](../../../lib/features/backup/presentation/widgets/backup_busy_overlay.dart)

**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.

### BackupBusyOverlay

Cobre a tela com um aviso de progresso enquanto o [BackupController]
está ocupado (baixando, comparando, enviando…), bloqueando toques.

<details>
<summary>Parâmetros, padrões e variantes</summary>

```dart
const BackupBusyOverlay({super.key, required this.child});

// Tipos dos campos públicos declarados nesta classe.
  final Widget child;
```

</details>

**Onde usar como referência:**

- [lib/features/backup/presentation/pages/backup_history_page.dart](../../../lib/features/backup/presentation/pages/backup_history_page.dart)
- [lib/features/backup/presentation/pages/backup_page.dart](../../../lib/features/backup/presentation/pages/backup_page.dart)

Trecho de uso existente (variáveis pertencem à tela indicada):

```dart
BackupBusyOverlay(child: _body(context))
```

