import { DOCUMENT } from '@angular/common';
import { Injectable, inject } from '@angular/core';

import { ANALYTICS_CONFIG } from '../config/analytics.config';

type GtagWindow = Window & {
  dataLayer?: unknown[];
  gtag?: (...args: unknown[]) => void;
};

/** Thin wrapper around Google's gtag.js: data layer, script loading and the opt-out switch. */
@Injectable({ providedIn: 'root' })
export class GtagClient {
  private readonly config = inject(ANALYTICS_CONFIG);
  private readonly document = inject(DOCUMENT);

  /** Defines `window.gtag` so commands can be queued before gtag.js is loaded. */
  install(): void {
    const view = this.window;
    view.dataLayer ??= [];
    view.gtag ??= function () {
      // gtag.js expects the raw `arguments` object, not an array.
      // eslint-disable-next-line prefer-rest-params
      (view.dataLayer ??= []).push(arguments);
    };
  }

  send(...args: unknown[]): void {
    this.window.gtag?.(...args);
  }

  loadScript(): void {
    const script = this.document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(this.config.measurementId)}`;
    this.document.head.appendChild(script);
  }

  setDisabled(disabled: boolean): void {
    // Google's opt-out switch: `window['ga-disable-<id>'] = true` stops all measurement for that property.
    Reflect.set(this.window, `ga-disable-${this.config.measurementId}`, disabled);
  }

  private get window(): GtagWindow {
    return this.document.defaultView as GtagWindow;
  }
}
