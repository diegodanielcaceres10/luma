import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { ANALYTICS_CONFIG } from '@core/config/analytics.config';
import { AnalyticsService } from '@core/services/analytics';
import { CONSENT_STORAGE_KEY } from '@core/services/analytics-consent-store';
import { CookieBannerComponent } from './cookie-banner';

describe('CookieBannerComponent', () => {
  let fixture: ComponentFixture<CookieBannerComponent>;
  let analytics: AnalyticsService;

  const banner = () => fixture.nativeElement.querySelector('section');
  const button = (label: string) =>
    Array.from<HTMLButtonElement>(fixture.nativeElement.querySelectorAll('button')).find(
      (el) => el.textContent?.trim() === label,
    );

  const render = async () => {
    fixture = TestBed.createComponent(CookieBannerComponent);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
  };

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        // Disabled so that accepting never injects the Google script into the test page.
        { provide: ANALYTICS_CONFIG, useValue: { measurementId: 'G-TEST', enabled: false } },
      ],
    });
    analytics = TestBed.inject(AnalyticsService);
  });

  afterEach(() => localStorage.clear());

  it('shows the banner with a link to the privacy policy while no choice was made', async () => {
    await render();

    expect(banner()).not.toBeNull();
    expect(banner().querySelector('a')?.getAttribute('href')).toBe('/privacidad');
  });

  it('stores the choice and hides the banner when the visitor accepts', async () => {
    await render();

    button('Aceptar')?.click();
    fixture.detectChanges();

    expect(analytics.consent()).toBe('granted');
    expect(localStorage.getItem(CONSENT_STORAGE_KEY)).toBe('granted');
    expect(banner()).toBeNull();
  });

  it('stores the choice and hides the banner when the visitor rejects', async () => {
    await render();

    button('Rechazar')?.click();
    fixture.detectChanges();

    expect(analytics.consent()).toBe('denied');
    expect(localStorage.getItem(CONSENT_STORAGE_KEY)).toBe('denied');
    expect(banner()).toBeNull();
  });

  it('shows the banner again when the preferences are reopened', async () => {
    await render();
    button('Aceptar')?.click();
    fixture.detectChanges();

    analytics.reopenPreferences();
    fixture.detectChanges();

    expect(banner()).not.toBeNull();
  });

  it('does not render before the first browser render', () => {
    fixture = TestBed.createComponent(CookieBannerComponent);

    expect(banner()).toBeNull();
  });
});
