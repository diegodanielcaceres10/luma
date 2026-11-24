import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');

const workflow = read('.github/workflows/web_deploy_github_pages.yml');
const lighthouseJob = workflow.slice(workflow.search(/^ {2}lighthouse:/m));

const stepIndex = (name: string) => lighthouseJob.indexOf(`- name: ${name}`);
const step = (name: string) => {
  const start = stepIndex(name);
  const rest = lighthouseJob.slice(start + 1);
  const next = rest.search(/\n\s+- name: /);
  return start === -1 ? '' : rest.slice(0, next === -1 ? undefined : next);
};

const configs = ['web/lighthouserc.desktop.json', 'web/lighthouserc.mobile.json'].map(
  (path) => JSON.parse(read(path)) as { ci: { assert: { assertions: Record<string, unknown> } } },
);

describe('Lighthouse in the main CI', () => {
  it('runs after the site is deployed, which itself waits for lint, test and build', () => {
    expect(lighthouseJob).toMatch(/needs:\s*deploy\b/);
    expect(workflow).toMatch(/^ {2}deploy:[\s\S]*?needs:\s*build\b/m);
  });

  it('asserts the four Lighthouse categories for desktop and mobile', () => {
    for (const config of configs) {
      expect(Object.keys(config.ci.assert.assertions).sort()).toEqual([
        'categories:accessibility',
        'categories:best-practices',
        'categories:performance',
        'categories:seo',
      ]);
    }
  });

  it('keeps each run in its own folder before the next run replaces the results', () => {
    const order = [
      'Run Lighthouse CI Desktop',
      'Save Lighthouse desktop reports',
      'Run Lighthouse CI Mobile',
      'Save Lighthouse mobile reports',
      'Upload Lighthouse reports',
    ].map(stepIndex);

    expect(order.every((index) => index > -1)).toBe(true);
    expect([...order].sort((a, b) => a - b)).toEqual(order);
    expect(step('Save Lighthouse desktop reports')).toContain('lighthouse-reports/desktop');
    expect(step('Save Lighthouse mobile reports')).toContain('lighthouse-reports/mobile');
  });

  it('reads the results folder from the action output instead of assuming its location', () => {
    expect(step('Save Lighthouse desktop reports')).toContain('steps.lhci-d.outputs.resultsPath');
    expect(step('Save Lighthouse mobile reports')).toContain('steps.lhci-m.outputs.resultsPath');
  });

  it('uploads the reports as a single artifact even when an assertion fails', () => {
    const upload = step('Upload Lighthouse reports');

    expect(upload).toContain('uses: actions/upload-artifact@');
    expect(upload).toMatch(/name:\s*lighthouse-reports\s*$/m);
    expect(upload).toMatch(/path:\s*lighthouse-reports\s*$/m);
    expect(upload).toMatch(/if:\s*\$\{\{ !cancelled\(\) \}\}/);
  });

  it('does not use the action artifact upload, whose fixed name would clash between the two runs', () => {
    expect(lighthouseJob).not.toMatch(/uploadArtifacts:\s*true/);
  });
});
