# Produtos e catálogos

[Fluxos](README.md) · [Leitura de código](leitura-de-codigo.md) · [Planos e limites](../configuracoes/planos-e-limites.md)

Catálogo reutilizável entre Boxes. Categorias, tipos de produto e unidades são entidades
com CRUD próprio, não enums fixos.

| Catálogo | Entrada | Campos principais |
|---|---|---|
| Produtos | aba Produtos | nome, código interno, códigos de barras, marca, categoria, tipo, unidade padrão, preço de referência, ativo |
| Categorias | Mais → Categorias | nome |
| Tipos de produto | Mais → Tipos de Produto | nome |
| Unidades | Mais → Unidades | nome, abreviação |

1. Lista com busca; criar/editar por bottom sheet (`*FormSheet`); excluir (lógico).
2. Produtos: busca por texto (`SearchProducts`) e filtro por categoria; o preço de
   referência pré-preenche o preço no lançamento.
3. Itens acima do limite do plano ficam com cadeado e não abrem nem aparecem nos seletores.

## Catálogos padrão

`SeedDefaults` cria categorias, tipos e unidades padrão **uma vez**, na primeira execução,
no idioma em uso (flag `defaultsSeeded` no `app_meta`). Depois disso são dados do usuário
e não mudam com o idioma. `DefaultCatalogs` reconhece os nomes padrão em todos os idiomas
(unidades pela abreviação): esses itens **não contam** na cota do plano e nunca ficam
bloqueados. Renomear um item padrão faz ele passar a contar.

"Limpar dados → Restaurar tudo" apaga os catálogos e roda o seed de novo.

| Alterar | Fonte |
|---|---|
| Lista e nomes padrão | [default_catalogs.dart](../../lib/core/catalog/default_catalogs.dart), chaves `catalog.*` em [pt_BR.json](../../assets/i18n/pt_BR.json) |
| Seed | [seed_defaults.dart](../../lib/app/bootstrap/seed_defaults.dart) |
| Produtos | [features/products](../../lib/features/products/) |
| Categorias, tipos, unidades | [categories](../../lib/features/categories/), [product_types](../../lib/features/product_types/), [units](../../lib/features/units/) |
| Formulários | [catálogo de componentes](../componentes/catalogo/README.md) (famílias `Módulo:`) |
