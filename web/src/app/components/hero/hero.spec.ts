import { TestBed } from '@angular/core/testing';

import { HeroComponent } from './hero';

describe('HeroComponent entrance', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(HeroComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('animates the first viewport with the CSS-only entrance class', () => {
    const heading = root.querySelector('h1');
    expect(heading?.classList.contains('editorial-enter')).toBe(true);
    expect(root.querySelectorAll('.editorial-enter').length).toBe(5);
  });

  it('does not gate the first viewport behind the scroll reveal', () => {
    expect(root.querySelector('.editorial-reveal')).toBeNull();
  });
});
