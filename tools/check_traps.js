const fs = require('fs');
const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));
levels.forEach(lvl => {
  const traps = (lvl.traps || []).filter(t => t.type === 'trap_floor' || t.type === 'sinking_door_floor');
  if (traps.length > 0) {
    console.log(`Level ${lvl.id} (${lvl.title}): door_pos=${JSON.stringify(lvl.door_pos)}, traps:`, traps.map(t => `${t.name} (x=${t.x}, w=${t.w})`));
  }
});

