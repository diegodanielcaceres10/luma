import { TestBed } from '@angular/core/testing';

import { ANALYTICS_CONFIG } from '../config/analytics.config';
import { GtagClient } from './gtag-client';

const MEASUREMENT_ID = 'G-TEST123';
const DISABLE_FLAG = `ga-disable-${MEASUREMENT_ID}`;

type GaWindow = Window & { dataLayer?: unknown[]; gtag?: unknown } & Record<string, unknown>;

describe('GtagClient', () => {
  const win = window as unknown as GaWindow;
  let client: GtagClient;

  const scripts = () => document.head.querySelectorAll('script[src*="googletagmanager.com/gtag/js"]');

  beforeEach(() => {
    document.head.querySelectorAll('script[src*="googletagmanager.com"]').forEach((el) => el.remove());
    delete win.dataLayer;
    delete win.gtag;
    delete win[DISABLE_FLAG];
    TestBed.configureTestingModule({
      providers: [{ provide: ANALYTICS_CONFIG, useValue: { measurementId: MEASUREMENT_ID, enabled: true } }],
    });
    client = TestBed.inject(GtagClient);
  });

  it('does nothing when sending before install', () => {
    expect(() => client.send('event', 'x')).not.toThrow();
    expect(win.dataLayer).toBeUndefined();
  });

  it('pushes the raw arguments object to the data layer', () => {
    client.install();
    client.send('event', 'page_view', { page_path: '/' });

    const entry = win.dataLayer?.[0] as ArrayLike<unknown>;
    expect(Object.prototype.toString.call(entry)).toBe('[object Arguments]');
    expect(Array.from(entry)).toEqual(['event', 'page_view', { page_path: '/' }]);
  });

  it('keeps an existing data layer and gtag when installing again', () => {
    client.install();
    const gtag = win.gtag;
    client.install();

    expect(win.gtag).toBe(gtag);
  });

  it('appends the gtag.js script once per call with the encoded measurement id', () => {
    client.loadScript();

    expect(scripts()).toHaveLength(1);
    expect(scripts()[0]?.getAttribute('src')).toBe(
      `https://www.googletagmanager.com/gtag/js?id=${MEASUREMENT_ID}`,
    );
  });

  it('toggles the property opt-out flag', () => {
    client.setDisabled(true);
    expect(win[DISABLE_FLAG]).toBe(true);

    client.setDisabled(false);
    expect(win[DISABLE_FLAG]).toBe(false);
  });
});
