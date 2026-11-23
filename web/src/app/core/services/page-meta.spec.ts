import { DOCUMENT } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { PageMetaService } from './page-meta';

const META_SELECTOR = [
  'meta[name="description"]',
  'meta[property="og:title"]',
  'meta[property="og:description"]',
  'meta[name="twitter:title"]',
  'meta[name="twitter:description"]',
].join(', ');

describe('PageMetaService', () => {
  let doc: Document;
  let service: PageMetaService;

  const content = (selector: string) => doc.head.querySelector(selector)?.getAttribute('content');

  beforeEach(() => {
    doc = TestBed.inject(DOCUMENT);
    doc.head.querySelectorAll(META_SELECTOR).forEach((el) => el.remove());
    service = TestBed.inject(PageMetaService);
  });

  it('writes the description and the social title and description', () => {
    service.set('Page title', 'Page description');

    expect(content('meta[name="description"]')).toBe('Page description');
    expect(content('meta[property="og:title"]')).toBe('Page title');
    expect(content('meta[property="og:description"]')).toBe('Page description');
    expect(content('meta[name="twitter:title"]')).toBe('Page title');
    expect(content('meta[name="twitter:description"]')).toBe('Page description');
  });

  it('replaces the previous values instead of duplicating tags', () => {
    service.set('First', 'One');
    service.set('Second', 'Two');

    expect(doc.head.querySelectorAll(META_SELECTOR)).toHaveLength(5);
    expect(content('meta[property="og:title"]')).toBe('Second');
  });

  describe('driven by the router', () => {
    let router: Router;

    beforeEach(() => {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          provideRouter([
            { path: '', title: 'Home', data: { description: 'Home text' }, children: [] },
            { path: 'about', title: 'About', data: { description: 'About text' }, children: [] },
            { path: 'bare', title: 'Bare', children: [] },
            { path: '**', redirectTo: '' },
          ]),
        ],
      });
      doc = TestBed.inject(DOCUMENT);
      doc.head.querySelectorAll(META_SELECTOR).forEach((el) => el.remove());
      router = TestBed.inject(Router);
      TestBed.inject(PageMetaService).init();
    });

    it('uses the route title and description after navigating', async () => {
      await router.navigateByUrl('/about');

      expect(content('meta[name="description"]')).toBe('About text');
      expect(content('meta[property="og:title"]')).toBe('About');
      expect(content('meta[name="twitter:description"]')).toBe('About text');
    });

    it('restores the home values when navigating back', async () => {
      await router.navigateByUrl('/about');
      await router.navigateByUrl('/');

      expect(content('meta[property="og:title"]')).toBe('Home');
      expect(content('meta[property="og:description"]')).toBe('Home text');
    });

    it('keeps the previous tags when a route declares no description', async () => {
      await router.navigateByUrl('/about');
      await router.navigateByUrl('/bare');

      expect(content('meta[name="description"]')).toBe('About text');
    });
  });
});
