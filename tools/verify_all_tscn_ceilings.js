const fs = require('fs');

let issues = [];

for (let i = 1; i <= 60; i++) {
  const numStr = String(i).padStart(2, '0');
  const tscnPath = `scenes/levels/level_${numStr}.tscn`;
  if (!fs.existsSync(tscnPath)) {
    issues.push(`Missing tscn: ${tscnPath}`);
    continue;
  }
  const content = fs.readFileSync(tscnPath, 'utf8');
  
  // Check if there is a Ceiling node
  if (content.includes('[node name="Ceiling"')) {
    // Check if position is Vector2(0, 0) and platform_size is Vector2(960, ...)
    const ceilingMatch = content.match(/\[node name="Ceiling"[^\]]*\]\s*position = Vector2\(([^)]+)\)\s*platform_size = Vector2\(([^)]+)\)/);
    if (ceilingMatch) {
      const pos = ceilingMatch[1];
      const size = ceilingMatch[2];
      if (pos !== '0, 0' || !size.startsWith('960,')) {
        issues.push(`Level ${i} (${tscnPath}): Ceiling pos=${pos}, size=${size}`);
      }
    } else {
      issues.push(`Level ${i} (${tscnPath}): Ceiling node found but failed regex parse`);
    }
  }

  // Check if there is falling_spike or crusher without Ceiling
  if ((content.includes('falling_spike.tscn') || content.includes('crusher.tscn')) && !content.includes('[node name="Ceiling"')) {
    issues.push(`Level ${i} (${tscnPath}): Has falling_spike/crusher but NO Ceiling node!`);
  }
}

console.log(`TSCN Ceiling Audit Complete. Total issues found: ${issues.length}`);
issues.forEach(i => console.log(' - ' + i));

