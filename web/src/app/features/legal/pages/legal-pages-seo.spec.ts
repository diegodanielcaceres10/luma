import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { routes } from '../../../app.routes';
import { SITE_URL } from '@core/config/site.config';
import { PageUrlService } from '@core/services/page-url';

describe('Legal pages SEO metadata', () => {
  const canonical = () => document.head.querySelector('link[rel="canonical"]')?.getAttribute('href');
  let router: Router;

  beforeEach(() => {
    document.head.querySelectorAll('link[rel="canonical"]').forEach((el) => el.remove());
    TestBed.configureTestingModule({ providers: [provideRouter(routes)] });
    router = TestBed.inject(Router);
    TestBed.inject(PageUrlService).init();
  });

  it('points the privacy policy to its own URL and title', async () => {
    await router.navigateByUrl('/privacidad');

    expect(canonical()).toBe(`${SITE_URL}privacidad/`);
    expect(document.title).toBe('Política de privacidad — Luma');
  });

  it('points the terms of service to its own URL and title', async () => {
    await router.navigateByUrl('/condiciones');

    expect(canonical()).toBe(`${SITE_URL}condiciones/`);
    expect(document.title).toBe('Condiciones del servicio — Luma');
  });

  it('restores the home title when navigating back', async () => {
    await router.navigateByUrl('/privacidad');
    await router.navigateByUrl('/');

    expect(canonical()).toBe(SITE_URL);
    expect(document.title).toBe('Luma — Finanzas personales simples');
  });
});
