#!/usr/bin/env node
// Fails unless the version in web/package.json is strictly greater than the one on the base ref.
// Usage: node scripts/check-version.mjs <baseRef>   (e.g. origin/main)
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SEMVER = /^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;

function parse(version, label) {
  const match = SEMVER.exec(version);
  if (!match) throw new Error(`${label} version "${version}" is not a valid semver.`);
  return { core: match.slice(1, 4).map(Number), pre: match[4] ? match[4].split('.') : [] };
}

function comparePrerelease(a, b) {
  // A release outranks any of its prereleases.
  if (!a.length || !b.length) return Math.sign(b.length - a.length);
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    if (a[i] === undefined) return -1;
    if (b[i] === undefined) return 1;
    const aNumeric = /^\d+$/.test(a[i]);
    const bNumeric = /^\d+$/.test(b[i]);
    if (aNumeric && bNumeric && Number(a[i]) !== Number(b[i])) return Math.sign(Number(a[i]) - Number(b[i]));
    if (aNumeric !== bNumeric) return aNumeric ? -1 : 1;
    if (!aNumeric && a[i] !== b[i]) return a[i] < b[i] ? -1 : 1;
  }
  return 0;
}

function compare(a, b) {
  for (let i = 0; i < 3; i++) if (a.core[i] !== b.core[i]) return Math.sign(a.core[i] - b.core[i]);
  return comparePrerelease(a.pre, b.pre);
}

function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}

function main() {
  const baseRef = process.argv[2];
  if (!baseRef) throw new Error('Usage: node scripts/check-version.mjs <baseRef>');

  let baseVersion;
  try {
    baseVersion = JSON.parse(git('show', `${baseRef}:web/package.json`)).version;
  } catch {
    throw new Error(`Could not read web/package.json from "${baseRef}". Fetch the base branch first.`);
  }
  const headVersion = JSON.parse(readFileSync(join(git('rev-parse', '--show-toplevel'), 'web', 'package.json'), 'utf8')).version;

  if (compare(parse(headVersion, 'PR'), parse(baseVersion, 'Base')) <= 0) {
    throw new Error(`The PR version (${headVersion}) must be greater than the version on ${baseRef} (${baseVersion}). Bump "version" in web/package.json.`);
  }
  console.log(`Version bump OK: ${baseVersion} -> ${headVersion}`);
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
