import { InjectionToken } from '@angular/core';

import { environment } from '../../environments/environment';

export interface AnalyticsConfig {
  measurementId: string;
  /** When false the consent flow still works, but gtag.js is never loaded. */
  enabled: boolean;
}

export const ANALYTICS_CONFIG = new InjectionToken<AnalyticsConfig>('ANALYTICS_CONFIG', {
  providedIn: 'root',
  factory: () => environment.analytics,
});
