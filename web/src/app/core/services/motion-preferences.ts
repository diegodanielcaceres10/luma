import { DOCUMENT } from '@angular/common';
import { Injectable, inject } from '@angular/core';

/** Reads the user's motion preference without touching `window` directly. */
@Injectable({ providedIn: 'root' })
export class MotionPreferencesService {
  private readonly document = inject(DOCUMENT);

  /** Falls back to full motion where media queries are unavailable (server rendering, jsdom). */
  prefersReducedMotion(): boolean {
    return this.document.defaultView?.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
  }
}
