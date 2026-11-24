import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');

const workflow = read('.github/workflows/web_deploy_github_pages.yml');
const readme = read('README.md');

const buildJob = workflow.slice(workflow.search(/^ {2}build:/m), workflow.search(/^ {2}deploy:/m));
const dispatch = workflow.slice(workflow.indexOf('workflow_dispatch:'), workflow.indexOf('\npermissions:'));

describe('web rollback', () => {
  it('lets a manual run choose the commit or tag to publish', () => {
    expect(dispatch).toMatch(/inputs:\s*\n\s+ref:/);
    expect(dispatch).toMatch(/required:\s*false/);
    expect(dispatch).toMatch(/type:\s*string/);
  });

  it('builds the chosen ref, falling back to the commit that triggered the run', () => {
    expect(buildJob).toMatch(/uses: actions\/checkout@v\d+\s*\n\s+with:\s*\n[\s\S]*?ref:\s*\$\{\{ inputs\.ref \}\}/);
  });

  it('keeps the full history so the chosen ref can be validated', () => {
    expect(buildJob).toMatch(/fetch-depth:\s*0/);
  });

  it('refuses a ref that is not part of the history of the branch that started the run', () => {
    expect(buildJob).toMatch(/git merge-base --is-ancestor HEAD "\$GITHUB_SHA"/);
  });

  it('never interpolates the manual input into a shell command', () => {
    const uses = workflow.match(/\$\{\{\s*(github\.event\.)?inputs\./g) ?? [];

    expect(uses).toHaveLength(1);
  });

  it('documents how to roll back in the README', () => {
    expect(readme).toMatch(/^##+ .*[Rr]ollback/m);
    expect(readme).toContain('Web Deploy GitHub Pages');
    expect(readme).toMatch(/`ref`/);
  });
});
