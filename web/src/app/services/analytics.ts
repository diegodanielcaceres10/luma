import { DestroyRef, Injectable, PLATFORM_ID, inject, signal } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';

import { ANALYTICS_CONFIG } from '../config/analytics.config';

export type ConsentStatus = 'unknown' | 'granted' | 'denied';

export const CONSENT_STORAGE_KEY = 'luma-analytics-consent';

type AnalyticsWindow = Window & {
  dataLayer?: unknown[];
  gtag?: (...args: unknown[]) => void;
};

/**
 * Google Analytics 4 behind an explicit consent choice (Consent Mode v2).
 * Nothing is requested from Google until the user accepts.
 */
@Injectable({ providedIn: 'root' })
export class AnalyticsService {
  private readonly config = inject(ANALYTICS_CONFIG);
  private readonly document = inject(DOCUMENT);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly consentState = signal<ConsentStatus>('unknown');
  readonly consent = this.consentState.asReadonly();

  private scriptLoaded = false;

  init(): void {
    if (!this.isBrowser) return;

    this.installGtag();
    this.gtag('consent', 'default', {
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

    const stored = this.readStoredConsent();
    this.consentState.set(stored);
    if (stored === 'granted') this.activate();
  }

  accept(): void {
    this.consentState.set('granted');
    this.storeConsent('granted');
    this.activate();
  }

  reject(): void {
    this.consentState.set('denied');
    this.storeConsent('denied');
    if (!this.scriptLoaded) return;

    this.gtag('consent', 'update', { analytics_storage: 'denied' });
    this.setDisabled(true);
  }

  /** Puts the banner back so the user can change a previous choice. */
  reopenPreferences(): void {
    this.consentState.set('unknown');
  }

  private activate(): void {
    if (!this.config.enabled) return;

    this.setDisabled(false);
    this.gtag('consent', 'update', { analytics_storage: 'granted' });

    if (!this.scriptLoaded) {
      this.loadScript();
      this.gtag('js', new Date());
      // The router reports navigations itself, so the automatic page_view is off.
      this.gtag('config', this.config.measurementId, { send_page_view: false });
      this.scriptLoaded = true;
    }

    this.sendPageView(this.router.url);
  }

  private sendPageView(path: string): void {
    if (!this.scriptLoaded || this.consentState() !== 'granted') return;

    this.gtag('event', 'page_view', {
      page_path: path,
      page_location: this.document.location.href,
      page_title: this.document.title,
    });
  }

  private loadScript(): void {
    const script = this.document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(this.config.measurementId)}`;
    this.document.head.appendChild(script);
  }

  private installGtag(): void {
    const win = this.window;
    win.dataLayer = win.dataLayer ?? [];
    win.gtag =
      win.gtag ??
      function () {
        // gtag.js expects the raw `arguments` object, not an array.
        // eslint-disable-next-line prefer-rest-params
        win.dataLayer!.push(arguments);
      };
  }

  private gtag(...args: unknown[]): void {
    this.window.gtag?.(...args);
  }

  private setDisabled(disabled: boolean): void {
    (this.window as unknown as Record<string, unknown>)[`ga-disable-${this.config.measurementId}`] =
      disabled;
  }

  private get window(): AnalyticsWindow {
    return this.document.defaultView as AnalyticsWindow;
  }

  private readStoredConsent(): ConsentStatus {
    try {
      const value = localStorage.getItem(CONSENT_STORAGE_KEY);
      return value === 'granted' || value === 'denied' ? value : 'unknown';
    } catch {
      return 'unknown';
    }
  }

  private storeConsent(value: ConsentStatus): void {
    try {
      localStorage.setItem(CONSENT_STORAGE_KEY, value);
    } catch {
      // Storage can be blocked (private mode); the choice then lasts for the session only.
    }
  }
}
