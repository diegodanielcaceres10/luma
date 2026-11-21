import { ChangeDetectionStrategy, Component } from '@angular/core';

/**
 * Multiple accounts and currencies card (spans 2 columns on large screens).
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-accounts-card',
  templateUrl: './bento-accounts-card.html',
  host: { class: 'contents' },
})
export class BentoAccountsCardComponent {}
