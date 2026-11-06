const fs = require('fs');

const funcData = JSON.parse(fs.readFileSync('audit/function_audit_data.json', 'utf8'));

// Group functions by system
const systems = {
  'Core Singletons & Services': f => f.file.startsWith('scripts/core/'),
  'Player Controller & Movement': f => f.file.startsWith('scripts/player/'),
  'Gameplay & Camera Systems': f => f.file.startsWith('scripts/levels/'),
  'Trap & Hazard Systems': f => f.file.startsWith('scripts/traps/'),
  'UI & Responsive Layout': f => f.file.startsWith('scripts/ui/'),
  'Multiplayer & Duel Systems': f => f.file.startsWith('scripts/multiplayer/'),
  'Editor & Level Authoring Tools': f => f.file.startsWith('scripts/editor/') || f.file.startsWith('scripts/tools/'),
  'Automated Test Suites': f => f.file.startsWith('tests/')
};

let md = `# WRONG WAY — PHASE 2: FUNCTION-BY-FUNCTION CODE AUDIT

**Audit Phase:** 02 — Function-by-Function Code Audit  
**Date:** 2026-11-06  
**Auditor:** Senior GDScript Code Reviewer & Systems Auditor  
**Total Project Scripts Audited:** 81 scripts  
**Total Project Functions Audited:** 689 functions  
**External Plugin Functions Cataloged:** 701 functions (inside \`addons/admob\`)  
**Combined Total Functions:** 1,390 functions  

---

## 1. FUNCTION AUDIT SUMMARY BY SYSTEM

| System Category | Script Count | Function Count | Issues Flagged | High Risk Issues | Status |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Core Singletons & Services** | 12 | 148 | 18 | 4 | **AUDITED** |
| **Player Controller & Movement** | 3 | 28 | 3 | 1 | **AUDITED** |
| **Gameplay & Camera Systems** | 5 | 52 | 6 | 1 | **AUDITED** |
| **Trap & Hazard Systems** | 22 | 114 | 8 | 0 | **AUDITED** |
| **UI & Responsive Layout** | 15 | 164 | 22 | 6 | **AUDITED** |
| **Multiplayer & Duel Systems** | 5 | 76 | 9 | 2 | **AUDITED** |
| **Editor & Level Authoring Tools** | 4 | 78 | 14 | 3 | **AUDITED** |
| **Automated Test Suites** | 15 | 29 | 12 | 12 | **AUDITED (CRASHES)** |
| **External Plugins (\`addons/admob\`)** | 157 | 701 | N/A | N/A | **EXTERNAL LIBRARY** |

---
`;

for (const [sysName, filterFn] of Object.entries(systems)) {
  const funcs = funcData.filter(filterFn);
  md += `\n## 2. SYSTEM: ${sysName.toUpperCase()}\n\n`;
  md += `Total Functions Audited in this system: **${funcs.length}**\n\n`;

  // Group by file
  const fileGroups = {};
  funcs.forEach(f => {
    fileGroups[f.file] = fileGroups[f.file] || [];
    fileGroups[f.file].push(f);
  });

  for (const [file, fList] of Object.entries(fileGroups)) {
    md += `### File: \`${file}\` (${fList.length} functions)\n\n`;
    md += `| Function Name | Return | Line | Params | Risk / Issues |\n`;
    md += `| :--- | :---: | :---: | :--- | :--- |\n`;

    fList.forEach(f => {
      const issueStr = f.issues.length > 0 ? f.issues.map(i => `**[${i.type}]** ${i.desc}`).join('<br>') : 'CLEAN / PASS';
      md += `| \`${f.funcName}()\` | \`${f.returnType}\` | L${f.startLine} | \`${f.params || 'none'}\` | ${issueStr} |\n`;
    });
    md += `\n`;
  }
}

fs.writeFileSync('audit/02_FUNCTION_AUDIT.md', md);
console.log('Phase 2 report written to audit/02_FUNCTION_AUDIT.md');

