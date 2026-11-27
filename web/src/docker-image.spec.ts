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

  describe('entrypoint', () => {
    it('starts through an exec-form ENTRYPOINT so the container does not hardcode what it runs', () => {
      expect(dockerfile).toMatch(/^ENTRYPOINT\s+\["\/usr\/local\/bin\/docker-entrypoint\.sh"\]\s*$/m);
    });

    it('does not set a CMD that bypasses the environment choice', () => {
      expect(dockerfile).not.toMatch(/^CMD\b/m);
    });

    it('installs the script as root-owned and executable, independent of git file modes on Windows', () => {
      expect(dockerfile).toMatch(
        /^COPY\s+docker\/web\/docker-entrypoint\.sh\s+\/usr\/local\/bin\/docker-entrypoint\.sh\s*$/m,
      );
      expect(dockerfile).toMatch(/^RUN\s+chmod\s+\+x\s+\/usr\/local\/bin\/docker-entrypoint\.sh\s*$/m);
    });
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

    it.each(lines.filter((line) => /^COPY\s/.test(line) && !line.includes('docker-entrypoint.sh')))(
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

  it('publishes the host port from WEB_PORT so each machine can avoid its own port conflicts', () => {
    expect(compose).toMatch(/^\s+- "\$\{WEB_PORT:-4200\}:4200"\s*$/m);
  });

  it('passes APP_ENV to the container with local as the default', () => {
    expect(compose).toMatch(/^\s+APP_ENV: \$\{APP_ENV:-local\}\s*$/m);
  });

  it('keeps node_modules in a container volume so host dependencies never shadow the installed ones', () => {
    expect(compose).toMatch(/^\s+- \/app\/node_modules\s*$/m);
  });

  describe('healthcheck', () => {
    const block = /^ {4}healthcheck:\n((?: {6,}.*\n?)+)/m.exec(compose)?.[1] ?? '';

    it('declares a healthcheck so Docker can tell when the dev server is not responding', () => {
      expect(block).not.toBe('');
    });

    it('probes the port the Dockerfile exposes', () => {
      const exposed = /^EXPOSE\s+(\d+)/m.exec(dockerfile)?.[1];

      expect(block).toContain(`http://127.0.0.1:${exposed}/`);
    });

    it('allows a start period long enough for the first compilation', () => {
      const seconds = Number(/start_period:\s*(\d+)s/.exec(block)?.[1]);

      expect(seconds).toBeGreaterThanOrEqual(30);
    });
  });
});

describe('.env.example', () => {
  const compose = read('docker-compose.yml');
  const example = existsSync(resolve(root, '.env.example')) ? read('.env.example') : '';
  const documented = new Map(
    example
      .split('\n')
      .map((line) => /^([A-Z][A-Z0-9_]*)=(.*)$/.exec(line))
      .filter((match): match is RegExpExecArray => match !== null)
      .map((match) => [match[1] ?? '', match[2] ?? '']),
  );
  const used = [...compose.matchAll(/\$\{([A-Z][A-Z0-9_]*)(?::-([^}]*))?\}/g)];

  it('exists next to docker-compose.yml', () => {
    expect(example).not.toBe('');
  });

  it('documents every variable that docker-compose.yml reads', () => {
    expect(used.length).toBeGreaterThan(0);
    expect(used.filter((match) => !documented.has(match[1] ?? '')).map((match) => match[1])).toEqual([]);
  });

  it('shows the same default values that docker-compose.yml falls back to', () => {
    const mismatched = used
      .filter((match) => match[2] !== undefined && documented.get(match[1] ?? '') !== match[2])
      .map((match) => match[1]);

    expect(mismatched).toEqual([]);
  });
});

describe('root .gitignore', () => {
  const entries = existsSync(resolve(root, '.gitignore'))
    ? read('.gitignore')
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith('#'))
    : [];

  it('ignores the local .env so port and environment overrides are never committed', () => {
    expect(entries).toContain('.env*');
  });

  it('keeps .env.example trackable', () => {
    expect(entries.indexOf('!.env.example')).toBeGreaterThan(entries.indexOf('.env*'));
  });
});

describe('.gitattributes', () => {
  it('forces LF endings on Docker shell scripts because CRLF breaks them inside Linux containers', () => {
    const attributes = existsSync(resolve(root, '.gitattributes')) ? read('.gitattributes') : '';

    expect(attributes).toMatch(/^docker\/\*\*\/\*\.sh\s+text\s+eol=lf\s*$/m);
  });
});
