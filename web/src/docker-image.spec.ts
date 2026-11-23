import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');

const dockerfile = read('docker/web/Dockerfile');
const baseImage = /^FROM\s+node:(\S+)/m.exec(dockerfile)?.[1] ?? '';
const nvmrcMajor = read('web/.nvmrc').trim().replace(/^v/, '').split('.')[0];

describe('web Dockerfile', () => {
  it('builds on the same Node major version that .nvmrc pins for local and CI runs', () => {
    expect(baseImage.split(/[.-]/)[0]).toBe(nvmrcMajor);
  });

  it('uses a Debian variant that the official Node images still publish', () => {
    expect(baseImage).not.toContain('bullseye');
    expect(baseImage).toMatch(/-(bookworm|trixie)(-slim)?$/);
  });

  it('skips the Cypress binary download because end-to-end tests do not run in the image', () => {
    expect(dockerfile).toMatch(/^ENV\s+CYPRESS_INSTALL_BINARY=0\s*$/m);
  });

  it('installs dependencies from the lockfile before copying the sources', () => {
    expect(dockerfile.indexOf('npm ci')).toBeGreaterThan(-1);
    expect(dockerfile.indexOf('npm ci')).toBeLessThan(dockerfile.indexOf('COPY web/ .'));
  });
});

describe('.dockerignore', () => {
  const ignored = existsSync(resolve(root, '.dockerignore'))
    ? read('.dockerignore')
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith('#'))
    : [];

  it.each(['**/node_modules', 'web/dist', 'web/coverage', 'web/.angular', '.git'])(
    'keeps %s out of the build context',
    (entry) => {
      expect(ignored).toContain(entry);
    },
  );
});
