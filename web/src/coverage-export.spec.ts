import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');
const angular = JSON.parse(read('web/angular.json')) as {
  projects: Record<string, { architect: { test: { options: { coverageReporters?: string[] } } } }>;
};
const testOptions = angular.projects['web']?.architect.test.options;
const mainWorkflow = read('.github/workflows/web_deploy_github_pages.yml');
const script = resolve(process.cwd(), 'scripts/coverage-summary.mjs');

/** Returns the text of the workflow step whose `name:` matches. */
const step = (name: string) => {
  const start = mainWorkflow.indexOf(`- name: ${name}`);
  const rest = mainWorkflow.slice(start + 1);
  const next = rest.search(/\n\s+- name: /);
  return start === -1 ? '' : rest.slice(0, next === -1 ? undefined : next);
};

describe('coverage export in the main CI', () => {
  it('writes the machine-readable summary and the browsable report', () => {
    expect(testOptions?.coverageReporters).toEqual(expect.arrayContaining(['html', 'lcov', 'json-summary']));
  });

  it('uploads the coverage directory Angular writes (coverage/<project>) as an artifact', () => {
    const upload = step('Upload coverage report');

    expect(upload).toContain('uses: actions/upload-artifact@');
    expect(upload).toMatch(/path:\s*web\/coverage\/web\s*$/m);
  });

  it('uploads and summarizes even when the tests fail', () => {
    expect(step('Upload coverage report')).toMatch(/if:\s*\$\{\{ !cancelled\(\) \}\}|if:\s*always\(\)/);
    expect(step('Add coverage to job summary')).toMatch(/if:\s*\$\{\{ !cancelled\(\) \}\}|if:\s*always\(\)/);
  });

  it('runs after the tests so the report exists', () => {
    const order = ['Run unit tests', 'Add coverage to job summary', 'Upload coverage report'].map((name) =>
      mainWorkflow.indexOf(`- name: ${name}`),
    );

    expect(order.every((index) => index > -1)).toBe(true);
    expect([...order].sort((a, b) => a - b)).toEqual(order);
  });
});

describe('coverage summary script (scripts/coverage-summary.mjs)', () => {
  let dir: string;

  const run = (file: string) => spawnSync('node', [script, file], { encoding: 'utf8' });

  beforeEach(() => {
    dir = mkdtempSync(join(tmpdir(), 'coverage-summary-'));
  });

  afterEach(() => rmSync(dir, { recursive: true, force: true }));

  it('prints a Markdown table with the four totals', () => {
    const file = join(dir, 'coverage-summary.json');
    const metric = (pct: number, covered: number, total: number) => ({ total, covered, skipped: 0, pct });
    writeFileSync(
      file,
      JSON.stringify({
        total: {
          statements: metric(99.93, 1462, 1463),
          branches: metric(99.71, 344, 345),
          functions: metric(100, 100, 100),
          lines: metric(100, 1007, 1007),
        },
      }),
    );

    const result = run(file);

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('| Metric | Covered | Total | % |');
    expect(result.stdout).toContain('| Statements | 1462 | 1463 | 99.93% |');
    expect(result.stdout).toContain('| Branches | 344 | 345 | 99.71% |');
    expect(result.stdout).toContain('| Functions | 100 | 100 | 100% |');
    expect(result.stdout).toContain('| Lines | 1007 | 1007 | 100% |');
  });

  it('reports a missing summary without failing the job', () => {
    const result = run(join(dir, 'missing.json'));

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('Coverage summary not found');
  });

  it('reports an unreadable summary without failing the job', () => {
    const file = join(dir, 'broken.json');
    writeFileSync(file, '{ not json');

    const result = run(file);

    expect(result.status).toBe(0);
    expect(result.stdout).toContain('Coverage summary not found');
  });
});
