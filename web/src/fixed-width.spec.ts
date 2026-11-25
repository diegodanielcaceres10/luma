import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const APP = resolve(process.cwd(), 'src/app');
const MIN_RISKY_WIDTH_PX = 600;

const templates = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return templates(path);
    return path.endsWith('.html') ? [path] : [];
  });

/** Class attributes that fix a width of 600 px or more without any max-width cap. */
const uncappedWideElements = (): string[] =>
  templates(APP).flatMap((file) =>
    [...readFileSync(file, 'utf8').matchAll(/class="([^"]*)"/g)]
      .map(([, classes = '']) => classes)
      .filter((classes) => {
        const fixed = [...classes.matchAll(/(?<![\w-])w-\[(\d+)px\]/g)].map(([, px = '0']) => Number(px));
        return fixed.some((px) => px >= MIN_RISKY_WIDTH_PX) && !/(?<![\w-])max-w-/.test(classes);
      })
      .map((classes) => `${file.slice(APP.length + 1)}: ${classes.slice(0, 60)}`),
  );

describe('fixed widths on narrow screens (UX-01)', () => {
  it('caps every fixed width of 600 px or more with a max-width', () => {
    expect(uncappedWideElements()).toEqual([]);
  });
});
