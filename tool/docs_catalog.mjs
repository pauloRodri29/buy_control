import fs from 'node:fs';
import path from 'node:path';

// Referência técnica derivada do código. Não altera páginas explicativas.
// Cobre os componentes compartilhados (lib/app/widgets/) e as pastas
// presentation/widgets/ de cada feature.
const root = process.cwd();
const slash = p => p.replaceAll('\\', '/');
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e =>
    e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]);
}
const isComponent = rel => rel.startsWith('lib/app/widgets/') ||
  /^lib\/features\/[^/]+\/presentation\/widgets\//.test(rel);
const sources = walk(path.join(root, 'lib')).filter(p => p.endsWith('.dart') && !p.endsWith('.g.dart'));
const texts = new Map(sources.map(p => [p, fs.readFileSync(p, 'utf8')]));
const candidates = sources.filter(p => isComponent(slash(path.relative(root, p))));
const out = path.join(root, 'docs/componentes/catalogo');
fs.mkdirSync(out, { recursive: true });

// lib/app/widgets/ é uma pasta só: a família vem deste mapa (arquivo → família).
// Arquivo novo fora do mapa cai em "outros"; acrescente-o aqui.
const sharedFamilies = {
  app_button: 'botoes',
  app_card: 'cards', app_list_card: 'cards',
  app_text_field: 'campos', app_money_field: 'campos', app_dropdown: 'campos',
  search_field_debounced: 'campos', app_date_picker: 'campos',
  app_bottom_sheet: 'modais', confirm_dialog: 'modais', text_input_dialog: 'modais',
  app_feedback: 'feedback', empty_state_view: 'feedback', error_state_view: 'feedback',
  loading_skeleton: 'feedback',
  filter_chips_bar: 'selecao', selectable_list_tile: 'selecao',
  app_text: 'texto',
  barcode_scanner_page: 'leitura',
};
const titles = {
  botoes: 'Botões', cards: 'Cards e itens de lista', campos: 'Campos e seletores',
  modais: 'Bottom sheets e diálogos', feedback: 'Avisos, vazio, erro e carregamento',
  selecao: 'Filtros e seleção', texto: 'Textos', leitura: 'Leitura de código de barras',
  outros: 'Outros compartilhados',
  'modulo-backup': 'Módulo: Backup', 'modulo-boxes': 'Módulo: Boxes',
  'modulo-categories': 'Módulo: Categorias', 'modulo-dashboard': 'Módulo: Início (Dashboard)',
  'modulo-planning': 'Módulo: Planejamento', 'modulo-product_types': 'Módulo: Tipos de produto',
  'modulo-products': 'Módulo: Produtos', 'modulo-reports': 'Módulo: Relatórios',
  'modulo-settings': 'Módulo: Configurações', 'modulo-subscription': 'Módulo: Planos',
  'modulo-transactions': 'Módulo: Lançamentos', 'modulo-units': 'Módulo: Unidades',
};
function link(from, to) { return slash(path.relative(path.dirname(from), to)); }
function balanced(text, start) {
  let level = 0, quote = '', line = false, block = false;
  for (let i = start; i < text.length; i++) {
    const ch = text[i], next = text[i + 1];
    if (line) { if (ch === '\n') line = false; continue; }
    if (block) { if (ch === '*' && next === '/') { block = false; i++; } continue; }
    if (quote) { if (ch === '\\') i++; else if (ch === quote) quote = ''; continue; }
    if (ch === '/' && next === '/') { line = true; i++; continue; }
    if (ch === '/' && next === '*') { block = true; i++; continue; }
    if (ch === '"' || ch === "'") { quote = ch; continue; }
    if (ch === '(') level++;
    if (ch === ')' && --level === 0) return i + 1;
  }
  return start;
}
const groups = new Map();
const manifest = [];
for (const source of candidates.sort()) {
  const rel = slash(path.relative(root, source));
  const name = path.basename(source, '.dart');
  const group = rel.startsWith('lib/app/widgets/')
    ? (sharedFamilies[name] ?? 'outros')
    : 'modulo-' + rel.split('/')[2];
  if (!groups.has(group)) groups.set(group, []);
  groups.get(group).push({ source, rel, text: texts.get(source) });
}
let count = 0;
const index = ['# Catálogo completo de componentes', '', '[Voltar ao guia](../README.md) · [Buscar pelo nome da classe](busca.md)', '',
  'Referência gerada por `node tool/docs_catalog.mjs`. Inclui todos os arquivos de `lib/app/widgets/` e das pastas `presentation/widgets/` das features. Telas completas são explicadas nos [fluxos](../../fluxos/README.md).', '',
  'Abra uma família; localize o componente pelo índice. As assinaturas mostram parâmetros obrigatórios (`required`) e valores padrão. Os links de uso apontam chamadas reais; os fragmentos são referências de integração, não telas completas.', '',
  '| Família | Arquivos |', '|---|---|'];
