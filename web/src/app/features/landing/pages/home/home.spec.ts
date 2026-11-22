import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { ANALYTICS_CONFIG } from '@core/config/analytics.config';
import { MotionPreferencesService } from '@core/services/motion-preferences';
import { Home } from './home';

describe('Home scroll reveal', () => {
  const render = async (reducedMotion: boolean) => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        { provide: ANALYTICS_CONFIG, useValue: { measurementId: 'G-TEST123', enabled: false } },
        { provide: MotionPreferencesService, useValue: { prefersReducedMotion: () => reducedMotion } },
      ],
    });
    const fixture = TestBed.createComponent(Home);
    await fixture.whenStable();
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  };

  const revealable = (root: HTMLElement) =>
    root.querySelectorAll('.editorial-reveal, .editorial-reveal-scale, .editorial-stat-reveal');

  afterEach(() => localStorage.clear());

  it('reveals every animated element at once when the user prefers reduced motion', async () => {
    const root = await render(true);
    const elements = Array.from(revealable(root));

    expect(elements.length).toBeGreaterThan(0);
    expect(elements.every((el) => el.classList.contains('is-revealed'))).toBe(true);
  });
});

describe('Home skip link target', () => {
  it('exposes the main landmark as the skip link target', async () => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        { provide: ANALYTICS_CONFIG, useValue: { measurementId: 'G-TEST123', enabled: false } },
      ],
    });
    const fixture = TestBed.createComponent(Home);
    await fixture.whenStable();
    fixture.detectChanges();
    const main = (fixture.nativeElement as HTMLElement).querySelector('main');

    expect(main?.id).toBe('main-content');
    expect(main?.getAttribute('tabindex')).toBe('-1');
  });
});
