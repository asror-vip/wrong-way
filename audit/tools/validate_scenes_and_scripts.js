const fs = require('fs');
const path = require('path');

function getFiles(dir, ext) {
    let results = [];
    fs.readdirSync(dir).forEach(file => {
        const full = path.join(dir, file);
        if (fs.statSync(full).isDirectory()) {
            if (file !== '.git' && file !== '.godot' && file !== 'audit') {
                results = results.concat(getFiles(full, ext));
            }
        } else if (file.endsWith(ext)) {
            results.push(full);
        }
    });
    return results;
}

const allScenes = getFiles('.', '.tscn');
const allScripts = getFiles('.', '.gd');

console.log(`Total scenes to validate: ${allScenes.length}`);
console.log(`Total scripts to validate: ${allScripts.length}`);

// Check scene resource references
const brokenExtResources = [];
allScenes.forEach(sceneFile => {
    const content = fs.readFileSync(sceneFile, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, i) => {
        const m = line.match(/\[ext_resource type="([^"]+)" path="res:\/\/([^"]+)" id="([^"]+)"\]/);
        if (m) {
            const relPath = m[2];
            const fsPath = path.normalize(relPath);
            if (!fs.existsSync(fsPath)) {
                brokenExtResources.push({
                    scene: sceneFile,
                    line: i + 1,
                    type: m[1],
                    target: relPath
                });
            }
        }
    });
});

console.log(`Broken ext_resource references in scenes: ${brokenExtResources.length}`);
if (brokenExtResources.length > 0) {
    console.table(brokenExtResources);
}

fs.writeFileSync('audit/broken_scene_references.json', JSON.stringify(brokenExtResources, null, 2));

