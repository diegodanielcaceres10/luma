#!/usr/bin/env node
// Prints the coverage totals as a Markdown table (used for the GitHub job summary).
// Usage: node scripts/coverage-summary.mjs [path/to/coverage-summary.json]
// Never fails: a missing or unreadable report is described in the output instead.
import { readFileSync } from 'node:fs';

const file = process.argv[2] ?? 'coverage/web/coverage-summary.json';
const METRICS = [
  ['statements', 'Statements'],
  ['branches', 'Branches'],
  ['functions', 'Functions'],
  ['lines', 'Lines'],
];

try {
  const { total } = JSON.parse(readFileSync(file, 'utf8'));
  const rows = METRICS.map(([key, label]) => `| ${label} | ${total[key].covered} | ${total[key].total} | ${total[key].pct}% |`);
  console.log(['## Code coverage', '', '| Metric | Covered | Total | % |', '| --- | ---: | ---: | ---: |', ...rows].join('\n'));
} catch {
  console.log(`Coverage summary not found or unreadable: ${file}`);
}
