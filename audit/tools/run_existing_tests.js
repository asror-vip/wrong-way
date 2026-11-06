const { execSync } = require('child_process');
const fs = require('fs');

const godotPath = 'D:\\Downloads\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe';

const testFiles = [
    'tests/test_player_dash.gd',
    'tests/audit_all_levels.gd',
    'tests/render_level_06.gd',
    'tests/gameplay/test_ad_system.gd',
    'tests/gameplay/test_full_game_flow.gd',
    'tests/gameplay/test_menu_progression_and_stars.gd',
    'tests/gameplay/test_navigation_context.gd',
    'tests/gameplay/test_session_and_player.gd'
];

const results = [];

testFiles.forEach(file => {
    console.log('Testing: ' + file);
    const cmd = `"${godotPath}" --headless -s "${file}"`;
    let stdout = '', stderr = '', exitCode = 0, status = 'UNKNOWN';
    try {
        stdout = execSync(cmd, { encoding: 'utf8', timeout: 8000, stdio: ['pipe', 'pipe', 'pipe'] });
        status = stdout.includes('FAILED') || stdout.includes('Assertion failed') || stdout.includes('SCRIPT ERROR') ? 'FAIL' : 'PASS';
    } catch (e) {
        exitCode = e.status || 1;
        stdout = (e.stdout || '').toString();
        stderr = (e.stderr || '').toString();
        status = 'CRASH/FAIL';
    }
    
    // Check key errors in output
    const errors = [];
    const lines = (stdout + '\n' + stderr).split('\n');
    lines.forEach(l => {
        if (l.includes('ERROR:') || l.includes('SCRIPT ERROR:') || l.includes('Assertion failed')) {
            errors.push(l.trim());
        }
    });

    results.push({
        file: file,
        status: status,
        exitCode: exitCode,
        errorCount: errors.length,
        errors: errors.slice(0, 5),
        outputPreview: lines.slice(0, 10).join(' ')
    });
    console.log(`-> Status: ${status} (exit ${exitCode}, errors ${errors.length})`);
});

fs.writeFileSync('audit/existing_test_suite_results.json', JSON.stringify(results, null, 2));
console.log('Wrote results to audit/existing_test_suite_results.json');

