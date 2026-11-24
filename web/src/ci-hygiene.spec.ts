import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');

const workflowFiles = ['web_pr_tests.yml', 'web_deploy_github_pages.yml'];
const workflows = workflowFiles.map((file) => ({ file, text: read(`.github/workflows/${file}`) }));

/** Splits a workflow into its top-level jobs: [name, text]. */
const jobsOf = (text: string): [string, string][] => {
  const body = text.slice(text.search(/^jobs:/m));
  return body
    .split(/^ {2}(?=[a-z][\w-]*:\s*$)/m)
    .slice(1)
    .map((chunk) => [chunk.slice(0, chunk.indexOf(':')), chunk] as [string, string]);
};

const allJobs = workflows.flatMap(({ file, text }) => jobsOf(text).map(([name, job]) => ({ id: `${file}:${name}`, job })));

/** Bundled npm major per Node major (https://nodejs.org/en/about/previous-releases). */
const BUNDLED_NPM_MAJOR: Record<string, number> = { '20': 10, '22': 10, '24': 11 };

describe('web CI hygiene', () => {
  it('finds the jobs of both web workflows', () => {
    expect(allJobs.length).toBeGreaterThanOrEqual(5);
  });

  describe('reproducibility (CICD-07)', () => {
    it.each(allJobs)('pins the runner image of $id', ({ job }) => {
      expect(job).toMatch(/runs-on:\s*ubuntu-\d{2}\.\d{2}\s*$/m);
      expect(job).not.toMatch(/-latest/);
    });

    it('declares the npm version that ships with the Node version pinned in .nvmrc', () => {
      const nodeMajor = read('web/.nvmrc').trim().replace(/^v/, '').split('.')[0] ?? '';
      const packageManager = (JSON.parse(read('web/package.json')) as { packageManager: string }).packageManager;

      expect(packageManager).toMatch(/^npm@\d+\.\d+\.\d+$/);
      expect(Number(packageManager.split('@')[1]?.split('.')[0])).toBe(BUNDLED_NPM_MAJOR[nodeMajor]);
    });
  });

  describe('supply chain (CICD-10)', () => {
    it('pins every third-party action to a full commit SHA', () => {
      const uses = workflows
        .flatMap(({ text }) => [...text.matchAll(/^\s+uses:\s*(\S+)/gm)].map((match) => match[1] ?? ''))
        .filter((action) => !/^(actions|github)\//.test(action));

      expect(uses.length).toBeGreaterThan(0);
      expect(uses.filter((action) => !/@[0-9a-f]{40}$/.test(action))).toEqual([]);
    });
  });

  describe('failures and resources (CICD-12)', () => {
    it.each(allJobs)('limits the run time of $id', ({ job }) => {
      expect(job).toMatch(/^\s{4}timeout-minutes:\s*\d+\s*$/m);
    });

    it('does not cancel a production deployment that is already running', () => {
      const deploy = read('.github/workflows/web_deploy_github_pages.yml');

      expect(deploy).toMatch(/concurrency:\s*\n\s+group:\s*pages\s*\n(\s+#.*\n)*\s+cancel-in-progress:\s*false/);
    });

    it('opens an issue when the main pipeline fails', () => {
      const deploy = read('.github/workflows/web_deploy_github_pages.yml');
      const notify = jobsOf(deploy).find(([name]) => name === 'notify-failure')?.[1] ?? '';

      expect(notify).toMatch(/needs:\s*\[build, deploy, lighthouse\]/);
      expect(notify).toMatch(/if:\s*\$\{\{ failure\(\) && github\.ref == 'refs\/heads\/main' \}\}/);
      expect(notify).toMatch(/permissions:\s*\n\s+issues:\s*write/);
      expect(notify).toContain('github.rest.issues.create');
    });
  });
});
