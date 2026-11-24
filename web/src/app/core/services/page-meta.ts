import { DOCUMENT } from '@angular/common';
import { DestroyRef, Injectable, inject } from '@angular/core';
import { Meta } from '@angular/platform-browser';
import { ActivatedRouteSnapshot, Router } from '@angular/router';

import { onNavigationEnd } from '../utils/navigation-end';

const JSON_LD_SELECTOR = 'script[type="application/ld+json"]';

/** Keeps the description, the social tags and the JSON-LD block aligned with the current route. */
@Injectable({ providedIn: 'root' })
export class PageMetaService {
  private readonly document = inject(DOCUMENT);
  private readonly meta = inject(Meta);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  /** Starts syncing the tags with every completed navigation. */
  init(): void {
    onNavigationEnd(this.router, this.destroyRef, () => this.apply(this.deepestRoute()));
  }

  set(title: string, description: string): void {
    this.meta.updateTag({ name: 'description', content: description });
    this.meta.updateTag({ property: 'og:title', content: title });
    this.meta.updateTag({ property: 'og:description', content: description });
    this.meta.updateTag({ name: 'twitter:title', content: title });
    this.meta.updateTag({ name: 'twitter:description', content: description });
  }

  /** Replaces the page's JSON-LD block; `null` removes it. */
  setStructuredData(data: object | null): void {
    this.document.head.querySelectorAll(JSON_LD_SELECTOR).forEach((el) => el.remove());
    if (!data) return;

    const script = this.document.createElement('script');
    script.type = 'application/ld+json';
    // "<" is escaped so the data can never close the script element.
    script.textContent = JSON.stringify(data).replace(/</g, '\\u003c');
    this.document.head.appendChild(script);
  }

  private apply(route: ActivatedRouteSnapshot): void {
    const title = route.title;
    const description: unknown = route.data['description'];
    if (title && typeof description === 'string') this.set(title, description);

    const structuredData: unknown = route.data['structuredData'];
    this.setStructuredData(typeof structuredData === 'object' ? structuredData : null);
  }

  private deepestRoute(): ActivatedRouteSnapshot {
    let route = this.router.routerState.snapshot.root;
    while (route.firstChild) route = route.firstChild;
    return route;
  }
}
