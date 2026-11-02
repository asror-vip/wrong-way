const fs = require('fs');
const path = require('path');

for (let i = 1; i <= 40; i++) {
  const pad = String(i).padStart(2, '0');
  const file = path.join('scenes', 'levels', 'level_' + pad + '.tscn');
  if (!fs.existsSync(file)) continue;
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  
  let doorX = null, doorY = null;
  let objects = [];
  let currentObj = null;

  for (let line of lines) {
    let mNode = line.match(/^\[node name="([^"]+)" parent="([^"]+)"/);
    if (!mNode) {
      mNode = line.match(/^\[node name="([^"]+)"/);
    }
    if (mNode) {
      currentObj = { name: mNode[1], parent: mNode[2] || "root" };
      objects.push(currentObj);
    }
    if (currentObj) {
      let mPos = line.match(/^position = Vector2\(([^)]+)\)/);
      if (mPos) {
        const [x, y] = mPos[1].split(',').map(s => parseFloat(s.trim()));
        currentObj.x = x;
        currentObj.y = y;
        if (currentObj.name === 'ExitDoor') {
          doorX = x;
          doorY = y;
        }
      }
      let mSize = line.match(/^platform_size = Vector2\(([^)]+)\)/);
      if (mSize) {
        const [w, h] = mSize[1].split(',').map(s => parseFloat(s.trim()));
        currentObj.w = w;
        currentObj.h = h;
      }
    }
  }

  // Find platforms covering doorX
  const platsAtDoor = objects.filter(o => o.parent === 'Platforms' && o.w && o.x <= doorX && (o.x + o.w) >= doorX);
  const trapsAtDoor = objects.filter(o => o.parent === 'Traps' && o.w && o.x <= doorX && (o.x + o.w) >= doorX);
  
  // Right wall?
  const wallRight = objects.find(o => o.name === 'WallRight');
  const wallRightX = wallRight ? wallRight.x : 'NONE';

  console.log(`Level ${i}: Door at (${doorX}, ${doorY}) | Plats: ${platsAtDoor.map(p => p.name + '[' + p.x + '..' + (p.x+p.w) + ']').join(', ')} | Traps: ${trapsAtDoor.map(t => t.name + '[' + t.x + '..' + (t.x+t.w) + ']').join(', ')} | WallRight: ${wallRightX}`);
}
