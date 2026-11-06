const fs = require('fs');
const path = require('path');

function walk(dir) {
  let res = [];
  if (!fs.existsSync(dir)) return res;
  for (const f of fs.readdirSync(dir)) {
    if (['.git', '.godot', 'audit', 'build'].includes(f)) continue;
    const p = dir === '.' ? f : dir + '/' + f;
    if (fs.statSync(p).isDirectory()) {
      res = res.concat(walk(p));
    } else {
      res.push(p.replace(/\\/g, '/'));
    }
  }
  return res;
}

const scripts = walk('scripts').filter(f => f.endsWith('.gd'));

const suspiciousPatterns = [
  { id: 'DIV_BY_ZERO', regex: /\/\s*(?:float\()?[a-zA-Z0-9_.]+(?:\))?\b/, desc: 'Potential division by zero without zero guard' },
  { id: 'AWAIT_HTTP', regex: /await\s+.*request/, desc: 'Async HTTP request await without timeout or network failure check' },
  { id: 'UNCHECKED_CONNECT', regex: /\.connect\(/, desc: 'Signal connect call without is_connected guard' },
  { id: 'HARDCODED_SCREEN_SIZE', regex: /Vector2\(\s*960\s*,\s*540\s*\)/, desc: 'Hardcoded 960x540 viewport dimension' },
  { id: 'GET_NODE_ROOT', regex: /get_node(?:_or_null)?\("\/root\/[A-Za-z0-9_]+"\)/, desc: 'Direct root node lookup' }
];

const functionAudits = [];

for (const s of scripts) {
  const content = fs.readFileSync(s, 'utf8');
  const lines = content.split('\n');

  let currentFunc = null;
  let funcLines = [];
  let funcStartLine = 0;

  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('func ')) {
      if (currentFunc) {
        analyzeFunc(s, currentFunc, funcStartLine, funcLines.join('\n'));
      }
      const match = trimmed.match(/^func\s+([a-zA-Z0-9_]+)\s*\((.*?)\)(?:\s*->\s*([a-zA-Z0-9_]+))?:/);
      if (match) {
        currentFunc = { name: match[1], params: match[2], ret: match[3] || 'void' };
        funcStartLine = idx + 1;
        funcLines = [line];
      }
    } else if (currentFunc) {
      if (line.startsWith('\t') || line.startsWith('    ') || trimmed === '' || trimmed.startsWith('#')) {
        funcLines.push(line);
      } else {
        analyzeFunc(s, currentFunc, funcStartLine, funcLines.join('\n'));
        currentFunc = null;
        funcLines = [];
      }
    }
  });

  if (currentFunc) {
    analyzeFunc(s, currentFunc, funcStartLine, funcLines.join('\n'));
  }
}

function analyzeFunc(file, funcMeta, startLine, body) {
  const issues = [];

  // Check unchecked connects
  const connectMatches = body.match(/\b([a-zA-Z0-9_.]+)\.connect\(/g);
  if (connectMatches && !body.includes('is_connected(')) {
    // Only flag if connect occurs in a method that can be called multiple times (not _ready)
    if (!funcMeta.name.startsWith('_ready') && !funcMeta.name.startsWith('_init')) {
      issues.push({
        type: 'UNGUARDED_SIGNAL_CONNECT',
        severity: 'MEDIUM',
        desc: `Signal .connect() in non-ready function '${funcMeta.name}' without is_connected() check can cause duplicate signal connection errors on re-entry.`
      });
    }
  }

  // Check direct autoload references in scripts that may run standalone
  if (body.includes('GameManager.') && !body.includes('get_node_or_null')) {
    issues.push({
      type: 'DIRECT_AUTOLOAD_DEPENDENCY',
      severity: 'LOW',
      desc: `Direct call to GameManager in '${funcMeta.name}'. Causes compile/runtime errors when instantiated without autoload tree.`
    });
  }

  // Check division by zero risk
  if (body.includes(' / win_size.x') || body.includes(' / win_size.y') || body.includes(' / vp_size.x') || body.includes(' / vp_size.y')) {
    if (!body.includes('<= 0') && !body.includes('!= 0') && !body.includes('maxf(')) {
      issues.push({
        type: 'POTENTIAL_DIV_ZERO',
        severity: 'HIGH',
        desc: `Division by viewport or window size without zero guard in '${funcMeta.name}'.`
      });
    }
  }

  // Check async await without error code validation
  if (body.includes('await http_request.request_completed') && !body.includes('HTTPClient.STATUS_')) {
    issues.push({
      type: 'UNVALIDATED_ASYNC_HTTP',
      severity: 'HIGH',
      desc: `Awaiting http_request.request_completed in '${funcMeta.name}' without validating HTTP client response status codes or timeout.`
    });
  }

  functionAudits.push({
    file,
    funcName: funcMeta.name,
    params: funcMeta.params,
    returnType: funcMeta.ret,
    startLine,
    lineCount: body.split('\n').length,
    issues
  });
}

console.log('Audited functions count:', functionAudits.length);
const issuesCount = functionAudits.reduce((acc, f) => acc + f.issues.length, 0);
console.log('Total function issues identified:', issuesCount);

fs.writeFileSync('audit/function_audit_data.json', JSON.stringify(functionAudits, null, 2));
console.log('Function audit written to audit/function_audit_data.json');

