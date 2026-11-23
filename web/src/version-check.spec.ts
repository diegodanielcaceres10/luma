import { execFileSync, spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const script = resolve(process.cwd(), 'scripts/check-version.mjs');

const git = (cwd: string, ...args: string[]) =>
  execFileSync('git', ['-c', 'user.name=ci', '-c', 'user.email=ci@example.com', ...args], { cwd, stdio: 'pipe' });

const writeVersion = (repo: string, version: string) =>
  writeFileSync(join(repo, 'web', 'package.json'), JSON.stringify({ name: 'web', version }));

describe('PR version check (scripts/check-version.mjs)', () => {
  let repo: string;

  /** Commits `base` on the base branch, then `head` on top of it, and runs the check against the base. */
  const check = (base: string, head: string) => {
    writeVersion(repo, base);
    git(repo, 'add', '.');
    git(repo, 'commit', '-m', 'base');
    git(repo, 'branch', 'base');
    writeVersion(repo, head);
    return spawnSync('node', [script, 'base'], { cwd: join(repo, 'web'), encoding: 'utf8' });
  };

  beforeEach(() => {
    repo = mkdtempSync(join(tmpdir(), 'version-check-'));
    mkdirSync(join(repo, 'web'));
    git(repo, 'init', '-q');
  });

  afterEach(() => rmSync(repo, { recursive: true, force: true }));

  it.each([
    ['patch', '1.2.3', '1.2.4'],
    ['minor', '1.2.3', '1.3.0'],
    ['major', '1.2.3', '2.0.0'],
    ['numeric (not lexical) comparison', '3.9.0', '3.10.0'],
    ['release over its own prerelease', '1.0.0-rc.1', '1.0.0'],
    ['numeric prerelease identifiers', '1.0.0-rc.2', '1.0.0-rc.10'],
  ])('passes when the version increases: %s', (_name, base, head) => {
    const result = check(base, head);

    expect(result.status).toBe(0);
    expect(result.stdout).toContain(head);
  });

  it.each([
    ['is unchanged', '1.2.3', '1.2.3'],
    ['is lower (patch)', '1.2.3', '1.2.2'],
    ['is lower (major)', '2.0.0', '1.9.9'],
    ['only changes build metadata', '1.2.3+a', '1.2.3+b'],
    ['moves from a release to a prerelease', '1.0.0', '1.0.0-rc.1'],
  ])('fails when the version %s', (_name, base, head) => {
    const result = check(base, head);

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('must be greater');
  });

  it('fails with a clear message when the version is not valid semver', () => {
    const result = check('1.2.3', 'next');

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('not a valid semver');
  });

  it('fails when the base reference does not exist', () => {
    writeVersion(repo, '1.0.0');
    git(repo, 'add', '.');
    git(repo, 'commit', '-m', 'base');

    const result = spawnSync('node', [script, 'missing-branch'], { cwd: join(repo, 'web'), encoding: 'utf8' });

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('missing-branch');
  });

  it('asks for the base reference when none is given', () => {
    const result = spawnSync('node', [script], { cwd: repo, encoding: 'utf8' });

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('Usage');
  });
});
