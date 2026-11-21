import { TestBed } from '@angular/core/testing';

import { StackSectionComponent } from './stack-section';

describe('StackSectionComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(StackSectionComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('keeps the section anchor used by the navigation', () => {
    expect(root.querySelector('section#stack')).not.toBeNull();
  });

  it('shows the four technology logos', () => {
    const sources = Array.from(root.querySelectorAll('img')).map((img) => img.getAttribute('src'));

    expect(sources).toEqual([
      'stack/flutter.webp',
      'stack/supabase.webp',
      'stack/postgresql.webp',
      'stack/angular.webp',
    ]);
  });

  it('gives every logo explicit dimensions to avoid layout shifts', () => {
    const images = Array.from(root.querySelectorAll('img'));

    expect(images.every((img) => img.hasAttribute('width') && img.hasAttribute('height'))).toBe(true);
  });
});
