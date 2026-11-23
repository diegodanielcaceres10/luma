import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { routes } from '../../../app.routes';
import { SITE_URL } from '@core/config/site.config';
import { PageMetaService } from '@core/services/page-meta';
import { PageUrlService } from '@core/services/page-url';

describe('Legal pages SEO metadata', () => {
  const meta = (selector: string) => document.head.querySelector(selector)?.getAttribute('content');
  const canonical = () => document.head.querySelector('link[rel="canonical"]')?.getAttribute('href');
  let router: Router;

  beforeEach(() => {
    document.head.querySelectorAll('link[rel="canonical"]').forEach((el) => el.remove());
    TestBed.configureTestingModule({ providers: [provideRouter(routes)] });
    router = TestBed.inject(Router);
    TestBed.inject(PageUrlService).init();
    TestBed.inject(PageMetaService).init();
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

  it('gives the privacy policy its own description and social tags', async () => {
    await router.navigateByUrl('/privacidad');

    expect(meta('meta[name="description"]')).toContain('datos');
    expect(meta('meta[property="og:title"]')).toBe('Política de privacidad — Luma');
    expect(meta('meta[property="og:description"]')).toBe(meta('meta[name="description"]'));
    expect(meta('meta[name="twitter:title"]')).toBe('Política de privacidad — Luma');
  });

  it('gives the terms of service their own description and social tags', async () => {
    await router.navigateByUrl('/condiciones');

    expect(meta('meta[name="description"]')).toContain('Condiciones del servicio de Luma');
    expect(meta('meta[property="og:title"]')).toBe('Condiciones del servicio — Luma');
    expect(meta('meta[name="twitter:description"]')).toBe(meta('meta[name="description"]'));
  });

  it('restores the home title when navigating back', async () => {
    await router.navigateByUrl('/privacidad');
    await router.navigateByUrl('/');

    expect(canonical()).toBe(SITE_URL);
    expect(document.title).toBe('Luma — Finanzas personales simples');
  });
});
