const fs = require('fs');
const path = require('path');

function walk(dir) {
  let res = [];
  if (!fs.existsSync(dir)) return res;
  for (const f of fs.readdirSync(dir)) {
    if (['.git', '.godot', 'audit', 'build'].includes(f)) continue;
    const p = dir === '.' ? f : dir + '/' + f;
    const stat = fs.statSync(p);
    if (stat.isDirectory()) {
      res = res.concat(walk(p));
    } else {
      res.push(p.replace(/\\/g, '/'));
    }
  }
  return res;
}

const all = walk('.');

const projectFiles = all.filter(f => !f.startsWith('addons/'));
const addonFiles = all.filter(f => f.startsWith('addons/'));

const projExts = {};
projectFiles.forEach(f => {
  const ext = path.extname(f).toLowerCase() || '(no-ext)';
  projExts[ext] = (projExts[ext] || 0) + 1;
});

const addonExts = {};
addonFiles.forEach(f => {
  const ext = path.extname(f).toLowerCase() || '(no-ext)';
  addonExts[ext] = (addonExts[ext] || 0) + 1;
});

// Count GDScript files and functions
function countFuncs(fileList) {
  let totalFuncs = 0;
  const fileFuncMap = {};
  fileList.forEach(f => {
    if (!f.endsWith('.gd')) return;
    const content = fs.readFileSync(f, 'utf8');
    const lines = content.split('\n');
    let funcs = 0;
    lines.forEach(line => {
      if (line.trim().match(/^func\s+[a-zA-Z0-9_]+\s*\(/)) {
        funcs++;
      }
    });
    fileFuncMap[f] = funcs;
    totalFuncs += funcs;
  });
  return { totalFuncs, fileFuncMap };
}

const projScripts = projectFiles.filter(f => f.endsWith('.gd'));
const addonScripts = addonFiles.filter(f => f.endsWith('.gd'));

const projFuncData = countFuncs(projScripts);
const addonFuncData = countFuncs(addonScripts);

// Count test cases in audit/TEST_CASES.csv
let csvRows = 0;
if (fs.existsSync('audit/TEST_CASES.csv')) {
  const csvContent = fs.readFileSync('audit/TEST_CASES.csv', 'utf8').trim().split('\n');
  csvRows = csvContent.length - 1; // subtract header
}

console.log('--- RECONCILIATION REPORT ---');
console.log('Total non-ignored workspace files:', all.length);
console.log('Project core files:', projectFiles.length);
console.log('Addon (external plugin) files:', addonFiles.length);
console.log('\nProject files by extension:', projExts);
console.log('\nAddon files by extension:', addonExts);
console.log('\nProject GDScripts (.gd):', projScripts.length);
console.log('Project functions count:', projFuncData.totalFuncs);
console.log('\nAddon GDScripts (.gd):', addonScripts.length);
console.log('Addon functions count:', addonFuncData.totalFuncs);
console.log('Combined scripts (81 + 157):', projScripts.length + addonScripts.length);
console.log('Combined functions:', projFuncData.totalFuncs + addonFuncData.totalFuncs);
console.log('\nTest cases in audit/TEST_CASES.csv:', csvRows);

fs.writeFileSync('audit/stats_reconciliation.json', JSON.stringify({
  totalFiles: all.length,
  projectFilesCount: projectFiles.length,
  addonFilesCount: addonFiles.length,
  projExts,
  addonExts,
  projectScriptsCount: projScripts.length,
  projectFunctionsCount: projFuncData.totalFuncs,
  addonScriptsCount: addonScripts.length,
  addonFunctionsCount: addonFuncData.totalFuncs,
  csvRows
}, null, 2));

