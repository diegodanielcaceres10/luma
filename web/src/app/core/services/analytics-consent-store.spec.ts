import { TestBed } from '@angular/core/testing';

import { AnalyticsConsentStore, CONSENT_STORAGE_KEY } from './analytics-consent-store';

describe('AnalyticsConsentStore', () => {
  let store: AnalyticsConsentStore;

  beforeEach(() => {
    localStorage.clear();
    store = TestBed.inject(AnalyticsConsentStore);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    localStorage.clear();
  });

  it('reads unknown when nothing was stored', () => {
    expect(store.read()).toBe('unknown');
  });

  it.each(['granted', 'denied'] as const)('round-trips a stored %s choice', (choice) => {
    store.save(choice);

    expect(localStorage.getItem(CONSENT_STORAGE_KEY)).toBe(choice);
    expect(store.read()).toBe(choice);
  });

  it('treats unexpected stored values as unknown', () => {
    localStorage.setItem(CONSENT_STORAGE_KEY, 'maybe');

    expect(store.read()).toBe('unknown');
  });

  it('falls back to unknown when storage is blocked', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('blocked');
    });

    expect(store.read()).toBe('unknown');
  });

  it('does not throw when storage is blocked while saving', () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('blocked');
    });

    expect(() => store.save('granted')).not.toThrow();
  });
});
