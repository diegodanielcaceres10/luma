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
    doc.head.querySelectorAll('script[type="application/ld+json"]').forEach((el) => el.remove());
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

  it('keeps a single JSON-LD block when the data is replaced', () => {
    service.setStructuredData({ name: 'One' });
    service.setStructuredData({ name: 'Two' });

    const blocks = doc.head.querySelectorAll('script[type="application/ld+json"]');
    expect(blocks).toHaveLength(1);
    expect(JSON.parse(blocks[0]?.textContent ?? '')).toEqual({ name: 'Two' });
  });

  it('cannot break out of the script element through the data', () => {
    service.setStructuredData({ name: '</script><img src=x onerror=alert(1)>' });

    const block = doc.head.querySelector('script[type="application/ld+json"]');
    expect(block?.textContent).not.toContain('<');
    expect(JSON.parse(block?.textContent ?? '').name).toBe('</script><img src=x onerror=alert(1)>');
    expect(doc.head.querySelector('img')).toBeNull();
  });

  describe('driven by the router', () => {
    let router: Router;

    beforeEach(() => {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        providers: [
          provideRouter([
            { path: '', title: 'Home', data: { description: 'Home text' }, children: [] },
            {
              path: 'about',
              title: 'About',
              data: { description: 'About text', structuredData: { '@type': 'Thing', name: 'About' } },
              children: [],
            },
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

    it('adds the structured data of the route as a JSON-LD block', async () => {
      await router.navigateByUrl('/about');

      const blocks = doc.head.querySelectorAll('script[type="application/ld+json"]');
      expect(blocks).toHaveLength(1);
      expect(JSON.parse(blocks[0]?.textContent ?? '')).toEqual({ '@type': 'Thing', name: 'About' });
    });

    it('removes the JSON-LD block on routes without structured data', async () => {
      await router.navigateByUrl('/about');
      await router.navigateByUrl('/bare');

      expect(doc.head.querySelectorAll('script[type="application/ld+json"]')).toHaveLength(0);
    });

    it('keeps the previous tags when a route declares no description', async () => {
      await router.navigateByUrl('/about');
      await router.navigateByUrl('/bare');

      expect(content('meta[name="description"]')).toBe('About text');
    });
  });
});
