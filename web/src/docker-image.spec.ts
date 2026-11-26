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
    expect(dockerfile.indexOf('npm ci')).toBeLessThan(dockerfile.search(/^COPY\s+(--\S+\s+)*web\/ \./m));
  });

  describe('runtime user', () => {
    const lines = dockerfile.split('\n').map((line) => line.trim());
    const indexOfLine = (pattern: RegExp) => lines.findIndex((line) => pattern.test(line));
    const userLine = indexOfLine(/^USER\s+(?!root\b|0\b)\S+/i);

    it('drops root privileges instead of running the dev server as root', () => {
      expect(userLine).toBeGreaterThan(-1);
    });

    it('switches user before installing dependencies so node_modules is not owned by root', () => {
      expect(userLine).toBeGreaterThan(-1);
      expect(userLine).toBeLessThan(indexOfLine(/^RUN\s+npm ci\b/));
    });

    it('hands the working directory and the Angular cache directory to that user before the switch', () => {
      const chownLine = indexOfLine(/^RUN\s+mkdir\s+\/app\/\.angular\s+&&\s+chown\s+node:node\s+\/app\s+\/app\/\.angular$/);

      expect(chownLine).toBeGreaterThan(-1);
      expect(chownLine).toBeLessThan(userLine);
    });

    it.each(lines.filter((line) => /^COPY\s/.test(line)))(
      'copies files owned by the runtime user: %s',
      (line) => {
        expect(line).toContain('--chown=node:node');
      },
    );

    it('keeps the unprivileged port above 1023', () => {
      expect(Number(/^EXPOSE\s+(\d+)/m.exec(dockerfile)?.[1])).toBeGreaterThanOrEqual(1024);
    });
  });
});

describe('.dockerignore', () => {
  const ignored = existsSync(resolve(root, '.dockerignore'))
    ? read('.dockerignore')
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith('#'))
    : [];

  it.each([
    '**/node_modules',
    'web/dist',
    'web/coverage',
    'web/.angular',
    '.git',
    '**/.env*',
    '**/*.log',
  ])(
    'keeps %s out of the build context',
    (entry) => {
      expect(ignored).toContain(entry);
    },
  );
});

describe('docker-compose.yml', () => {
  const compose = read('docker-compose.yml');

  it('keeps the Angular cache in a container volume because a bind-mounted /app is not writable by the node user', () => {
    expect(compose).toMatch(/^\s+- \/app\/\.angular\s*$/m);
  });

  it('keeps node_modules in a container volume so host dependencies never shadow the installed ones', () => {
    expect(compose).toMatch(/^\s+- \/app\/node_modules\s*$/m);
  });
});
