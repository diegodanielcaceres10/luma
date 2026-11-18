import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { ANALYTICS_CONFIG, AnalyticsConfig } from '../config/analytics.config';
import { AnalyticsService, CONSENT_STORAGE_KEY } from './analytics';

const MEASUREMENT_ID = 'G-TEST123';
const DISABLE_FLAG = `ga-disable-${MEASUREMENT_ID}`;

type GaWindow = Window & { dataLayer?: unknown[]; gtag?: unknown } & Record<string, unknown>;

describe('AnalyticsService', () => {
  const win = window as unknown as GaWindow;

  const configure = (config: Partial<AnalyticsConfig> = {}, platform = 'browser') => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([{ path: '**', children: [] }]),
        { provide: PLATFORM_ID, useValue: platform },
        { provide: ANALYTICS_CONFIG, useValue: { measurementId: MEASUREMENT_ID, enabled: true, ...config } },
      ],
    });
    return TestBed.inject(AnalyticsService);
  };

  /** gtag pushes the raw `arguments` object, so entries are normalized to arrays. */
  const calls = () => (win.dataLayer ?? []).map((entry) => Array.from(entry as ArrayLike<unknown>));
  const gaScripts = () => document.head.querySelectorAll('script[src*="googletagmanager.com/gtag/js"]');
  const pageViews = () => calls().filter(([command, name]) => command === 'event' && name === 'page_view');

  beforeEach(() => {
    localStorage.clear();
    document.head.querySelectorAll('script[src*="googletagmanager.com"]').forEach((el) => el.remove());
    delete win.dataLayer;
    delete win.gtag;
    delete win[DISABLE_FLAG];
  });

  afterEach(() => localStorage.clear());

  describe('before any choice', () => {
    it('starts as unknown, denies every consent signal and requests nothing from Google', () => {
      const service = configure();
      service.init();

      expect(service.consent()).toBe('unknown');
      expect(gaScripts().length).toBe(0);
      expect(calls()).toContainEqual([
        'consent',
        'default',
        {
          analytics_storage: 'denied',
          ad_storage: 'denied',
          ad_user_data: 'denied',
          ad_personalization: 'denied',
        },
      ]);
    });

    it('does not send page views while consent is unknown', async () => {
      const service = configure();
      service.init();

      await TestBed.inject(Router).navigateByUrl('/precios');

      expect(pageViews().length).toBe(0);
    });
  });

  describe('accepting', () => {
    it('stores the choice, loads gtag.js once and configures it without automatic page views', () => {
      const service = configure();
      service.init();

      service.accept();
      service.accept();

      expect(service.consent()).toBe('granted');
      expect(localStorage.getItem(CONSENT_STORAGE_KEY)).toBe('granted');
      expect(gaScripts().length).toBe(1);
      expect(gaScripts()[0].getAttribute('src')).toContain(`id=${MEASUREMENT_ID}`);
      expect(calls()).toContainEqual(['consent', 'update', { analytics_storage: 'granted' }]);
      expect(calls()).toContainEqual(['config', MEASUREMENT_ID, { send_page_view: false }]);
    });

    it('sends the current page and later navigations as page views', async () => {
      const service = configure();
      service.init();
      service.accept();
      const afterAccept = pageViews().length;

      await TestBed.inject(Router).navigateByUrl('/privacidad');

      expect(afterAccept).toBe(1);
      expect(pageViews().length).toBe(2);
      expect(pageViews()[1][2]).toMatchObject({ page_path: '/privacidad' });
    });

    it('keeps the consent flow but never loads gtag.js when analytics is disabled', () => {
      const service = configure({ enabled: false });
      service.init();

      service.accept();

      expect(service.consent()).toBe('granted');
      expect(gaScripts().length).toBe(0);
    });
  });

  describe('rejecting', () => {
    it('stores the choice and never loads the script when rejecting first', () => {
      const service = configure();
      service.init();

      service.reject();

      expect(service.consent()).toBe('denied');
      expect(localStorage.getItem(CONSENT_STORAGE_KEY)).toBe('denied');
      expect(gaScripts().length).toBe(0);
    });

    it('withdraws consent and disables measurement after a previous acceptance', async () => {
      const service = configure();
      service.init();
      service.accept();
      const viewsBefore = pageViews().length;

      service.reject();
      await TestBed.inject(Router).navigateByUrl('/condiciones');

      expect(calls()).toContainEqual(['consent', 'update', { analytics_storage: 'denied' }]);
      expect(win[DISABLE_FLAG]).toBe(true);
      expect(pageViews().length).toBe(viewsBefore);
    });
  });

  describe('stored choice', () => {
    it('restores a granted choice and activates analytics on init', () => {
      localStorage.setItem(CONSENT_STORAGE_KEY, 'granted');
      const service = configure();

      service.init();

      expect(service.consent()).toBe('granted');
      expect(gaScripts().length).toBe(1);
    });

    it('restores a denied choice without loading the script', () => {
      localStorage.setItem(CONSENT_STORAGE_KEY, 'denied');
      const service = configure();

      service.init();

      expect(service.consent()).toBe('denied');
      expect(gaScripts().length).toBe(0);
    });

    it('ignores unexpected stored values', () => {
      localStorage.setItem(CONSENT_STORAGE_KEY, 'maybe');
      const service = configure();

      service.init();

      expect(service.consent()).toBe('unknown');
      expect(gaScripts().length).toBe(0);
    });

    it('lets the user reopen the preferences to change a previous choice', () => {
      localStorage.setItem(CONSENT_STORAGE_KEY, 'denied');
      const service = configure();
      service.init();

      service.reopenPreferences();

      expect(service.consent()).toBe('unknown');
    });
  });

  describe('blocked storage', () => {
    it('falls back to unknown and keeps the choice for the session', () => {
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new DOMException('blocked', 'SecurityError');
      });
      vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new DOMException('blocked', 'SecurityError');
      });
      const service = configure();

      expect(() => service.init()).not.toThrow();
      expect(service.consent()).toBe('unknown');

      expect(() => service.accept()).not.toThrow();
      expect(service.consent()).toBe('granted');
      vi.restoreAllMocks();
    });
  });

  describe('on the server', () => {
    it('does nothing during prerendering', () => {
      const service = configure({}, 'server');

      service.init();

      expect(win.gtag).toBeUndefined();
      expect(win.dataLayer).toBeUndefined();
      expect(gaScripts().length).toBe(0);
    });
  });
});
