import { nextTabIndex } from './tabs-keyboard';

describe('nextTabIndex', () => {
  it('moves forward with ArrowRight and wraps from the last tab to the first', () => {
    expect(nextTabIndex('ArrowRight', 0, 3)).toBe(1);
    expect(nextTabIndex('ArrowRight', 2, 3)).toBe(0);
  });

  it('moves backward with ArrowLeft and wraps from the first tab to the last', () => {
    expect(nextTabIndex('ArrowLeft', 2, 3)).toBe(1);
    expect(nextTabIndex('ArrowLeft', 0, 3)).toBe(2);
  });

  it('jumps to the first and last tabs with Home and End', () => {
    expect(nextTabIndex('Home', 2, 3)).toBe(0);
    expect(nextTabIndex('End', 0, 3)).toBe(2);
  });

  it('returns null for keys that do not navigate tabs', () => {
    expect(nextTabIndex('Enter', 1, 3)).toBeNull();
    expect(nextTabIndex('a', 1, 3)).toBeNull();
  });
});
