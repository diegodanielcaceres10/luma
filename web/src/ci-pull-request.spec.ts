import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const workflowPath = '.github/workflows/web_pr_tests.yml';
const workflow = readFileSync(resolve(root, workflowPath), 'utf8');
const packageJson = JSON.parse(readFileSync(resolve(root, 'web/package.json'), 'utf8')) as {
  scripts: Record<string, string>;
};

describe('web pull request workflow', () => {
  it('runs on pull requests to main', () => {
    expect(workflow).toMatch(/^on:\s*\n\s+pull_request:\s*\n\s+branches:\s*\n\s+- main\b/m);
  });

  it('only filters on workflow files that exist', () => {
    const referenced = [...workflow.matchAll(/^\s+- "(\.github\/workflows\/[^"]+)"/gm)].map((match) => match[1] ?? '');

    expect(referenced).toContain(workflowPath);
    expect(referenced.filter((path) => !existsSync(resolve(root, path)))).toEqual([]);
  });

  it.each(['lint', 'test', 'build'])('runs the npm script "%s"', (script) => {
    expect(packageJson.scripts[script]).toBeDefined();
    expect(workflow).toMatch(new RegExp(`^\\s+run: npm run ${script}\\s*$`, 'm'));
  });

  it('installs from the lockfile and does not call ng directly', () => {
    expect(workflow).toMatch(/^\s+run: npm ci\s*$/m);
    expect(workflow).not.toMatch(/\b(npx\s+)?ng\s+(test|build|lint)\b/);
  });

  it('checks that the version is greater than the one on the base branch', () => {
    expect(packageJson.scripts['check:version']).toContain('scripts/check-version.mjs');
    expect(workflow).toMatch(/fetch-depth:\s*0/);
    expect(workflow).toMatch(/^\s+run: npm run check:version -- "\$BASE_REF"\s*$/m);
    expect(workflow).toMatch(/BASE_REF:\s*origin\/\$\{\{ github\.base_ref \}\}/);
  });

  it('never lets the mandatory steps fail silently', () => {
    expect(workflow).not.toMatch(/continue-on-error|\|\|\s*true/);
  });
});
