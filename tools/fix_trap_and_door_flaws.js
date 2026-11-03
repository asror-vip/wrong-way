// tools/fix_trap_and_door_flaws.js
const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, '..', 'data', 'levels.json');
const levels = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

for (const lvl of levels) {
  // 1. Level 11
  if (lvl.id === 11) {
    for (const t of lvl.traps) {
      if (t.name === 'Stalactite1') t.y = 60;
      if (t.name === 'CrusherMid') t.y = 140;
      if (t.name === 'Stalactite2') t.y = 60;
    }
  }

  // 2. Level 9
  if (lvl.id === 9) {
    const tf = lvl.traps.find(t => t.name === 'TrapFloorBeforeDoor');
    if (tf) { tf.x = 740; tf.w = 90; }
    const gd = lvl.platforms.find(p => p.name === 'GroundDoor');
    if (gd) { gd.x = 830; gd.w = 130; }
    lvl.door_pos = [890, 380];
  }

  // 3. Level 23
  if (lvl.id === 23) {
    const tf = lvl.traps.find(t => t.name === 'TrapFloorFinish');
    if (tf) { tf.x = 730; tf.w = 100; }
    const ge = lvl.platforms.find(p => p.name === 'GroundEnd');
    if (ge) { ge.x = 830; ge.w = 130; }
    lvl.door_pos = [885, 380];
  }

  // 4. Level 32
  if (lvl.id === 32) {
    const gs = lvl.platforms.find(p => p.name === 'GroundStart');
    if (gs) { gs.w = 740; }
    const tf = lvl.traps.find(t => t.name === 'TrapFloorMid');
    if (tf) { tf.x = 740; tf.w = 90; }
    const ge = lvl.platforms.find(p => p.name === 'GroundEnd');
    if (ge) { ge.x = 830; ge.w = 130; }
    lvl.door_pos = [885, 380];
  }

  // 5. Level 34
  if (lvl.id === 34) {
    const gle = lvl.platforms.find(p => p.name === 'GroundLowerEnd');
    if (gle) { gle.w = 120; }
    const tf = lvl.traps.find(t => t.name === 'TrapFloor3');
    if (tf) { tf.x = 770; tf.w = 80; }
    const ge = lvl.platforms.find(p => p.name === 'GroundEnd');
    if (ge) { ge.x = 850; ge.w = 110; }
    lvl.door_pos = [890, 380];
  }

  // 6. Level 42
  if (lvl.id === 42) {
    const gs = lvl.platforms.find(p => p.name === 'GroundStart');
    if (gs) { gs.w = 760; }
    const tf = lvl.traps.find(t => t.name === 'TrapFloorFinish');
    if (tf) { tf.x = 760; tf.w = 80; }
    const ge = lvl.platforms.find(p => p.name === 'GroundEnd');
    if (ge) { ge.x = 840; ge.w = 120; }
    lvl.door_pos = [890, 380];
  }

  // 7. Level 45
  if (lvl.id === 45) {
    const ps = lvl.platforms.find(p => p.name === 'PlatformSaw');
    if (ps) { ps.w = 40; }
    const tf = lvl.traps.find(t => t.name === 'TrapFloorFinal');
    if (tf) { tf.x = 770; tf.w = 70; }
    const gd = lvl.platforms.find(p => p.name === 'GroundDoor');
    if (gd) { gd.x = 840; gd.w = 120; }
    lvl.door_pos = [890, 380];
  }

  // 8. Level 36, 39, 59, 60 door centering
  if ([36, 39, 59].includes(lvl.id)) {
    lvl.door_pos[0] = 890;
  }
  if (lvl.id === 60) {
    lvl.door_pos[0] = 890;
    const pdr = lvl.platforms.find(p => p.name === 'PlatformDoorRunway');
    if (pdr) { pdr.x = 850; pdr.w = 110; }
  }
}

fs.writeFileSync(jsonPath, JSON.stringify(levels, null, 2), 'utf8');
console.log('Fixed levels.json successfully!');
