import { DOCUMENT } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { SITE_URL } from '../config/site.config';
import { PageUrlService } from './page-url';

describe('PageUrlService', () => {
  let doc: Document;
  let service: PageUrlService;

  const canonicals = () => doc.head.querySelectorAll('link[rel="canonical"]');
  const ogUrls = () => doc.head.querySelectorAll('meta[property="og:url"]');

  beforeEach(() => {
    doc = TestBed.inject(DOCUMENT);
    doc.head.querySelectorAll('link[rel="canonical"], meta[property="og:url"]').forEach((el) => el.remove());
    service = TestBed.inject(PageUrlService);
  });

  it('creates the canonical link and og:url for the home page', () => {
    service.set('');

    expect(canonicals()).toHaveLength(1);
    expect(canonicals()[0]?.getAttribute('href')).toBe(SITE_URL);
    expect(ogUrls()[0]?.getAttribute('content')).toBe(SITE_URL);
  });

  it('appends the route path with a trailing slash', () => {
    service.set('privacidad');

    expect(canonicals()[0]?.getAttribute('href')).toBe(`${SITE_URL}privacidad/`);
    expect(ogUrls()[0]?.getAttribute('content')).toBe(`${SITE_URL}privacidad/`);
  });

  it('replaces the previous values instead of duplicating tags', () => {
    service.set('privacidad');
    service.set('condiciones');

    expect(canonicals()).toHaveLength(1);
    expect(ogUrls()).toHaveLength(1);
    expect(canonicals()[0]?.getAttribute('href')).toBe(`${SITE_URL}condiciones/`);
  });

  it('keeps the canonical and og:url in sync', () => {
    service.set('condiciones');

    expect(ogUrls()[0]?.getAttribute('content')).toBe(canonicals()[0]?.getAttribute('href'));
  });

  describe('driven by the router', () => {
    let router: Router;

    beforeEach(() => {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          provideRouter([
            { path: '', children: [] },
            { path: 'privacidad', children: [] },
            { path: '**', redirectTo: '' },
          ]),
        ],
      });
      doc = TestBed.inject(DOCUMENT);
      doc.head.querySelectorAll('link[rel="canonical"], meta[property="og:url"]').forEach((el) => el.remove());
      router = TestBed.inject(Router);
      TestBed.inject(PageUrlService).init();
    });

    it('sets the canonical URL after navigating to a page', async () => {
      await router.navigateByUrl('/privacidad');

      expect(canonicals()[0]?.getAttribute('href')).toBe(`${SITE_URL}privacidad/`);
      expect(ogUrls()[0]?.getAttribute('content')).toBe(`${SITE_URL}privacidad/`);
    });

    it('returns to the site root when navigating back home', async () => {
      await router.navigateByUrl('/privacidad');
      await router.navigateByUrl('/');

      expect(canonicals()[0]?.getAttribute('href')).toBe(SITE_URL);
    });

    it('ignores query string and fragment', async () => {
      await router.navigateByUrl('/privacidad?x=1#top');

      expect(canonicals()[0]?.getAttribute('href')).toBe(`${SITE_URL}privacidad/`);
    });

    it('uses the redirected URL for unknown paths', async () => {
      await router.navigateByUrl('/does-not-exist');

      expect(canonicals()[0]?.getAttribute('href')).toBe(SITE_URL);
    });
  });
});
