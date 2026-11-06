const fs = require('fs');

const data = JSON.parse(fs.readFileSync('audit/levels_runtime_verification.json', 'utf8'));
console.log('Total levels verified:', data.total_levels);

let minTraps = 999, maxTraps = 0;
let minTrapsLvl = 0, maxTrapsLvl = 0;
let ySpawnRange = { min: 9999, max: -9999 };
let yExitRange = { min: 9999, max: -9999 };

data.levels.forEach(l => {
    if (l.trap_count < minTraps) { minTraps = l.trap_count; minTrapsLvl = l.level; }
    if (l.trap_count > maxTraps) { maxTraps = l.trap_count; maxTrapsLvl = l.level; }
    
    // Parse vectors
    const playerMatch = l.player_pos.match(/\(([0-9.-]+),\s*([0-9.-]+)\)/);
    const exitMatch = l.exit_pos.match(/\(([0-9.-]+),\s*([0-9.-]+)\)/);
    if (playerMatch) {
        const py = parseFloat(playerMatch[2]);
        if (py < ySpawnRange.min) ySpawnRange.min = py;
        if (py > ySpawnRange.max) ySpawnRange.max = py;
    }
    if (exitMatch) {
        const ey = parseFloat(exitMatch[2]);
        if (ey < yExitRange.min) yExitRange.min = ey;
        if (ey > yExitRange.max) yExitRange.max = ey;
    }
});

console.log('Min traps:', minTraps, 'in level', minTrapsLvl);
console.log('Max traps:', maxTraps, 'in level', maxTrapsLvl);
console.log('Player spawn Y range:', ySpawnRange);
console.log('Exit door Y range:', yExitRange);

// Check if any level has player spawn Y > 540 or exit Y > 540 (viewport height is 540)
const suspicious = [];
data.levels.forEach(l => {
    const playerMatch = l.player_pos.match(/\(([0-9.-]+),\s*([0-9.-]+)\)/);
    const exitMatch = l.exit_pos.match(/\(([0-9.-]+),\s*([0-9.-]+)\)/);
    const px = playerMatch ? parseFloat(playerMatch[1]) : 0;
    const py = playerMatch ? parseFloat(playerMatch[2]) : 0;
    const ex = exitMatch ? parseFloat(exitMatch[1]) : 0;
    const ey = exitMatch ? parseFloat(exitMatch[2]) : 0;
    
    // Default base floor is y=420 or y=380. Viewport is 960x540.
    if (py > 500 || py < 50 || ey > 500 || ey < 50) {
        suspicious.push({ level: l.level, px, py, ex, ey, reason: 'Y pos out of typical screen bounds' });
    }
    // Check if exit door is behind player (wrong way mechanic)
    if (ex < px) {
        suspicious.push({ level: l.level, px, py, ex, ey, reason: 'Exit door is behind player (reversed)' });
    }
});

console.log('Suspicious or unique levels:', JSON.stringify(suspicious, null, 2));

