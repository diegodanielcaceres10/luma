import { TestBed } from '@angular/core/testing';

import { CtaBannerComponent } from './cta-banner';

describe('CtaBannerComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(CtaBannerComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('invites the visitor to try the product in its main heading', () => {
    expect(root.querySelector('h2')?.textContent).toContain('Tu patrimonio merece una herramienta');
  });

  it('links to the portfolio and the repository', () => {
    const hrefs = Array.from(root.querySelectorAll('a')).map((a) => a.getAttribute('href'));

    expect(hrefs).toEqual([
      'https://diegodanielcaceres10.github.io/nura',
      'https://github.com/diegodanielcaceres10/luma',
    ]);
  });

  it('opens its external links safely in a new tab', () => {
    const links = Array.from(root.querySelectorAll<HTMLAnchorElement>('a'));

    expect(links.every((a) => a.target === '_blank' && a.rel.includes('noopener'))).toBe(true);
  });
});
