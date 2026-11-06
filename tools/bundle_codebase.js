const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..');
const OUTPUT_FILE = path.join(ROOT_DIR, 'project_code.txt');

// Folders and patterns to ignore
const IGNORE_DIRS = new Set(['.git', '.godot', '.idea', 'build', 'node_modules', 'dist']);
const IGNORE_EXTS = new Set([
  '.png', '.jpg', '.jpeg', '.webp', '.ico', '.wav', '.ogg', '.mp3',
  '.import', '.uid', '.apk', '.aab', '.keystore', '.jar', '.dex',
  '.so', '.zip', '.pck', '.tmp'
]);

// Relevant extensions
const ALLOWED_EXTS = new Set(['.gd', '.gdshader', '.tscn', '.tres', '.json', '.cfg', '.godot', '.js', '.md']);

function getAllFiles(dirPath, arrayOfFiles = []) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    const relPath = path.relative(ROOT_DIR, fullPath).replace(/\\/g, '/');

    if (entry.isDirectory()) {
      if (!IGNORE_DIRS.has(entry.name)) {
        getAllFiles(fullPath, arrayOfFiles);
      }
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name).toLowerCase();
      // Skip the output file itself
      if (entry.name === 'project_code.txt') continue;
      if (IGNORE_EXTS.has(ext)) continue;

      if (ALLOWED_EXTS.has(ext) || entry.name === 'project.godot' || entry.name === 'export_presets.cfg') {
        arrayOfFiles.push({ fullPath, relPath, ext, name: entry.name });
      }
    }
  }

  return arrayOfFiles;
}

console.log('Scanning project files in:', ROOT_DIR);
const files = getAllFiles(ROOT_DIR);

// Sort files logically:
// 1. project.godot & configs
// 2. scripts/core
// 3. scripts/player, platforms, traps, objects
// 4. scripts/ui
// 5. scripts/levels, editor
// 6. shaders
// 7. scenes
// 8. data, resources
// 9. tools, tests, docs
files.sort((a, b) => {
  const getOrder = (p) => {
    if (p.startsWith('project.godot')) return 1;
    if (p.startsWith('scripts/core/')) return 2;
    if (p.startsWith('scripts/player/')) return 3;
    if (p.startsWith('scripts/platforms/')) return 4;
    if (p.startsWith('scripts/traps/')) return 5;
    if (p.startsWith('scripts/objects/')) return 6;
    if (p.startsWith('scripts/levels/')) return 7;
    if (p.startsWith('scripts/ui/')) return 8;
    if (p.startsWith('scripts/editor/')) return 9;
    if (p.startsWith('scripts/multiplayer/')) return 10;
    if (p.startsWith('scripts/')) return 11;
    if (p.startsWith('shaders/')) return 12;
    if (p.startsWith('scenes/')) return 13;
    if (p.startsWith('data/')) return 14;
    if (p.startsWith('resources/')) return 15;
    if (p.startsWith('tools/')) return 16;
    if (p.startsWith('tests/')) return 17;
    if (p.startsWith('docs/')) return 18;
    return 99;
  };

  const orderA = getOrder(a.relPath);
  const orderB = getOrder(b.relPath);
  if (orderA !== orderB) return orderA - orderB;
  return a.relPath.localeCompare(b.relPath);
});

console.log(`Found ${files.length} code and configuration files.`);

const outStream = fs.createWriteStream(OUTPUT_FILE, { encoding: 'utf8' });

outStream.write('================================================================================\n');
outStream.write('WRONG WAY -- COMPLETE PROJECT CODEBASE & CONFIGURATION ARCHIVE\n');
outStream.write(`Generated: ${new Date().toISOString()}\n`);
outStream.write(`Total Files: ${files.length}\n`);
outStream.write('Engine: Godot 4.7.2 (GL Compatibility Renderer, 2D Precision Platformer)\n');
outStream.write('================================================================================\n\n');

outStream.write('TABLE OF CONTENTS:\n');
outStream.write('--------------------------------------------------------------------------------\n');
for (let i = 0; i < files.length; i++) {
  outStream.write(`${String(i + 1).padStart(3, ' ')}. ${files[i].relPath}\n`);
}
outStream.write('--------------------------------------------------------------------------------\n\n');

let processedCount = 0;
for (const file of files) {
  try {
    const content = fs.readFileSync(file.fullPath, 'utf8');
    const lineCount = content.split('\n').length;

    outStream.write('\n');
    outStream.write('================================================================================\n');
    outStream.write(`FILE: ${file.relPath}\n`);
    outStream.write(`LINES: ${lineCount} | SIZE: ${Buffer.byteLength(content, 'utf8')} bytes\n`);
    outStream.write('================================================================================\n');
    outStream.write(content);
    if (!content.endsWith('\n')) {
      outStream.write('\n');
    }
    processedCount++;
  } catch (err) {
    console.error(`Error reading ${file.relPath}:`, err.message);
  }
}

outStream.end(() => {
  const stats = fs.statSync(OUTPUT_FILE);
  const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);
  console.log(`\nSuccessfully created: ${OUTPUT_FILE}`);
  console.log(`Total Files Written: ${processedCount}`);
  console.log(`Output File Size: ${sizeMB} MB (${stats.size} bytes)`);
});
