import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const webRoot = process.cwd();
const read = (path: string) => readFileSync(resolve(webRoot, path), 'utf8');

const readme = read('README.md');
const scripts = (JSON.parse(read('package.json')) as { scripts: Record<string, string> }).scripts;
const nodeMajor = read('.nvmrc').trim().replace(/^v/, '').split('.')[0];
const headings = readme
  .split('\n')
  .filter((line) => /^#{1,3}\s/.test(line))
  .map((line) => line.replace(/^#+\s*/, '').toLowerCase());

describe('web/README.md', () => {
  it.each([
    ['description', /descripci[oó]n|description/],
    ['requirements', /requisitos|requirements/],
    ['installation', /instalaci[oó]n|installation/],
    ['running and scripts', /ejecuci[oó]n|scripts|running/],
    ['project structure', /estructura|structure/],
    ['deployment', /despliegue|deployment/],
  ])('has a %s section', (_name, pattern) => {
    expect(headings.some((heading) => pattern.test(heading))).toBe(true);
  });

  it.each(['start', 'test', 'lint', 'build'])('documents the %s script', (name) => {
    expect(readme).toMatch(new RegExp(`npm (run )?${name}\\b`));
  });

  it('only cites npm scripts that exist in package.json', () => {
    const cited = [...readme.matchAll(/npm run ([\w:-]+)/g)].map((match) => match[1] ?? '');

    expect(cited.length).toBeGreaterThan(0);
    expect(cited.filter((name) => !(name in scripts))).toEqual([]);
  });

  it('states the Node major version that .nvmrc pins', () => {
    expect(readme).toMatch(new RegExp(`Node(\\.js)?\\s+${nodeMajor}\\b`));
  });

  it('links only to files that exist', () => {
    const links = [...readme.matchAll(/\]\((?!https?:|#|mailto:)([^)\s]+)\)/g)].map((match) => match[1] ?? '');
    const missing = links.filter((link) => !existsSync(resolve(webRoot, link.split('#')[0] ?? '')));

    expect(missing).toEqual([]);
  });

  it('does not keep the Angular CLI boilerplate, which cites a stale CLI version and a missing e2e target', () => {
    expect(readme).not.toContain('generated using');
    expect(readme).not.toContain('ng e2e');
  });
});
