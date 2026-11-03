const fs = require('fs');

const levels = JSON.parse(fs.readFileSync('data/levels.json', 'utf8'));

// 1. Level 6: fix GroundStart width
const l6 = levels.find(l => l.id === 6);
if (l6) {
  const gs = l6.platforms.find(p => p.name === 'GroundStart');
  if (gs) gs.w = 300; // was 340, overlapping TrapFloorStart [300..340]
}

// 2. Level 9: improve trap floor before door
const l9 = levels.find(l => l.id === 9);
if (l9) {
  const gmid = l9.platforms.find(p => p.name === 'GroundMid');
  if (gmid) gmid.w = 260; // 420..680
  const gdoor = l9.platforms.find(p => p.name === 'GroundDoor');
  if (gdoor) { gdoor.x = 860; gdoor.w = 100; } // 860..960
  const tf = l9.traps.find(t => t.name === 'TrapFloorBeforeDoor');
  if (tf) { tf.x = 760; tf.w = 100; tf.params = { shake_duration: 0.18 }; }
}

// 3. Level 12: fix GroundEnd start
const l12 = levels.find(l => l.id === 12);
if (l12) {
  const ge = l12.platforms.find(p => p.name === 'GroundEnd');
  if (ge) { ge.x = 820; ge.w = 140; } // was 760..960, overlapping TrapFloorEnd [760..820]
}

// 4. Level 13: jump distances and no overlap
const l13 = levels.find(l => l.id === 13);
if (l13) {
  const gs = l13.platforms.find(p => p.name === 'GroundStart');
  if (gs) gs.w = 270; // 0..270
  const gm1 = l13.platforms.find(p => p.name === 'GroundMid1');
  if (gm1) { gm1.x = 340; gm1.w = 170; } // 340..510
  const tf = l13.traps.find(t => t.name === 'TrapFloorEnd');
  if (tf) { tf.x = 510; tf.w = 60; } // 510..570
  const gm2 = l13.platforms.find(p => p.name === 'GroundMid2');
  if (gm2) { gm2.x = 640; gm2.w = 160; } // 640..800
  const gd = l13.platforms.find(p => p.name === 'GroundDoor');
  if (gd) { gd.x = 800; gd.w = 160; } // 800..960
  // Move Crusher1 and Stalactite slightly so player has room to jump
  const c1 = l13.traps.find(t => t.name === 'Crusher1');
  if (c1) c1.x = 140;
  const s1 = l13.traps.find(t => t.name === 'Stalactite1');
  if (s1) s1.x = 190;
  const saw = l13.traps.find(t => t.name === 'MovingSawInGap');
  if (saw) saw.x = 305;
}

// 5. Level 20: split Tier5Final to avoid overlap with TrapFloorFinal [750..820]
const l20 = levels.find(l => l.id === 20);
if (l20) {
  const idx = l20.platforms.findIndex(p => p.name === 'Tier5Final');
  if (idx !== -1) {
    l20.platforms.splice(idx, 1, 
      { name: "Tier5Approach", x: 700, y: 380, w: 50, h: 160 },
      { name: "Tier5Final", x: 820, y: 380, w: 140, h: 160 }
    );
  }
}

fs.writeFileSync('data/levels.json', JSON.stringify(levels, null, 2), 'utf8');
console.log('Successfully updated levels 6, 9, 12, 13, 20 in data/levels.json');
