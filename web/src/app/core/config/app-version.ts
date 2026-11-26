import { InjectionToken } from '@angular/core';

/**
 * Release version of the product, shown in the navbar and the footer.
 * Bump it together with `version` in app/pubspec.yaml; a spec fails when they differ.
 */
export const APP_VERSION = new InjectionToken<string>('APP_VERSION', {
  providedIn: 'root',
  factory: () => '3.3.0',
});
