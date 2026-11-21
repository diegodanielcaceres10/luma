import { DestroyRef, Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';

import { ANALYTICS_CONFIG } from '../config/analytics.config';
import { AnalyticsConsentStore, ConsentStatus } from './analytics-consent-store';
import { GtagClient } from './gtag-client';

export { CONSENT_STORAGE_KEY } from './analytics-consent-store';
export type { ConsentStatus } from './analytics-consent-store';

/**
 * Google Analytics 4 behind an explicit consent choice (Consent Mode v2).
 * Nothing is requested from Google until the user accepts. Persistence and the
 * gtag.js plumbing live in {@link AnalyticsConsentStore} and {@link GtagClient}.
 */
@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly config = inject(ANALYTICS_CONFIG);
  private readonly document = inject(DOCUMENT);
  private readonly gtagClient = inject(GtagClient);
  private readonly consentStore = inject(AnalyticsConsentStore);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly consentState = signal<ConsentStatus>('unknown');
  readonly consent = this.consentState.asReadonly();

  private scriptLoaded = false;

  init(): void {
    if (!this.isBrowser) return;

    this.gtagClient.install();
    this.gtagClient.send('consent', 'default', {
      analytics_storage: 'denied',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
    });

    this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((event) => this.sendPageView(event.urlAfterRedirects));

    const stored = this.consentStore.read();
    this.consentState.set(stored);
    if (stored === 'granted') this.activate();
  }

  accept(): void {
    this.consentState.set('granted');
    this.consentStore.save('granted');
    this.activate();
  }

  reject(): void {
    this.consentState.set('denied');
    this.consentStore.save('denied');
    if (!this.scriptLoaded) return;

    this.gtagClient.send('consent', 'update', { analytics_storage: 'denied' });
    this.gtagClient.setDisabled(true);
  }

  /** Puts the banner back so the user can change a previous choice. */
  reopenPreferences(): void {
    this.consentState.set('unknown');
  }

  private activate(): void {
    if (!this.config.enabled) return;

    this.gtagClient.setDisabled(false);
    this.gtagClient.send('consent', 'update', { analytics_storage: 'granted' });

    if (!this.scriptLoaded) {
      this.gtagClient.loadScript();
      this.gtagClient.send('js', new Date());
      // The router reports navigations itself, so the automatic page_view is off.
      this.gtagClient.send('config', this.config.measurementId, { send_page_view: false });
      this.scriptLoaded = true;
    }

    this.sendPageView(this.router.url);
  }

  private sendPageView(path: string): void {
    if (!this.scriptLoaded || this.consentState() !== 'granted') return;

    this.gtagClient.send('event', 'page_view', {
      page_path: path,
      page_location: this.document.location.href,
      page_title: this.document.title,
    });
  }
}
