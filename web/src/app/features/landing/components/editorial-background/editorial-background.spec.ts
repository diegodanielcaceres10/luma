import { TestBed } from '@angular/core/testing';

import { EditorialBackgroundComponent } from './editorial-background';

describe('EditorialBackgroundComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(EditorialBackgroundComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('is hidden from assistive technology because it is purely decorative', () => {
    expect(root.querySelector('.editorial-bg-root')?.getAttribute('aria-hidden')).toBe('true');
  });

  it('does not intercept pointer events over the content', () => {
    expect(root.querySelector('.editorial-bg-root')?.classList).toContain('pointer-events-none');
  });

  it('draws its decorative curves with SVG gradients', () => {
    expect(root.querySelectorAll('linearGradient').length).toBeGreaterThan(0);
  });
});
