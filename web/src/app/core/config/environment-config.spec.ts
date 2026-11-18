import { TestBed } from '@angular/core/testing';

import { environment } from '../../../environments/environment';
import { ANALYTICS_CONFIG } from './analytics.config';
import { SITE_URL } from './site.config';

describe('environment-driven configuration', () => {
  it('exposes the site URL from the environment', () => {
    expect(SITE_URL).toBe(environment.siteUrl);
  });

  it('keeps the site URL absolute and slash-terminated so paths can be appended', () => {
    expect(SITE_URL).toMatch(/^https?:\/\/.+\/$/);
  });

  it('builds the analytics config from the environment', () => {
    expect(TestBed.inject(ANALYTICS_CONFIG)).toEqual(environment.analytics);
  });
});
