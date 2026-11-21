import { TestBed } from '@angular/core/testing';

import { BentoInsightsCardComponent } from './bento-insights-card';

describe('BentoInsightsCardComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(BentoInsightsCardComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('shows its title as a third-level heading', () => {
    expect(root.querySelector('h3')?.textContent?.trim()).toBe('Insights Mensuales');
  });

  it('keeps a single heading so the page outline stays predictable', () => {
    expect(root.querySelectorAll('h1, h2, h3, h4')).toHaveLength(1);
  });
});
