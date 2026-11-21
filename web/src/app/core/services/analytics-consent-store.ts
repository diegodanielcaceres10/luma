import { Injectable } from '@angular/core';

export type ConsentStatus = 'unknown' | 'granted' | 'denied';

export const CONSENT_STORAGE_KEY = 'luma-analytics-consent';

/** Persists the visitor's analytics consent choice in localStorage. */
@Injectable({ providedIn: 'root' })
export class AnalyticsConsentStore {
  read(): ConsentStatus {
    try {
      const value = localStorage.getItem(CONSENT_STORAGE_KEY);
      return value === 'granted' || value === 'denied' ? value : 'unknown';
    } catch {
      return 'unknown';
    }
  }

  save(value: ConsentStatus): void {
    try {
      localStorage.setItem(CONSENT_STORAGE_KEY, value);
    } catch {
      // Storage can be blocked (private mode); the choice then lasts for the session only.
    }
  }
}
