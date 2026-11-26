import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const entries = readFileSync(resolve(process.cwd(), '.gitignore'), 'utf8')
  .split('\n')
  .map((line) => line.trim())
  .filter((line) => line && !line.startsWith('#'));

describe('web/.gitignore', () => {
  it.each(['/dist', '/node_modules', '/.angular/cache', '/coverage'])('ignores generated path %s', (entry) => {
    expect(entries).toContain(entry);
  });

  it('ignores local environment files so secrets are never committed by accident', () => {
    expect(entries).toContain('.env*');
  });

  it('keeps the committed environment template trackable', () => {
    expect(entries.indexOf('!.env.example')).toBeGreaterThan(entries.indexOf('.env*'));
  });
});
