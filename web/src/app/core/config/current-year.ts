import { InjectionToken } from '@angular/core';

/** Year shown in the footer; injectable so the date is read in one place and tests can fix it. */
export const CURRENT_YEAR = new InjectionToken<number>('CURRENT_YEAR', {
  providedIn: 'root',
  factory: () => new Date().getFullYear(),
});
