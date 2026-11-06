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
const projectFiles = allFiles.filter(f => !f.startsWith('addons/') && !f.endsWith('.uid') && !f.endsWith('.import'));

// Read all textual content across the project
const searchableFiles = projectFiles.filter(f => 
  f.endsWith('.gd') || f.endsWith('.tscn') || f.endsWith('.tres') || f.endsWith('.godot') || f.endsWith('.cfg') || f.endsWith('.json') || f.endsWith('.md')
);

const corpus = {};
searchableFiles.forEach(f => {
  corpus[f] = fs.readFileSync(f, 'utf8');
});

const fileUsage = [];

projectFiles.forEach(f => {
  const baseName = path.basename(f);
  const resPath = 'res://' + f;
  const noExt = path.basename(f, path.extname(f));

  let refCount = 0;
  const referencingFiles = [];

  for (const [sFile, content] of Object.entries(corpus)) {
    if (sFile === f) continue;
    if (content.includes(resPath) || content.includes(baseName)) {
      refCount++;
      referencingFiles.push(sFile);
    }
  }

  // Check if it is main scene
  if (f === 'scenes/main/splash_screen.tscn') {
    refCount++;
    referencingFiles.push('project.godot:main_scene');
  }

  fileUsage.push({
    file: f,
    refCount,
    referencingFiles: referencingFiles.slice(0, 5)
  });
});

const unreferenced = fileUsage.filter(u => u.refCount === 0);
console.log('Total project files checked:', projectFiles.length);
console.log('Unreferenced (zero direct string hits):', unreferenced.length);

fs.writeFileSync('audit/file_usage.json', JSON.stringify({ unreferenced, fileUsage }, null, 2));
console.log('Unreferenced files written to audit/file_usage.json');

