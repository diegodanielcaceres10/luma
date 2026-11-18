import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';

const APP_DIR = resolve(process.cwd(), 'src/app');
const ALIASES: Record<string, string> = {
  '@core/': 'core',
  '@shared/': 'shared',
  '@features/': 'features',
};
const IMPORT_PATTERN = /(?:from|import)\s*\(?\s*'([^']+)'/g;

interface Area {
  layer: string;
  feature?: string;
}

interface Edge {
  file: string;
  specifier: string;
  from: Area;
  to: Area;
}

/** Maps a path relative to `src/app` to its layer and, inside `features/`, its feature. */
const areaOf = (path: string): Area => {
  const [layer, feature] = path.split(sep);
  return layer === 'features' ? { layer, feature } : { layer: ['core', 'shared'].includes(layer) ? layer : 'shell' };
};

const sourceFiles = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return sourceFiles(path);
    return entry.name.endsWith('.ts') ? [path] : [];
  });

/** Resolves an import to a path relative to `src/app`, or null for packages and files outside the app. */
const resolveInternal = (file: string, specifier: string): string | null => {
  const alias = Object.keys(ALIASES).find((prefix) => specifier.startsWith(prefix));
  const absolute = alias
    ? join(APP_DIR, ALIASES[alias], specifier.slice(alias.length))
    : specifier.startsWith('.')
      ? resolve(dirname(file), specifier)
      : null;
  if (!absolute) return null;
  const path = relative(APP_DIR, absolute);
  return path.startsWith('..') ? null : path;
};

const edges: Edge[] = sourceFiles(APP_DIR).flatMap((file) => {
  const from = areaOf(relative(APP_DIR, file));
  const source = readFileSync(file, 'utf8');
  return [...source.matchAll(IMPORT_PATTERN)].flatMap(([, specifier]) => {
    const target = resolveInternal(file, specifier);
    return target === null
      ? []
      : [{ file: relative(APP_DIR, file), specifier, from, to: areaOf(target) }];
  });
});

const crossesArea = ({ from, to }: Edge) => from.layer !== to.layer || from.feature !== to.feature;
const describe_ = (edge: Edge) => `${edge.file} -> ${edge.specifier}`;

describe('architecture', () => {
  it('analyzes the application imports', () => {
    expect(edges.length).toBeGreaterThan(20);
  });

  it('keeps core independent of shared and features', () => {
    const violations = edges.filter(({ from, to }) => from.layer === 'core' && to.layer !== 'core');

    expect(violations.map(describe_)).toEqual([]);
  });

  it('lets shared depend only on core and shared', () => {
    const violations = edges.filter(
      ({ from, to }) => from.layer === 'shared' && !['core', 'shared'].includes(to.layer),
    );

    expect(violations.map(describe_)).toEqual([]);
  });

  it('keeps features from importing other features', () => {
    const violations = edges.filter(
      ({ from, to }) => from.layer === 'features' && to.layer === 'features' && from.feature !== to.feature,
    );

    expect(violations.map(describe_)).toEqual([]);
  });

  it('imports across layers and features through path aliases', () => {
    const violations = edges.filter(
      (edge) => crossesArea(edge) && edge.to.layer !== 'shell' && !edge.specifier.startsWith('@'),
    );

    expect(violations.map(describe_)).toEqual([]);
  });

  it('uses relative imports inside the same layer or feature', () => {
    const violations = edges.filter((edge) => !crossesArea(edge) && edge.specifier.startsWith('@'));

    expect(violations.map(describe_)).toEqual([]);
  });
});
