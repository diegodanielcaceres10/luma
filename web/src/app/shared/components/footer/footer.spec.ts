import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { AnalyticsService } from '@core/services/analytics';
import { FooterComponent } from './footer';

describe('FooterComponent', () => {
  let fixture: ComponentFixture<FooterComponent>;
  let root: HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    fixture = TestBed.createComponent(FooterComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('links to the legal pages', () => {
    const hrefs = Array.from(root.querySelectorAll('a')).map((a) => a.getAttribute('href'));

    expect(hrefs).toContain('/privacidad');
    expect(hrefs).toContain('/condiciones');
  });

  it('opens external links safely in a new tab', () => {
    const external = Array.from(root.querySelectorAll<HTMLAnchorElement>('a[target="_blank"]'));

    expect(external.length).toBeGreaterThan(0);
    expect(external.every((a) => a.rel.includes('noopener'))).toBe(true);
  });

  it('shows the current year in the copyright line', () => {
    expect(root.textContent).toContain(`© ${new Date().getFullYear()}`);
  });

  it('reopens the cookie preferences from its button', () => {
    const analytics = TestBed.inject(AnalyticsService);
    analytics.reject();
    expect(analytics.consent()).toBe('denied');

    Array.from(root.querySelectorAll('button'))
      .find((el) => el.textContent?.includes('Preferencias de cookies'))
      ?.click();

    expect(analytics.consent()).toBe('unknown');
    localStorage.clear();
  });
});
