import { InjectionToken, isDevMode } from '@angular/core';

/** Public by design: GA4 measurement IDs ship in every page that uses them. */
export const ANALYTICS_MEASUREMENT_ID = 'G-0E4MJ98XS2';

export interface AnalyticsConfig {
  measurementId: string;
  /** When false the consent flow still works, but gtag.js is never loaded. */
  enabled: boolean;
}

export const ANALYTICS_CONFIG = new InjectionToken<AnalyticsConfig>('ANALYTICS_CONFIG', {
  providedIn: 'root',
  factory: () => ({
    measurementId: ANALYTICS_MEASUREMENT_ID,
    // Keeps local development out of the production reports.
    enabled: !isDevMode(),
  }),
});
