import { DOCUMENT } from '@angular/common';
import { TestBed } from '@angular/core/testing';

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
    expect(canonicals()[0].getAttribute('href')).toBe(SITE_URL);
    expect(ogUrls()[0].getAttribute('content')).toBe(SITE_URL);
  });

  it('appends the route path with a trailing slash', () => {
    service.set('privacidad');

    expect(canonicals()[0].getAttribute('href')).toBe(`${SITE_URL}privacidad/`);
    expect(ogUrls()[0].getAttribute('content')).toBe(`${SITE_URL}privacidad/`);
  });

  it('replaces the previous values instead of duplicating tags', () => {
    service.set('privacidad');
    service.set('condiciones');

    expect(canonicals()).toHaveLength(1);
    expect(ogUrls()).toHaveLength(1);
    expect(canonicals()[0].getAttribute('href')).toBe(`${SITE_URL}condiciones/`);
  });

  it('keeps the canonical and og:url in sync', () => {
    service.set('condiciones');

    expect(ogUrls()[0].getAttribute('content')).toBe(canonicals()[0].getAttribute('href'));
  });
});
