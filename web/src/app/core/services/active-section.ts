import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { Injectable, PLATFORM_ID, inject, signal } from '@angular/core';

/** A thin band across the middle of the viewport: the section crossing it is the one being read. */
const READING_BAND_MARGIN = '-45% 0px -54% 0px';

/** Tells which page section is being read, so the navigation can show where the visitor is. */
@Injectable({ providedIn: 'root' })
export class ActiveSectionService {
  private readonly document = inject(DOCUMENT);
  private readonly platformId = inject(PLATFORM_ID);

  private observer: IntersectionObserver | undefined;
  private readonly activeId = signal<string | null>(null);

  /** The id of the section being read, or null when none of the watched sections is. */
  readonly active = this.activeId.asReadonly();

  /** Starts watching the sections with these ids; when several qualify, the earliest in `ids` wins. */
  watch(ids: readonly string[]): void {
    this.stop();
    if (!isPlatformBrowser(this.platformId) || typeof IntersectionObserver === 'undefined') return;

    const crossing = new Set<string>();
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(({ target, isIntersecting }) =>
          isIntersecting ? crossing.add(target.id) : crossing.delete(target.id),
        );
        this.activeId.set(ids.find((id) => crossing.has(id)) ?? null);
      },
      { rootMargin: READING_BAND_MARGIN },
    );

    ids.forEach((id) => {
      const section = this.document.getElementById(id);
      if (section) observer.observe(section);
    });
    this.observer = observer;
  }

  stop(): void {
    this.observer?.disconnect();
    this.observer = undefined;
    this.activeId.set(null);
  }
}
