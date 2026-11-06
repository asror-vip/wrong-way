const fs = require('fs');
const path = require('path');

// Player physics constants from scripts/player/player_controller.gd
const MOVE_SPEED = 200.0;
const JUMP_VELOCITY = 420.0;
const GRAVITY = 980.0;
const DASH_SPEED = 600.0;
const DASH_DURATION = 0.15;

const MAX_JUMP_HEIGHT = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * GRAVITY); // ~90.0 px
const AIR_TIME = (2.0 * JUMP_VELOCITY) / GRAVITY; // ~0.857s
const MAX_HORIZONTAL_JUMP = MOVE_SPEED * AIR_TIME; // ~171.4 px
const DASH_DISTANCE = DASH_SPEED * DASH_DURATION; // 90.0 px
const MAX_JUMP_WITH_DASH = MAX_HORIZONTAL_JUMP + DASH_DISTANCE; // ~261.4 px

function parseLevelTscn(lvlNum) {
  const pad = String(lvlNum).padStart(2, '0');
  const filePath = `scenes/levels/level_${pad}.tscn`;
  if (!fs.existsSync(filePath)) {
    return { error: `File not found: ${filePath}` };
  }

  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  let playerPos = null;
  let doorPos = null;
  const platforms = [];
  const traps = [];
  const nodes = [];

  // Parse nodes
  let currentNode = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('[node name="')) {
      if (currentNode) nodes.push(currentNode);
      const match = line.match(/\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?/);
      currentNode = {
        name: match ? match[1] : 'Unknown',
        type: match ? match[2] : '',
        parent: match ? match[3] : null,
        props: {}
      };
    } else if (currentNode && line.includes('=')) {
      const eqIdx = line.indexOf('=');
      const k = line.substring(0, eqIdx).trim();
      const v = line.substring(eqIdx + 1).trim();
      currentNode.props[k] = v;
    }
  }
  if (currentNode) nodes.push(currentNode);

  // Extract Player, Door, Platforms, Traps
  nodes.forEach(n => {
    const posMatch = n.props.position ? n.props.position.match(/Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)/) : null;
    const pos = posMatch ? { x: parseFloat(posMatch[1]), y: parseFloat(posMatch[2]) } : { x: 0, y: 0 };

    if (n.name === 'Player') {
      playerPos = pos;
    } else if (n.name === 'ExitDoor') {
      doorPos = pos;
    } else if (n.parent === 'Platforms' || n.name.includes('Ground') || n.name.includes('Platform') || n.name.includes('Wall') || n.name.includes('Ledge')) {
      const sizeMatch = n.props.platform_size ? n.props.platform_size.match(/Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)/) : null;
      const sz = sizeMatch ? { w: parseFloat(sizeMatch[1]), h: parseFloat(sizeMatch[2]) } : { w: 32, h: 32 };
      platforms.push({ name: n.name, type: n.type || 'Platform', pos, size: sz });
    } else if (n.parent === 'Traps' || n.name.includes('Spike') || n.name.includes('Saw') || n.name.includes('Laser') || n.name.includes('Boulder') || n.name.includes('Crusher') || n.name.includes('TrapFloor') || n.name.includes('Spring')) {
      traps.push({ name: n.name, type: n.type || 'Trap', pos, props: n.props });
    }
  });

  // Calculate jump gaps & reachability
  // Sort platforms horizontally (excluding vertical boundary walls)
  const walkingPlatforms = platforms.filter(p => !p.name.startsWith('Wall') && !p.name.includes('Ceiling')).sort((a, b) => a.pos.x - b.pos.x);

  const jumpGaps = [];
  let maxGapFound = 0;
  let impossibleJumpFound = false;

  for (let j = 0; j < walkingPlatforms.length - 1; j++) {
    const cur = walkingPlatforms[j];
    const nxt = walkingPlatforms[j + 1];
    const curRight = cur.pos.x + cur.size.w;
    const nxtLeft = nxt.pos.x;
    const gapX = Math.max(0, nxtLeft - curRight);
    const gapY = cur.pos.y - nxt.pos.y; // positive means jumping up

    jumpGaps.push({ from: cur.name, to: nxt.name, gapX, gapY });
    if (gapX > maxGapFound) maxGapFound = gapX;

    // Check if jump requires spring or exceeds max horizontal/vertical
    const hasSpringNearby = traps.some(t => t.name.toLowerCase().includes('spring') && Math.abs(t.pos.x - curRight) < 120);
    if (!hasSpringNearby) {
      if (gapX > MAX_JUMP_WITH_DASH || gapY > MAX_JUMP_HEIGHT) {
        impossibleJumpFound = true;
      }
    }
  }

  return {
    lvlNum,
    pad,
    filePath,
    nodeCount: nodes.length,
    playerPos: playerPos || { x: 80, y: 380 },
    doorPos: doorPos || { x: 860, y: 380 },
    platformsCount: platforms.length,
    platforms,
    trapsCount: traps.length,
    traps,
    jumpGaps,
    maxGapFound,
    impossibleJumpFound,
    verdict: impossibleJumpFound ? 'FAIL' : (traps.length > 0 ? 'PASS' : 'NEEDS RUNTIME TEST')
  };
}

const allLevelsData = [];
for (let lvl = 1; lvl <= 60; lvl++) {
  allLevelsData.push(parseLevelTscn(lvl));
}

console.log('Parsed levels count:', allLevelsData.length);
const verdicts = {};
allLevelsData.forEach(l => {
  verdicts[l.verdict] = (verdicts[l.verdict] || 0) + 1;
});
console.log('Verdicts summary:', verdicts);

fs.writeFileSync('audit/levels_audit_data.json', JSON.stringify(allLevelsData, null, 2));
console.log('Levels audit data written to audit/levels_audit_data.json');

