import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const SRC = resolve(process.cwd(), 'src');

const templates = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return templates(path);
    return path.endsWith('.html') ? [path] : [];
  });

describe('font sizes (UX-13)', () => {
  it('defines the smallest text size once as a theme token', () => {
    const styles = readFileSync(join(SRC, 'styles.css'), 'utf8');

    expect(styles).toMatch(/@theme\s*\{[\s\S]*--text-2xs:\s*[\d.]+rem;[\s\S]*\}/);
  });

  it('uses only theme font sizes in templates, never ad-hoc pixel sizes', () => {
    const adHoc = templates(join(SRC, 'app')).flatMap((file) =>
      (readFileSync(file, 'utf8').match(/(?<![\w-])text-\[[\d.]+(?:px|rem|em)\]/g) ?? []).map(
        (size) => `${file.slice(SRC.length + 1)}: ${size}`,
      ),
    );

    expect(adHoc).toEqual([]);
  });
});
