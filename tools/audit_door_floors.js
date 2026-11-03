const fs = require('fs');

const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));

levels.forEach(lvl => {
  const doorX = lvl.door_pos[0];
  const doorY = lvl.door_pos[1];
  const platforms = lvl.platforms || [];
  const traps = lvl.traps || [];

  // Check platform directly under door
  const underDoor = platforms.filter(p => p.y >= 350 && doorX >= p.x && doorX <= (p.x + p.w));
  
  // Check if any trap floor is right under door
  const trapUnderDoor = traps.filter(t => (t.type === 'trap_floor' || t.type === 'sinking_door_floor') && doorX >= t.x && doorX <= (t.x + t.w));

  // Check traps near door
  const trapsNearDoor = traps.filter(t => (t.type === 'trap_floor' || t.type === 'sinking_door_floor') && Math.abs(t.x - doorX) < 180);

  // Check right wall
  const rightWall = platforms.find(p => p.name.includes('WallRight') || p.x >= 900);

  console.log(`Level ${lvl.id}: Door at (${doorX}, ${doorY}) | Platform under door: ${underDoor.map(p => `${p.name} [${p.x}..${p.x+p.w}]`).join(', ') || 'NONE!'} | Trap under door: ${trapUnderDoor.map(t => `${t.name} [${t.x}..${t.x+t.w}]`).join(', ') || 'NONE'} | Trap before door: ${trapsNearDoor.map(t => `${t.name} [${t.x}..${t.x+t.w}]`).join(', ') || 'NONE'}`);
});

