import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const readJson = (path: string) => JSON.parse(readFileSync(resolve(process.cwd(), path), 'utf8'));

const pkg = readJson('package.json') as { private?: boolean; license?: string };
const lock = readJson('package-lock.json') as { packages: Record<string, { license?: string }> };

describe('package metadata', () => {
  it('is private, so no open-source license applies by default', () => {
    expect(pkg.private).toBe(true);
  });

  it('declares its license explicitly instead of leaving the field out', () => {
    expect(pkg.license).toBe('UNLICENSED');
  });

  it('mirrors the license in the lockfile root entry', () => {
    expect(lock.packages['']?.license).toBe('UNLICENSED');
  });
});
