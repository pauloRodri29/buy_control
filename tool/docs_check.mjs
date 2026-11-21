import fs from 'node:fs';
import path from 'node:path';

// Confere a documentação: links locais, âncoras, cobertura do catálogo de
// componentes e se a versão bate entre o histórico e o índice.
const root = process.cwd();
const slash = p => p.replaceAll('\\', '/');
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e =>
    e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]);
}
const files = [...walk(path.join(root, 'docs')).filter(p => p.endsWith('.md')),
  ...['README.md', 'tool/README.md'].map(p => path.join(root, p))];
const errors = [];
let links = 0;
function anchors(file) {
  const text = fs.readFileSync(file, 'utf8').replace(/```[\s\S]*?```/g, '');
  return new Set([
    ...[...text.matchAll(/<a\s+id="([^"]+)"/g)].map(m => m[1]),
    ...[...text.matchAll(/^#+\s+(.+)$/gm)].map(m => m[1].trim().toLowerCase()
      .replace(/[`*]/g, '').replace(/[^\p{L}\p{N}_\-\s]/gu, '').replace(/\s/g, '-')),
  ]);
}
for (const file of files) {
  const text = fs.readFileSync(file, 'utf8').replace(/```[\s\S]*?```/g, '');
  for (const match of text.matchAll(/\[[^\]\n]*\]\(([^)\n]+)\)/g)) {
    const href = match[1];
    if (/^(https?:|mailto:)/.test(href)) continue;
    links++;
    const [relative, hash] = href.split('#');
    const target = relative ? path.resolve(path.dirname(file), decodeURI(relative)) : file;
    if (!fs.existsSync(target)) errors.push(`${slash(path.relative(root, file))}: destino ausente ${href}`);
    else if (hash && target.endsWith('.md') && !anchors(target).has(decodeURI(hash)))
      errors.push(`${slash(path.relative(root, file))}: âncora ausente ${href}`);
  }
}
const inventory = JSON.parse(fs.readFileSync(path.join(root, 'docs/componentes/catalogo/inventario.json'), 'utf8'));
const sources = walk(path.join(root, 'lib')).map(p => slash(path.relative(root, p)))
  .filter(p => p.endsWith('.dart') && !p.endsWith('.g.dart') &&
    (p.startsWith('lib/app/widgets/') || /^lib\/features\/[^/]+\/presentation\/widgets\//.test(p)));
const indexed = new Set(inventory.map(e => e.source));
for (const source of sources) if (!indexed.has(source)) errors.push(`Componente não catalogado: ${source} (rode node tool/docs_catalog.mjs)`);
for (const entry of inventory) {
  if (!sources.includes(entry.source)) errors.push(`Entrada obsoleta: ${entry.source} (rode node tool/docs_catalog.mjs)`);
  if (!fs.existsSync(path.join(root, entry.catalog))) errors.push(`Catálogo ausente: ${entry.catalog}`);
}
// Versão da documentação: histórico (versão atual + 1ª entrada) e índice precisam bater.
const history = fs.readFileSync(path.join(root, 'docs/historico/README.md'), 'utf8');
const current = history.match(/Versão atual: \*\*(\d+\.\d+\.\d+)\*\* de \*\*(\d{2}\/\d{2}\/\d{4})\*\*/);
const entries = [...history.matchAll(/^### (\d+\.\d+\.\d+) — (\d{2}\/\d{2}\/\d{4})\r?$/gm)];
const index = fs.readFileSync(path.join(root, 'docs/README.md'), 'utf8')
  .match(/Versão \*\*(\d+\.\d+\.\d+)\*\* de \*\*(\d{2}\/\d{2}\/\d{4})\*\*/);
const semver = v => v.split('.').map(Number);
const newer = (a, b) => { const [x, y] = [semver(a), semver(b)]; return x[0] - y[0] || x[1] - y[1] || x[2] - y[2]; };
let version = '?';
if (!current) errors.push('docs/historico/README.md: linha "Versão atual: **x.y.z** de **dd/mm/aaaa**" ausente');
else if (!entries.length) errors.push('docs/historico/README.md: nenhuma entrada "### x.y.z — dd/mm/aaaa"');
else {
  version = current[1];
  const [, topVersion, topDate] = entries[0];
  if (current[1] !== topVersion || current[2] !== topDate)
    errors.push(`docs/historico/README.md: versão atual ${current[1]} (${current[2]}) ≠ 1ª entrada ${topVersion} (${topDate})`);
  if (!index) errors.push('docs/README.md: linha "Versão **x.y.z** de **dd/mm/aaaa**" ausente');
  else if (index[1] !== current[1] || index[2] !== current[2])
    errors.push(`docs/README.md: versão ${index[1]} (${index[2]}) ≠ histórico ${current[1]} (${current[2]})`);
  for (let i = 1; i < entries.length; i++)
    if (newer(entries[i - 1][1], entries[i][1]) <= 0)
      errors.push(`docs/historico/README.md: versões fora de ordem (${entries[i - 1][1]} antes de ${entries[i][1]})`);
}
if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
else console.log(`Documentação v${version}: ${files.length} páginas, ${links} links locais e ${sources.length} arquivos de componentes verificados.`);
