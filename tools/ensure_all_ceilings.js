// tools/ensure_all_ceilings.js
const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
const levels = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

levels.forEach(lvl => {
  const topTraps = lvl.traps.filter(t => t.type === 'falling_spike' || t.type === 'crusher' || t.type === 'falling_ceiling');
  if (topTraps.length === 0) return;

  topTraps.forEach(trap => {
    // Determine the ceiling y-level and bounds
    const trapX = trap.x;
    const trapW = trap.w || 32;
    const trapY = trap.y;

    // Check if covered by any existing platform at y <= 100
    const covered = lvl.platforms.some(p => p.y <= 100 && p.x <= (trapX - 10) && (p.x + p.w) >= (trapX + trapW + 10));

    if (!covered) {
      // Find if there is an adjacent or overlapping ceiling we can extend
      const nearCeiling = lvl.platforms.find(p => p.y <= 100 && Math.abs(p.x - trapX) < 260);
      if (nearCeiling) {
        const minX = Math.min(nearCeiling.x, trapX - 40);
        const maxX = Math.max(nearCeiling.x + nearCeiling.w, trapX + trapW + 40);
        nearCeiling.x = Math.max(0, minX);
        nearCeiling.w = maxX - nearCeiling.x;
        console.log(`Level ${lvl.id}: Extended ceiling '${nearCeiling.name}' to cover trap '${trap.name}' (${nearCeiling.x}..${nearCeiling.x + nearCeiling.w})`);
      } else {
        // Create a new ceiling platform
        const cX = Math.max(0, trapX - 50);
        const cW = trapW + 100;
        const cName = `Ceiling_${trap.name}`;
        lvl.platforms.push({
          name: cName,
          x: cX,
          y: 0,
          w: cW,
          h: 60
        });
        console.log(`Level ${lvl.id}: Added new ceiling '${cName}' for trap '${trap.name}' at (${cX}, 0) w=${cW}`);
      }
    }
  });
});

fs.writeFileSync(jsonPath, JSON.stringify(levels, null, 2), 'utf8');
console.log('Successfully ensured ceilings for all top traps in data/levels.json!');
