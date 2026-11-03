const fs = require('fs');

const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));

let overlaps = [];

levels.forEach(lvl => {
  const platforms = lvl.platforms || [];
  const traps = lvl.traps || [];

  traps.filter(t => t.type === 'trap_floor' || t.type === 'sinking_door_floor').forEach(t => {
    platforms.forEach(p => {
      // Check horizontal overlap if vertical is same floor level
      if (Math.abs(p.y - t.y) < 10) {
        const overlapStart = Math.max(p.x, t.x);
        const overlapEnd = Math.min(p.x + p.w, t.x + t.w);
        if (overlapEnd > overlapStart) {
          overlaps.push(`Level ${lvl.id}: Platform '${p.name}' [${p.x}..${p.x + p.w}] overlaps TrapFloor '${t.name}' [${t.x}..${t.x + t.w}] by ${overlapEnd - overlapStart}px!`);
        }
      }
    });
  });
});

console.log(`Total TrapFloor / Platform overlaps: ${overlaps.length}`);
overlaps.forEach(o => console.log(' - ' + o));

