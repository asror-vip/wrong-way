// tools/apply_full_ceilings.js
// Ensures every level with ceiling traps (falling_spike, crusher) has a single, full, flat ceiling:
// { name: "Ceiling", x: 0, y: 0, w: 960, h: 60 } (or 50 for high-platform levels)
// and removes all fragmented ceiling pieces.

const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
const levels = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

const HIGH_PLAT_LEVELS = new Set([15, 20, 26, 29, 30, 31, 34, 37, 38, 40]);

let modifiedCount = 0;

for (const lvl of levels) {
  const hasCeilingTraps = lvl.traps.some(t => t.type === 'falling_spike' || t.type === 'crusher');
  const hasCeilingPlat = lvl.platforms.some(p => p.name.includes('Ceiling') || (p.y <= 10 && p.w > 50));

  if (hasCeilingTraps || hasCeilingPlat) {
    const h = HIGH_PLAT_LEVELS.has(lvl.id) ? 50 : 60;
    
    // Remove all existing ceiling platform segments
    lvl.platforms = lvl.platforms.filter(p => !p.name.includes('Ceiling') && !(p.y <= 10 && p.w > 50));
    
    // Add one single full ceiling
    lvl.platforms.push({
      name: "Ceiling",
      x: 0,
      y: 0,
      w: 960,
      h: h
    });

    console.log(`Level ${lvl.id}: Full ceiling applied (w=960, h=${h})`);
    modifiedCount++;
  }
}

fs.writeFileSync(jsonPath, JSON.stringify(levels, null, 2), 'utf8');
console.log(`Finished! Updated ${modifiedCount} levels in data/levels.json`);

