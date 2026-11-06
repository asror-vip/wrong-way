const fs = require('fs');

const ratios = [
  { name: '16:9 Standard', width: 960, height: 540, aspect: 16/9 },
  { name: '18:9 (2:1)', width: 1080, height: 540, aspect: 18/9 },
  { name: '19.5:9 Modern Notch', width: 1170, height: 540, aspect: 19.5/9 },
  { name: '20:9 Ultra-wide Android', width: 1200, height: 540, aspect: 20/9 },
  { name: '4:3 Tablet / iPad', width: 960, height: 720, aspect: 4/3 }
];

// Check UI scripts for anchor/offset patterns
const uiFiles = [
  'scripts/ui/splash_screen.gd',
  'scripts/ui/main_menu.gd',
  'scripts/ui/level_select.gd',
  'scripts/ui/game_hud.gd',
  'scripts/ui/pause_modal.gd',
  'scripts/ui/settings_modal.gd',
  'scripts/ui/auth_modal.gd',
  'scripts/ui/profile_modal.gd',
  'scripts/ui/control_customizer.gd',
  'scripts/levels/gameplay.gd'
];

const findings = [];

uiFiles.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const lines = content.split('\n');

  lines.forEach((line, idx) => {
    // Check hardcoded 960 or 540 offsets
    if (line.includes('960') || line.includes('540')) {
      if (!line.includes('Vector2(960.0, 540.0)') && !line.includes('base_w') && !line.includes('DEFAULT_VIEWPORT')) {
        findings.push({
          file, line: idx + 1, code: line.trim(),
          issue: 'Hardcoded 960/540 constant may break on dynamic aspect ratio expansion.'
        });
      }
    }
  });
});

console.log('UI hardcoded coordinate findings:', findings.length);

fs.writeFileSync('audit/ui_audit_data.json', JSON.stringify({ ratios, findings }, null, 2));
