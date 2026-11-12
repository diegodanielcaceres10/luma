import { Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { CookieBannerComponent } from './components/cookie-banner/cookie-banner';
import { ANALYTICS_CONFIG } from './config/analytics.config';
import { PrivacyPolicy } from './pages/privacy-policy/privacy-policy';
import { TermsOfService } from './pages/terms-of-service/terms-of-service';

/** Regional second-person forms and words that the site copy must avoid. */
const REGIONAL_FORMS =
  /\b(vos|aceptás|podés|tenés|usás|cargás|elegís|pedís|enviás|sos|cargá|pedí|elegí|liviana|liviano)\b/i;

describe('Neutral Spanish copy', () => {
  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({
      providers: [
        provideRouter([]),
        { provide: ANALYTICS_CONFIG, useValue: { measurementId: 'G-TEST123', enabled: false } },
      ],
    });
  });

  afterEach(() => localStorage.clear());

  const renderedText = async (component: Type<unknown>) => {
    const fixture = TestBed.createComponent(component);
    await fixture.whenStable();
    fixture.detectChanges();
    return (fixture.nativeElement as HTMLElement).textContent ?? '';
  };

  it.each([
    ['cookie banner', CookieBannerComponent],
    ['privacy policy', PrivacyPolicy],
    ['terms of service', TermsOfService],
  ])('%s has no regional forms', async (_name, component) => {
    const text = await renderedText(component);

    expect(text.length).toBeGreaterThan(100);
    expect(text).not.toMatch(REGIONAL_FORMS);
  });
});
