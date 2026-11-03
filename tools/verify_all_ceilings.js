const fs = require('fs');

const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));

let issues = [];

levels.forEach(lvl => {
  const platforms = lvl.platforms || [];
  const traps = lvl.traps || [];
  
  // Check ceilings
  const ceilings = platforms.filter(p => p.name.toLowerCase().includes('ceiling') || (p.y <= 20 && p.h <= 100));
  ceilings.forEach(c => {
    if (c.x !== 0 || c.w !== 960) {
      issues.push(`Level ${lvl.id}: Ceiling '${c.name}' has non-standard bounds: x=${c.x}, w=${c.w}`);
    }
  });

  // Check top traps (falling_spike, crusher)
  const topTraps = traps.filter(t => t.type === 'falling_spike' || t.type === 'crusher');
  if (topTraps.length > 0 && ceilings.length === 0) {
    issues.push(`Level ${lvl.id}: Has top traps (${topTraps.map(t => t.name).join(', ')}) but NO ceiling!`);
  }
});

console.log(`Ceiling Audit Complete. Total issues found: ${issues.length}`);
issues.forEach(i => console.log(' - ' + i));

