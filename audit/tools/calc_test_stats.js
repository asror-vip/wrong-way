const fs = require('fs');

const lines = fs.readFileSync('audit/TEST_CASES.csv', 'utf8').trim().split('\n').slice(1);
const counts = { PASS: 0, FAIL: 0, BLOCKED: 0 };

lines.forEach(l => {
    if (l.includes(',PASS,')) counts.PASS++;
    else if (l.includes(',FAIL,')) counts.FAIL++;
    else if (l.includes(',BLOCKED,')) counts.BLOCKED++;
});

console.log(JSON.stringify({
    total: lines.length,
    counts: counts
}, null, 2));

fs.writeFileSync('audit/test_statistics.json', JSON.stringify({
    total_tests: lines.length,
    passed: counts.PASS,
    failed: counts.FAIL,
    blocked: counts.BLOCKED
}, null, 2));

