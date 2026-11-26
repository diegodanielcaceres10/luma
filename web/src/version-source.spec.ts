import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

import { TestBed } from '@angular/core/testing';

import { APP_VERSION } from '@core/config/app-version';

const SEMVER = /^(\d+)\.(\d+)\.(\d+)(?:-[0-9A-Za-z.-]+)?$/;
const pubspec = readFileSync(resolve(process.cwd(), '..', 'app/pubspec.yaml'), 'utf8');
// Flutter appends an optional build number ("3.3.0+12"); the web only shows the release part.
const pubspecVersion = /^version:\s*([^\s+#]+)/m.exec(pubspec)?.[1] ?? '';

const templates = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return templates(path);
    return entry.name.endsWith('.html') ? [path] : [];
  });

describe('product version', () => {
  const version = TestBed.inject(APP_VERSION);

  it('is a valid semver that is not the 0.0.0 placeholder', () => {
    expect(version).toMatch(SEMVER);
    expect(version).not.toBe('0.0.0');
  });

  it('matches the version declared in app/pubspec.yaml, the release source of truth', () => {
    expect(pubspecVersion).not.toBe('');
    expect(version).toBe(pubspecVersion);
  });

  it('is not hardcoded in any template', () => {
    const offenders = templates(resolve(process.cwd(), 'src/app')).filter((file) =>
      /\bv\s?\d+\.\d+\.\d+/.test(readFileSync(file, 'utf8')),
    );

    expect(offenders).toEqual([]);
  });
});
