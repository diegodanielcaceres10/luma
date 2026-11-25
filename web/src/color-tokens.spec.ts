import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const SRC = resolve(process.cwd(), 'src');
const LITERAL_COLOR =
  /#(?:[0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{4}|[0-9a-f]{3})(?![0-9a-f])|rgba?\([^)]*\)|hsla?\([^)]*\)/gi;

const filesIn = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return filesIn(path);
    return /\.(css|html|ts)$/.test(path) && !path.endsWith('.spec.ts') ? [path] : [];
  });

const normalize = (color: string) => color.toLowerCase().replace(/\s+/g, '');

const styles = readFileSync(join(SRC, 'styles.css'), 'utf8');
const themeBlock = /@theme\s*\{[\s\S]*?\n\}/.exec(styles)?.[0] ?? '';

/** Literal colors outside the @theme tokens, ignoring font ranges and embedded data URIs. */
const literalsOutsideTheme = (): string[] =>
  filesIn(SRC).flatMap((file) => {
    const text = readFileSync(file, 'utf8')
      .replace(file.endsWith('styles.css') && file === join(SRC, 'styles.css') ? themeBlock : '', '')
      .replace(/unicode-range:[^;]*;/g, '')
      .replace(/url\(["']data:[^)]*\)/g, '');
    return (text.match(LITERAL_COLOR) ?? []).map(normalize);
  });

describe('color tokens (UX-14)', () => {
  it('finds the theme tokens and the literal colors it checks', () => {
    expect(themeBlock).toContain('--color-luma-500');
    expect(literalsOutsideTheme().length).toBeGreaterThan(10);
  });

  it('keeps every literal color to a single use; repeated colors belong in @theme', () => {
    const counts = new Map<string, number>();
    literalsOutsideTheme().forEach((color) => counts.set(color, (counts.get(color) ?? 0) + 1));

    const repeated = [...counts].filter(([, count]) => count > 1).map(([color]) => color);

    expect(repeated).toEqual([]);
  });

  it('does not repeat as a literal a color that already has a hex token in @theme', () => {
    const tokens = new Set((themeBlock.match(LITERAL_COLOR) ?? []).map(normalize));

    const duplicated = [...new Set(literalsOutsideTheme())].filter((color) => tokens.has(color));

    expect(duplicated).toEqual([]);
  });
});
