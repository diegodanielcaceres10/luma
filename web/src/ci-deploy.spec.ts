import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const workflow = readFileSync(resolve(process.cwd(), '../.github/workflows/web_deploy_github_pages.yml'), 'utf8');

/** Returns the text of a top-level job, from its key to the next job (or the end of the file). */
const job = (name: string) => {
  const start = workflow.search(new RegExp(`^ {2}${name}:`, 'm'));
  const rest = workflow.slice(start + 1);
  const next = rest.search(/\n {2}[a-z-]+:\n/);
  return start === -1 ? '' : rest.slice(0, next === -1 ? undefined : next);
};

describe('web production deploy', () => {
  it('is triggered only by pushes to main and by manual runs, never by pull requests', () => {
    const triggers = workflow.slice(workflow.indexOf('\non:'), workflow.indexOf('\npermissions:'));

    expect(triggers).toMatch(/push:\s*\n\s+branches:\s*\n\s+- main\b/);
    expect(triggers).toContain('workflow_dispatch:');
    expect(triggers).not.toMatch(/pull_request/);
  });

  it('publishes only from main, even when the workflow is run manually from another branch', () => {
    expect(job('deploy')).toMatch(/^\s+if:\s*github\.ref == 'refs\/heads\/main'\s*$/m);
  });

  it('publishes through the github-pages environment', () => {
    expect(job('deploy')).toMatch(/environment:\s*\n\s+name:\s*github-pages\b/);
  });

  it('only publishes what the build job produced', () => {
    expect(job('deploy')).toMatch(/needs:\s*build\b/);
  });

  it('skips the production Lighthouse run when nothing was published', () => {
    expect(job('lighthouse')).toMatch(/needs:\s*deploy\b/);
    // A job-level `if` such as always() would run it even when the deploy was skipped.
    expect(job('lighthouse')).not.toMatch(/^ {4}if:/m);
  });
});
