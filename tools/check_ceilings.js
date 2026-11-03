const fs = require('fs');
const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));

levels.forEach(lvl => {
  const topTraps = lvl.traps.filter(t => t.type === 'falling_spike' || t.type === 'crusher');
  if (topTraps.length === 0) return;
  
  const ceilings = lvl.platforms.filter(p => p.y <= 100);
  
  topTraps.forEach(trap => {
    // Check if any ceiling covers this trap's x position
    const covered = ceilings.some(c => c.x <= trap.x && (c.x + c.w) >= trap.x);
    if (!covered) {
      console.log(`Level ${lvl.id} (${lvl.title}): Trap '${trap.name}' (${trap.type}) at (${trap.x}, ${trap.y}) HAS NO CEILING ABOVE IT!`);
    }
  });
});

