import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const SRC = resolve(process.cwd(), 'src');

const filesWithExtension = (dir: string, extension: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return filesWithExtension(path, extension);
    return path.endsWith(extension) ? [path] : [];
  });

/** Returns the body of every `@media (prefers-reduced-motion: reduce)` block, matching braces. */
const reducedMotionBlocks = (css: string): string => {
  const marker = '@media (prefers-reduced-motion: reduce)';
  let result = '';
  let from = css.indexOf(marker);
  while (from !== -1) {
    const open = css.indexOf('{', from);
    let depth = 1;
    let index = open + 1;
    while (depth > 0 && index < css.length) {
      depth += css[index] === '{' ? 1 : css[index] === '}' ? -1 : 0;
      index++;
    }
    result += css.slice(open + 1, index - 1);
    from = css.indexOf(marker, index);
  }
  return result;
};

describe('reduced motion', () => {
  it('turns off every Tailwind animation utility used in templates', () => {
    const offenders: string[] = [];

    for (const file of filesWithExtension(SRC, '.html')) {
      const html = readFileSync(file, 'utf8');
      for (const [, classes = ''] of html.matchAll(/class="([^"]*)"/g)) {
        const animated = /(?:^|\s)animate-(?!none\b)[a-z-]+/.test(classes);
        if (animated && !classes.includes('motion-reduce:animate-none')) {
          offenders.push(`${file.replace(SRC, 'src')}: ${classes.trim().slice(0, 80)}`);
        }
      }
    }

    expect(offenders).toEqual([]);
  });

  it('disables every infinite CSS animation inside a prefers-reduced-motion block', () => {
    const offenders: string[] = [];

    for (const file of filesWithExtension(SRC, '.css')) {
      const css = readFileSync(file, 'utf8');
      const reduced = reducedMotionBlocks(css);

      for (const [, selectors = '', body = ''] of css.matchAll(/([^{}@]+)\{([^{}]*)\}/g)) {
        if (!/animation\s*:[^;]*\binfinite\b/.test(body)) continue;
        for (const selector of selectors.split(',').map((item) => item.trim())) {
          if (!reduced.includes(selector)) offenders.push(`${file.replace(SRC, 'src')}: ${selector}`);
        }
      }
    }

    expect(offenders).toEqual([]);
  });
});
