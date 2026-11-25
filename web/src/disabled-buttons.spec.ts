import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const styles = readFileSync(resolve(process.cwd(), 'src/styles.css'), 'utf8');

/** Declarations of the first rule whose selector is exactly `button:disabled`. */
const disabledButtonRule = (): string => /(?:^|\})\s*button:disabled\s*\{([^}]*)\}/m.exec(styles)?.[1] ?? '';

describe('disabled button state (UX-12)', () => {
  it('styles every disabled button in one place', () => {
    expect(disabledButtonRule()).not.toBe('');
  });

  it('dims a disabled button', () => {
    expect(disabledButtonRule()).toMatch(/opacity:\s*0?\.\d+/);
  });

  it('shows that a disabled button cannot be used', () => {
    expect(disabledButtonRule()).toMatch(/cursor:\s*not-allowed/);
  });
});