const order = ([a], [b]) => (a.startsWith('modulo-') - b.startsWith('modulo-')) || a.localeCompare(b);
for (const [group, entries] of [...groups].sort(order)) {
  const target = path.join(out, group + '.md');
  const body = [`# ${titles[group] ?? group}`, '', '[Catálogo](README.md) · [Como usar componentes](../README.md)', ''];
  for (const { source } of entries) {
    const name = path.basename(source, '.dart');
    body.push(`- [${name}](#${name.replaceAll('_', '-')})`);
  }
  body.push('');
  for (const { source, rel, text } of entries) {
    const name = path.basename(source, '.dart');
    const classes = [...text.matchAll(/^(?:abstract\s+|final\s+|base\s+|sealed\s+)*class\s+([A-Za-z]\w*)\b/gm)].map(m => m[1]);
    const enums = [...text.matchAll(/^enum\s+(\w+)\s*\{([^}]+)\}/gm)].map(m => m[0]);
    body.push(`<a id="${name.replaceAll('_', '-')}"></a>`, '', `## ${name}`, '', `**Código:** [${rel}](${link(target, source)})`, '',
      '**Uso:** configure pelos construtores abaixo; forneça os argumentos `required` e sobrescreva os opcionais somente quando necessário.', '');
    if (!classes.length) body.push('Este arquivo não declara classe pública. Consulte a fonte para funções auxiliares.', '');
    for (const cls of classes) {
      count++;
      body.push(`### ${cls}`, '');
      const classMatch = new RegExp('^(?:(?:abstract|final|base|sealed)\\s+)*class\\s+' + cls + '\\b', 'm').exec(text);
      const declaration = classMatch.index + classMatch[0].indexOf('class');
      const prefix = text.slice(0, declaration).match(/((?:\/\/\/[^\n]*\n)+)(?:abstract\s+|final\s+|base\s+|sealed\s+)*$/);
      if (prefix) body.push(prefix[1].replace(/^\/\/\/ ?/gm, '').trim(), '');
      const ctors = [...text.matchAll(new RegExp('^\\s*(?:(?:const|factory)\\s+)?' + cls + '(?:\\.[A-Za-z]\\w*)?\\s*\\(', 'gm'))];
      const rest = text.slice(declaration + 6);
      const next = /^(?:(?:abstract|final|base|sealed)\s+)?(?:class|enum)\s+/m.exec(rest);
      const classText = text.slice(declaration, next ? declaration + 6 + next.index : text.length);
      const fields = classText.split('\n').filter(l => /^  final\s/.test(l) && !/\s_\w/.test(l));
      const methods = [...classText.matchAll(/^  static\s+[^=;\n]+?\s+([a-zA-Z]\w*)(?:<[^\n]+?>)?\s*\(/gm)];
      if (ctors.length || fields.length || methods.length) {
        body.push('<details>', '<summary>Parâmetros, padrões e variantes</summary>', '', '```dart');
        for (const ctor of ctors) {
          const start = ctor.index + ctor[0].search(/\S/);
          const open = text.indexOf('(', start);
          body.push(text.slice(start, balanced(text, open)).trim() + ';', '');
        }
        for (const method of methods) {
          const open = classText.indexOf('(', method.index);
          body.push(classText.slice(method.index, balanced(classText, open)).trim() + ';', '');
        }
        if (fields.length) body.push('// Tipos dos campos públicos declarados nesta classe.', ...fields);
        body.push('```', '', '</details>', '');
      }
      const usages = [];
      for (const [p, content] of texts) {
        if (p === source) continue;
        const re = new RegExp('\\b' + cls + '(?:\\.[A-Za-z]\\w*)?(?:<[^>\\n]+>)?\\s*\\(', 'g');
        const m = re.exec(content);
        if (m) usages.push({ p, content, m });
      }
      if (usages.length) {
        body.push('**Onde usar como referência:**');
        body.push('', ...usages.slice(0, 3).map(u => `- [${slash(path.relative(root, u.p))}](${link(target, u.p)})`), '');
        const u = usages[0], open = u.content.indexOf('(', u.m.index);
        const example = u.content.slice(u.m.index, balanced(u.content, open));
        if (example.split('\n').length <= 30) body.push('Trecho de uso existente (variáveis pertencem à tela indicada):', '', '```dart', example, '```', '');
      } else body.push('**Integração:** nenhuma chamada direta encontrada fora deste arquivo. Pode ser usado só por herança, `static` ou dentro do próprio arquivo; confira a fonte antes de adotar ou remover.', '');
    }
    const functions = [...text.matchAll(/^(?:Future<[^\n]+?>|void|bool|Widget|String|Color|double|int|List<[^\n]+?>)\s+([A-Za-z]\w*)(?:<[^\n]+?>)?\s*\(/gm)];
    for (const fn of functions) {
      const open = text.indexOf('(', fn.index);
      body.push(`### ${fn[1]}`, '', 'Função pública: use os argumentos abaixo. O retorno e as opções são parte do contrato.', '',
        '```dart', text.slice(fn.index, balanced(text, open)).trim() + ';', '```', '');
      const usage = [...texts].find(([p, content]) => p !== source &&
        new RegExp('\\b' + fn[1] + '(?:<[^>]+>)?\\s*\\(').test(content));
      if (usage) body.push(`Exemplo de integração: [${slash(path.relative(root, usage[0]))}](${link(target, usage[0])}).`, '');
    }
    if (enums.length) body.push('<details>', '<summary>Opções declaradas neste arquivo</summary>', '', '```dart', ...enums, '```', '', '</details>', '');
    manifest.push({ source: rel, catalog: slash(path.relative(root, target)), classes });
  }
  fs.writeFileSync(target, body.join('\n') + '\n');
  index.push(`| [${titles[group] ?? group}](${group}.md) | ${entries.length} |`);
}
fs.writeFileSync(path.join(out, 'README.md'), index.join('\n') + '\n');
const search = ['# Buscar componente pelo nome', '', '[Famílias](README.md) · [Guia de uso](../README.md)', '',
  'Use a busca do editor para localizar a classe. Classes privadas (`_Nome`) não aparecem: são detalhes internos do arquivo.', '',
  '| Classe | Parâmetros e uso |', '|---|---|'];
for (const { cls, entry } of manifest.flatMap(entry => entry.classes.map(cls => ({ cls, entry }))).sort((a, b) => a.cls.localeCompare(b.cls))) {
  const anchor = path.basename(entry.source, '.dart').replaceAll('_', '-');
  search.push(`| \`${cls}\` | [${path.basename(entry.source)}](${path.basename(entry.catalog)}#${anchor}) |`);
}
fs.writeFileSync(path.join(out, 'busca.md'), search.join('\n') + '\n');
fs.writeFileSync(path.join(out, 'inventario.json'), JSON.stringify(manifest, null, 2) + '\n');
// A pasta é toda gerada: família que deixou de existir vira página órfã.
const generated = new Set([...groups.keys()].map(group => group + '.md').concat('README.md', 'busca.md'));
for (const file of fs.readdirSync(out).filter(file => file.endsWith('.md') && !generated.has(file))) {
  fs.unlinkSync(path.join(out, file));
  console.log(`Removida família sem componentes: ${file}`);
}
console.log(`${candidates.length} arquivos e ${count} classes públicas catalogados em ${groups.size} famílias.`);
