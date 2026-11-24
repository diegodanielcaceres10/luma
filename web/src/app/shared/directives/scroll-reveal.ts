import { isPlatformBrowser } from '@angular/common';
import { DestroyRef, Directive, ElementRef, PLATFORM_ID, afterNextRender, inject } from '@angular/core';

import { MotionPreferencesService } from '@core/services/motion-preferences';

const REVEALABLE_SELECTOR =
  '.editorial-reveal, .editorial-reveal-scale, .editorial-stat-reveal, .editorial-progress-fill';
const REVEALED_CLASS = 'is-revealed';

/**
 * Adds `is-revealed` to the animated elements inside its host as they scroll into view.
 * Users who prefer reduced motion get everything revealed at once, with no observer.
 */
@Directive({ selector: '[appScrollReveal]' })
export class ScrollRevealDirective {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly platformId = inject(PLATFORM_ID);
  private readonly motion = inject(MotionPreferencesService);

  private intersectionObserver: IntersectionObserver | undefined;

  constructor() {
    afterNextRender(() => this.reveal());
    inject(DestroyRef).onDestroy(() => this.intersectionObserver?.disconnect());
  }

  private reveal(): void {
    if (!isPlatformBrowser(this.platformId)) return;

    const targets = this.host.nativeElement.querySelectorAll(REVEALABLE_SELECTOR);

    if (this.motion.prefersReducedMotion()) {
      targets.forEach((target) => target.classList.add(REVEALED_CLASS));
      return;
    }

    this.intersectionObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;

          entry.target.classList.add(REVEALED_CLASS);
          observer.unobserve(entry.target);
        });
      },
      { root: null, threshold: 0.1, rootMargin: '0px 0px -40px 0px' },
    );

    const observer = this.intersectionObserver;
    targets.forEach((target) => observer.observe(target));
  }
}
