import {
  ApplicationConfig,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { provideRouter, withInMemoryScrolling } from '@angular/router';

import { routes } from './app.routes';
import { provideClientHydration, withNoIncrementalHydration } from '@angular/platform-browser';
import { AnalyticsService } from '@core/services/analytics';
import { PageMetaService } from '@core/services/page-meta';
import { PageUrlService } from '@core/services/page-url';

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
    provideClientHydration(withNoIncrementalHydration()),
    provideAppInitializer(() => inject(AnalyticsService).init()),
    provideAppInitializer(() => inject(PageUrlService).init()),
    provideAppInitializer(() => inject(PageMetaService).init()),
  ],
};
