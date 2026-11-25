import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const APP = resolve(process.cwd(), 'src/app');
/** 44 px is the recommended minimum touch target size; Tailwind's min-h-11 is 2.75rem. */
const MIN_TOUCH_CLASS = 'min-h-11';

const read = (file: string) => readFileSync(join(APP, file), 'utf8');

const files = (dir: string, extension: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return files(path, extension);
    return path.endsWith(extension) && !path.endsWith('.spec.ts') ? [path] : [];
  });

/** Opening tags of the given elements, whose class attribute or class binding must reach 44 px. */
const openingTags = (source: string, elements: string[]): string[] =>
  elements.flatMap((element) => source.match(new RegExp(`<${element}\\b[^>]*>`, 'g')) ?? []);

describe('touch targets (UX-15)', () => {
  it('gives every button a 44px minimum height', () => {
    const tooSmall = files(APP, '.html').flatMap((file) =>
      openingTags(readFileSync(file, 'utf8'), ['button'])
        // Tab buttons that take their classes from a component constant are checked below.
        .filter((tag) => !tag.includes(MIN_TOUCH_CLASS) && !tag.includes('tabClasses()'))
        .map((tag) => `${file.slice(APP.length + 1)}: ${tag.replace(/\s+/g, ' ').slice(0, 70)}`),
    );

    expect(tooSmall).toEqual([]);
  });

  it('gives the experience tabs a 44px minimum height', () => {
    const source = read('features/landing/components/experience-tabs/experience-tabs.ts');
    const base = /const TAB_BASE_CLASSES =\s*'([^']*)'/.exec(source)?.[1] ?? '';

    expect(base).toContain(MIN_TOUCH_CLASS);
  });

  it('gives the footer links and button a 44px minimum height', () => {
    const tags = openingTags(read('shared/components/footer/footer.html'), ['a', 'button']);

    expect(tags.length).toBeGreaterThan(0);
    expect(tags.filter((tag) => !tag.includes(MIN_TOUCH_CLASS))).toEqual([]);
  });

  it('gives the brand link of the navbar a 44px minimum height', () => {
    const brand = openingTags(read('shared/components/navbar/navbar.html'), ['a']).find((tag) =>
      tag.includes('routerLink="/"'),
    );

    expect(brand).toContain(MIN_TOUCH_CLASS);
  });

  it('gives the standalone privacy link of the AI section a 44px minimum height', () => {
    const link = openingTags(read('features/landing/components/gemini-section/gemini-section.html'), ['a']).find(
      (tag) => tag.includes('routerLink="/privacidad"'),
    );

    expect(link).toContain(MIN_TOUCH_CLASS);
  });
});
