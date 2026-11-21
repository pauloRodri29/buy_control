# GastoLog

**Cada gasto, registrado.** App Flutter de planejamento e previsão de gastos: organize compras em Boxes, feche ciclos e planeje o que vem pela frente.

> ⚠️ Este é um projeto público para fins de portfólio e demonstração.
> Não está aberto para contribuições externas.

---

## 🚀 Tecnologias Utilizadas

- Flutter 3.32.7
- Dart SDK (compatível com Flutter 3.32.7)
- Material Design

---

## 📦 Versão do Flutter

Este projeto foi desenvolvido e testado utilizando:

Flutter SDK: 3.32.7

Recomenda-se utilizar exatamente esta versão para evitar problemas de compatibilidade.

Se você utiliza FVM:

```bash
fvm use 3.32.7

---

## 🎨 Identidade visual

- **Nome:** GastoLog. **Frase de apoio:** "Cada gasto, registrado."
- **Cores:** verde-petróleo `#0F766E` (principal) e âmbar `#F59E0B` (destaque). No tema escuro, a principal é `#14B8A6`.
- **Fontes** (embutidas, licença OFL): Plus Jakarta Sans no app e JetBrains Mono na splash e no símbolo.
- **Símbolo:** um terminal com `G_` (o cursor em âmbar) e duas linhas de log, a última terminando numa moeda.
- Tudo isso fica centralizado em [`lib/app/brand/`](lib/app/brand/).

### Regenerar ícone e splash

O ícone é desenhado em código (`AppLogoPainter`), o mesmo usado nas telas. Depois de alterar o desenho ou as cores:

```bash
flutter test tool/brand/render_brand_assets_test.dart   # gera os PNGs em assets/brand
dart run flutter_launcher_icons                         # ícones de todas as plataformas
dart run flutter_native_splash:create                   # splash nativa
```
