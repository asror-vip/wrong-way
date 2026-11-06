const fs = require('fs');
const path = require('path');

function walk(dir) {
  let res = [];
  if (!fs.existsSync(dir)) return res;
  for (const f of fs.readdirSync(dir)) {
    if (['.git', '.godot', 'audit', 'build', '.import'].includes(f)) continue;
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
const searchable = all.filter(f => f.endsWith('.gd') || f.endsWith('.tscn') || f.endsWith('.tres') || f.endsWith('.godot') || f.endsWith('.cfg') || f.endsWith('.json'));

const targetScripts = [
  { path: 'scripts/ui/home_menu.gd', name: 'home_menu' },
  { path: 'scripts/ui/title_screen.gd', name: 'title_screen' },
  { path: 'scripts/ui/main_menu_controller.gd', name: 'main_menu_controller' },
  { path: 'scripts/core/game_app.gd', name: 'game_app' },
  { path: 'scripts/systems/level_system.gd', name: 'level_system' },
  { path: 'scripts/traps/trap_base.gd', name: 'trap_base', className: 'TrapBase' },
  { path: 'scripts/traps/crusher_visuals.gd', name: 'crusher_visuals', className: 'CrusherVisuals' },
  { path: 'scripts/ui/cloud_layer.gd', name: 'cloud_layer', className: 'CloudLayer' }
];

const results = {};

targetScripts.forEach(target => {
  const matches = [];
  searchable.forEach(f => {
    if (f === target.path) return; // skip self
    const content = fs.readFileSync(f, 'utf8');
    const base = path.basename(target.path);
    const hasPath = content.includes(target.path);
    const hasBase = content.includes(base);
    const hasClass = target.className ? content.includes(target.className) : false;

    if (hasPath || hasBase || hasClass) {
      matches.push({ file: f, hasPath, hasBase, hasClass });
    }
  });
  results[target.path] = matches;
});

console.log('--- DEAD CODE VALIDATION RESULTS ---');
for (const [s, m] of Object.entries(results)) {
  console.log(`\nScript: ${s}`);
  if (m.length === 0) {
    console.log('  -> CONFIRMED ZERO REFERENCES anywhere in project.');
  } else {
    console.log(`  -> Found ${m.length} references:`, m);
  }
}

fs.writeFileSync('audit/dead_scripts_validation.json', JSON.stringify(results, null, 2));

