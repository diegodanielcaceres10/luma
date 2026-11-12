import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { SITE_URL } from '../config/site.config';
import { PrivacyPolicy } from './privacy-policy/privacy-policy';
import { TermsOfService } from './terms-of-service/terms-of-service';

describe('Legal pages canonical URL', () => {
  const canonical = () => document.head.querySelector('link[rel="canonical"]')?.getAttribute('href');

  beforeEach(() => {
    document.head.querySelectorAll('link[rel="canonical"]').forEach((el) => el.remove());
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
  });

  it('points the privacy policy to its own URL', () => {
    TestBed.createComponent(PrivacyPolicy);

    expect(canonical()).toBe(`${SITE_URL}privacidad/`);
  });

  it('points the terms of service to its own URL', () => {
    TestBed.createComponent(TermsOfService);

    expect(canonical()).toBe(`${SITE_URL}condiciones/`);
  });
});
