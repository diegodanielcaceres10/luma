import { DOCUMENT } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

/** Id every page must set on its `<main>` so the skip link can move focus there. */
export const SKIP_LINK_TARGET_ID = 'main-content';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-skip-link',
  templateUrl: './skip-link.html',
})
export class SkipLinkComponent {
  private readonly document = inject(DOCUMENT);

  protected readonly targetHref = `#${SKIP_LINK_TARGET_ID}`;

  protected skip(event: Event): void {
    // A plain hash link would resolve against <base href> and navigate to the home route.
    event.preventDefault();
    this.document.getElementById(SKIP_LINK_TARGET_ID)?.focus();
  }
}
