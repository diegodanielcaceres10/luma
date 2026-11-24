import { DOCUMENT } from '@angular/common';
import { DestroyRef, Injectable, inject } from '@angular/core';
import { Meta } from '@angular/platform-browser';
import { Router } from '@angular/router';

import { SITE_URL } from '../config/site.config';
import { onNavigationEnd } from '../utils/navigation-end';

/** Keeps the canonical link and og:url aligned with the current route. */
@Injectable({ providedIn: 'root' })
export class PageUrlService {
  private readonly document = inject(DOCUMENT);
  private readonly meta = inject(Meta);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  /** Starts syncing the canonical link and og:url with every completed navigation. */
  init(): void {
    onNavigationEnd(this.router, this.destroyRef, (event) => this.set(this.toPath(event.urlAfterRedirects)));
  }

  /** `path` is relative to the site root, for example `privacidad`. */
  set(path: string): void {
    const url = path ? `${SITE_URL}${path}/` : SITE_URL;

    let link = this.document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!link) {
      link = this.document.createElement('link');
      link.rel = 'canonical';
      this.document.head.appendChild(link);
    }
    link.href = url;

    this.meta.updateTag({ property: 'og:url', content: url });
  }

  private toPath(url: string): string {
    const [path = ''] = url.split(/[?#]/);
    return path.replace(/^\/+|\/+$/g, '');
  }
}
