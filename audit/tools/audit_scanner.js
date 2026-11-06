const fs = require('fs');
const path = require('path');

function walk(dir) {
  let res = [];
  if (!fs.existsSync(dir)) return res;
  for (const f of fs.readdirSync(dir)) {
    if (['.git', '.godot', 'audit', 'build', '.import'].includes(f)) continue;
    const p = dir === '.' ? f : dir + '/' + f;
    if (fs.statSync(p).isDirectory()) {
      res = res.concat(walk(p));
    } else {
      res.push(p.replace(/\\/g, '/'));
    }
  }
  return res;
}

const allFiles = walk('.');
const scripts = allFiles.filter(f => f.endsWith('.gd') && !f.startsWith('addons/'));
const scenes = allFiles.filter(f => f.endsWith('.tscn') && !f.startsWith('addons/'));

console.log('Project scripts (non-addons):', scripts.length);
console.log('Project scenes (non-addons):', scenes.length);

const scriptData = [];
const allExtractedFuncs = [];

for (const s of scripts) {
  const content = fs.readFileSync(s, 'utf8');
  const lines = content.split('\n');
  const funcs = [];
  const signals = [];
  const preloads = [];
  const loads = [];
  let extendsClass = '';
  let className = '';

  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('extends ')) extendsClass = trimmed.replace('extends ', '').trim();
    if (trimmed.startsWith('class_name ')) className = trimmed.replace('class_name ', '').trim();
    if (trimmed.startsWith('signal ')) signals.push(trimmed.replace('signal ', '').split('(')[0].trim());
    if (trimmed.startsWith('func ')) {
      const match = trimmed.match(/^func\s+([a-zA-Z0-9_]+)\s*\((.*?)\)/);
      if (match) {
        funcs.push({ name: match[1], params: match[2], line: idx + 1 });
        allExtractedFuncs.push({ file: s, func: match[1], params: match[2], line: idx + 1 });
      }
    }
    const plRegex = /preload\((["'])(.*?)\1\)/g;
    let plm;
    while ((plm = plRegex.exec(line)) !== null) {
      preloads.push(plm[2]);
    }
    const lRegex = /load\((["'])(.*?)\1\)/g;
    let lm;
    while ((lm = lRegex.exec(line)) !== null) {
      loads.push(lm[2]);
    }
  });

  scriptData.push({
    file: s,
    lines: lines.length,
    className,
    extendsClass,
    funcsCount: funcs.length,
    funcs,
    signals,
    preloads,
    loads
  });
}

console.log('Total functions extracted:', allExtractedFuncs.length);

// Check broken preloads and loads
const brokenReferences = [];
for (const s of scriptData) {
  for (const pl of s.preloads) {
    if (pl.startsWith('res://')) {
      const clean = pl.replace('res://', '');
      if (!fs.existsSync(clean)) {
        brokenReferences.push({ type: 'preload', file: s.file, target: pl });
      }
    }
  }
  for (const ld of s.loads) {
    if (ld.startsWith('res://')) {
      const clean = ld.replace('res://', '');
      if (!fs.existsSync(clean)) {
        brokenReferences.push({ type: 'load', file: s.file, target: ld });
      }
    }
  }
}
console.log('Broken script resource references:', brokenReferences);

// Check scenes for missing script references or broken ext_resource
const brokenSceneExtResources = [];
for (const sc of scenes) {
  const content = fs.readFileSync(sc, 'utf8');
  const lines = content.split('\n');
  lines.forEach((line, idx) => {
    if (line.startsWith('[ext_resource')) {
      const pathMatch = line.match(/path="([^"]+)"/);
      if (pathMatch) {
        const target = pathMatch[1];
        if (target.startsWith('res://')) {
          const clean = target.replace('res://', '');
          if (!fs.existsSync(clean)) {
            brokenSceneExtResources.push({ scene: sc, line: idx + 1, target });
          }
        }
      }
    }
  });
}
console.log('Broken scene ext_resources:', brokenSceneExtResources);

fs.writeFileSync('audit/scripts_inventory.json', JSON.stringify(scriptData, null, 2));
fs.writeFileSync('audit/all_functions.json', JSON.stringify(allExtractedFuncs, null, 2));
fs.writeFileSync('audit/broken_references.json', JSON.stringify({ brokenReferences, brokenSceneExtResources }, null, 2));
console.log('Inventory data written to audit/*.json successfully.');

