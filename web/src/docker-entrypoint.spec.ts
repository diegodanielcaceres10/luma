import { spawnSync } from 'node:child_process';
import { chmodSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const script = resolve(process.cwd(), '..', 'docker/web/docker-entrypoint.sh');
const source = existsSync(script) ? readFileSync(script, 'utf8') : '';
const hasShell = process.platform !== 'win32' && spawnSync('sh', ['-c', 'true']).status === 0;

describe('docker-entrypoint.sh', () => {
  it('exists in the repository', () => {
    expect(existsSync(script)).toBe(true);
  });

  it('is a POSIX shell script that stops on errors and unset variables', () => {
    expect(source.startsWith('#!/bin/sh\n')).toBe(true);
    expect(source).toMatch(/^set -eu$/m);
  });

  it('uses LF line endings', () => {
    expect(source).not.toContain('\r');
  });

  it('hands over to the final command with exec so it receives the container signals', () => {
    expect(source).toMatch(/^\s*exec npm start$/m);
    expect(source).toMatch(/^\s*exec npm run build$/m);
  });

  it('goes through the npm scripts instead of calling the Angular CLI directly', () => {
    expect(source).not.toMatch(/\bnpx\b|\bng (serve|build)\b/);
  });

  describe.skipIf(!hasShell)('when executed', () => {
    const bin = mkdtempSync(join(tmpdir(), 'entrypoint-'));
    const fakeNpm = join(bin, 'npm');

    beforeAll(() => {
      writeFileSync(fakeNpm, '#!/bin/sh\necho "npm $*"\n');
      chmodSync(fakeNpm, 0o755);
    });

    afterAll(() => rmSync(bin, { recursive: true, force: true }));

    const run = (appEnv?: string) =>
      spawnSync('sh', [script], {
        encoding: 'utf8',
        env: { PATH: `${bin}:${process.env['PATH'] ?? ''}`, ...(appEnv === undefined ? {} : { APP_ENV: appEnv }) },
      });

    it('starts the dev server when APP_ENV is local', () => {
      expect(run('local').stdout.trim()).toBe('npm start');
    });

    it('defaults to local when APP_ENV is not defined', () => {
      expect(run().stdout.trim()).toBe('npm start');
    });

    it.each(['dev', 'staging', 'prod'])('builds the application when APP_ENV is %s', (appEnv) => {
      expect(run(appEnv).stdout.trim()).toBe('npm run build');
    });

    it('fails without running npm when APP_ENV is not a known environment', () => {
      const result = run('prd');

      expect(result.status).toBe(1);
      expect(result.stdout).toBe('');
      expect(result.stderr).toContain("unsupported APP_ENV 'prd'");
    });
  });
});
