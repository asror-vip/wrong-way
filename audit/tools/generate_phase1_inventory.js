const fs = require('fs');
const path = require('path');

function walk(dir) {
  let res = [];
  if (!fs.existsSync(dir)) return res;
  for (const f of fs.readdirSync(dir)) {
    if (['.git', '.godot', 'audit', 'build'].includes(f)) continue;
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

// Group files
const scripts = allFiles.filter(f => f.endsWith('.gd'));
const scenes = allFiles.filter(f => f.endsWith('.tscn'));
const resources = allFiles.filter(f => f.endsWith('.tres') || f.endsWith('.res'));
const shaders = allFiles.filter(f => f.endsWith('.gdshader'));
const audio = allFiles.filter(f => f.endsWith('.wav') || f.endsWith('.ogg') || f.endsWith('.mp3'));
const images = allFiles.filter(f => f.endsWith('.png') || f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.svg'));
const fonts = allFiles.filter(f => f.endsWith('.otf') || f.endsWith('.ttf'));
const configs = allFiles.filter(f => f.endsWith('.cfg') || f.endsWith('.godot') || f.endsWith('.env') || f.endsWith('.editorconfig') || f.endsWith('.gitattributes') || f.endsWith('.gitignore'));

const projectScripts = scripts.filter(f => !f.startsWith('addons/'));
const addonScripts = scripts.filter(f => f.startsWith('addons/'));

const projectScenes = scenes.filter(f => !f.startsWith('addons/'));
const addonScenes = scenes.filter(f => f.startsWith('addons/'));

// Parse Autoloads from project.godot
const projectGodot = fs.readFileSync('project.godot', 'utf8');
const autoloadMatch = projectGodot.match(/\[autoload\]([\s\S]*?)(?=\n\[|$)/);
const autoloads = [];
if (autoloadMatch) {
  autoloadMatch[1].split('\n').forEach(line => {
    line = line.trim();
    if (line && line.includes('=')) {
      const [name, target] = line.split('=');
      autoloads.push({ name: name.trim(), target: target.trim().replace(/"/g, '') });
    }
  });
}

// Parse Export Presets from export_presets.cfg
const exportPresetsCfg = fs.existsSync('export_presets.cfg') ? fs.readFileSync('export_presets.cfg', 'utf8') : '';

// Analyze broken preloads and loads in project scripts
const brokenReferences = [];
const scriptInventory = [];

projectScripts.forEach(s => {
  const content = fs.readFileSync(s, 'utf8');
  const lines = content.split('\n');
  const funcs = [];
  const signals = [];
  let extendsClass = '';
  let className = '';

  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('extends ')) extendsClass = trimmed.replace('extends ', '').trim();
    if (trimmed.startsWith('class_name ')) className = trimmed.replace('class_name ', '').trim();
    if (trimmed.startsWith('signal ')) signals.push(trimmed.replace('signal ', '').split('(')[0].trim());
    if (trimmed.startsWith('func ')) {
      const match = trimmed.match(/^func\s+([a-zA-Z0-9_]+)\s*\((.*?)\)/);
      if (match) funcs.push({ name: match[1], params: match[2], line: idx + 1 });
    }

    const plRegex = /(?:preload|load)\((["'])(res:\/\/.*?)\1\)/g;
    let m;
    while ((m = plRegex.exec(line)) !== null) {
      const resPath = m[2];
      const cleanPath = resPath.replace('res://', '');
      if (!fs.existsSync(cleanPath)) {
        brokenReferences.push({ file: s, line: idx + 1, path: resPath });
      }
    }
  });

  scriptInventory.push({
    file: s,
    lines: lines.length,
    className,
    extendsClass,
    funcs,
    signals
  });
});

// Check scene references to scripts or other resources
const brokenSceneDeps = [];
projectScenes.forEach(sc => {
  const content = fs.readFileSync(sc, 'utf8');
  const lines = content.split('\n');
  lines.forEach((line, idx) => {
    if (line.startsWith('[ext_resource')) {
      const pathMatch = line.match(/path="([^"]+)"/);
      if (pathMatch && pathMatch[1].startsWith('res://')) {
        const target = pathMatch[1].replace('res://', '');
        if (!fs.existsSync(target)) {
          brokenSceneDeps.push({ scene: sc, line: idx + 1, target: pathMatch[1] });
        }
      }
    }
  });
});

const report = {
  totalFiles: allFiles.length,
  counts: {
    totalScripts: scripts.length,
    projectScripts: projectScripts.length,
    addonScripts: addonScripts.length,
    totalScenes: scenes.length,
    projectScenes: projectScenes.length,
    addonScenes: addonScenes.length,
    resources: resources.length,
    shaders: shaders.length,
    audio: audio.length,
    images: images.length,
    fonts: fonts.length,
    configs: configs.length
  },
  autoloads,
  brokenReferences,
  brokenSceneDeps,
  scriptInventory
};

fs.writeFileSync('audit/inventory_data.json', JSON.stringify(report, null, 2));
console.log('Phase 1 data collected successfully!');

