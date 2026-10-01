import {
  ApplicationConfig,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { provideRouter, withInMemoryScrolling } from '@angular/router';

import { routes } from './app.routes';
import { provideClientHydration } from '@angular/platform-browser';
import { AnalyticsService } from './services/analytics';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withInMemoryScrolling({
        scrollPositionRestoration: 'top',
        // Without this, the router resets to top on every #fragment navigation
        anchorScrolling: 'enabled',
      }),
    ),
    provideClientHydration(),
    provideAppInitializer(() => inject(AnalyticsService).init()),
  ],
};
