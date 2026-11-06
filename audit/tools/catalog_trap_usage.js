const fs = require('fs');

const trapTypeCounts = {};
const levelTrapCatalog = {};

for (let lvl = 1; lvl <= 60; lvl++) {
    const num = lvl < 10 ? '0' + lvl : '' + lvl;
    const file = `scenes/levels/level_${num}.tscn`;
    if (!fs.existsSync(file)) continue;
    
    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');
    
    // Find ExtResource mapping for traps
    const extResources = {};
    lines.forEach(line => {
        const m = line.match(/\[ext_resource type="PackedScene" path="res:\/\/scenes\/traps\/([a-zA-Z0-9_]+)\.tscn" id="([^"]+)"\]/);
        if (m) {
            extResources[m[2]] = m[1];
        }
    });
    
    const trapsInLevel = [];
    lines.forEach(line => {
        const nodeMatch = line.match(/\[node name="([^"]+)" parent="Traps" instance=ExtResource\("([^"]+)"\)\]/);
        if (nodeMatch) {
            const trapType = extResources[nodeMatch[2]] || 'unknown';
            trapsInLevel.push(trapType);
            trapTypeCounts[trapType] = (trapTypeCounts[trapType] || 0) + 1;
        }
    });
    
    levelTrapCatalog[lvl] = {
        total: trapsInLevel.length,
        types: trapsInLevel
    };
}

console.log('Trap Type Distribution Across All 60 Levels:');
console.table(trapTypeCounts);

fs.writeFileSync('audit/trap_usage_distribution.json', JSON.stringify({
    trap_type_totals: trapTypeCounts,
    level_breakdown: levelTrapCatalog
}, null, 2));
console.log('Saved to audit/trap_usage_distribution.json');

