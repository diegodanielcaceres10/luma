import { DOCUMENT } from '@angular/common';
import { Injectable, inject } from '@angular/core';
import { Meta } from '@angular/platform-browser';

import { SITE_URL } from '../config/site.config';

/** Keeps the canonical link and og:url aligned with the current route. */
@Injectable({ providedIn: 'root' })
export class PageUrlService {
  private readonly document = inject(DOCUMENT);
  private readonly meta = inject(Meta);

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
}
