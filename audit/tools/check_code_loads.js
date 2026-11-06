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

const allScripts = getFiles('.', '.gd');
const brokenLoads = [];

allScripts.forEach(scriptFile => {
    const content = fs.readFileSync(scriptFile, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, i) => {
        const matches = line.matchAll(/(?:preload|load)\s*\(\s*["']res:\/\/([^"']+)["']\s*\)/g);
        for (const m of matches) {
            const relPath = m[1];
            const fsPath = path.normalize(relPath);
            if (!fs.existsSync(fsPath)) {
                brokenLoads.push({
                    script: scriptFile,
                    line: i + 1,
                    target: 'res://' + relPath
                });
            }
        }
    });
});

console.log(`Broken load/preload references in scripts: ${brokenLoads.length}`);
console.table(brokenLoads);

fs.writeFileSync('audit/broken_load_references.json', JSON.stringify(brokenLoads, null, 2));

