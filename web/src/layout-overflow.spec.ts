import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const read = (file: string) => readFileSync(resolve(process.cwd(), file), 'utf8');

/** Returns the declaration block of the first rule whose selector is exactly `selector`. */
const ruleBody = (css: string, selector: string): string => {
  const match = new RegExp(`(?:^|\\})\\s*${selector}\\s*\\{([^}]*)\\}`, 'm').exec(css);
  return match?.[1] ?? '';
};

describe('horizontal overflow handling (UX-05)', () => {
  it('does not hide horizontal overflow on the body', () => {
    const body = ruleBody(read('src/styles.css'), 'body');

    expect(body).not.toBe('');
    expect(body).not.toMatch(/overflow(-x)?\s*:\s*hidden/);
  });

  it('does not hide horizontal overflow on the home page root', () => {
    const root = read('src/app/features/landing/pages/home/home.html').split('\n')[0] ?? '';

    expect(root).not.toMatch(/\boverflow-x-hidden\b/);
  });
});
