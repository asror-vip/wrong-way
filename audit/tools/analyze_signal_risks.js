const fs = require('fs');

const funcAudits = JSON.parse(fs.readFileSync('audit/function_audit_data.json', 'utf8'));

const signalIssues = [];

funcAudits.forEach(fa => {
  fa.issues.forEach(iss => {
    if (iss.type === 'UNGUARDED_SIGNAL_CONNECT') {
      const content = fs.readFileSync(fa.file, 'utf8');
      const lines = content.split('\n');
      const funcBody = lines.slice(fa.startLine - 1, fa.startLine + fa.lineCount).join('\n');
      
      // Determine if the function is called repeatedly
      let callFrequency = 'ONCE_PER_SCENE'; // default
      if (fa.funcName.includes('open') || fa.funcName.includes('show') || fa.funcName.includes('update') || fa.funcName.includes('refresh') || fa.funcName.includes('bind') || fa.funcName.includes('setup')) {
        callFrequency = 'POTENTIALLY_REPEATED';
      }
      if (fa.funcName.startsWith('_on_')) {
        callFrequency = 'CALLED_ON_EVENT';
      }

      signalIssues.push({
        file: fa.file,
        line: fa.startLine,
        funcName: fa.funcName,
        callFrequency,
        funcBodySnippet: funcBody.substring(0, 200)
      });
    }
  });
});

console.log('Total unguarded signal connections identified:', signalIssues.length);
const repeatedRisk = signalIssues.filter(s => s.callFrequency !== 'ONCE_PER_SCENE');
console.log('High risk of duplicate connection (called repeatedly/on event):', repeatedRisk.length);

fs.writeFileSync('audit/signal_risk_analysis.json', JSON.stringify({ total: signalIssues.length, highRiskCount: repeatedRisk.length, repeatedRisk, all: signalIssues }, null, 2));

