import { ChangeDetectionStrategy, Component } from '@angular/core';

/**
 * Recurring payments card.
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-recurring-card',
  templateUrl: './bento-recurring-card.html',
  host: { class: 'contents' },
})
export class BentoRecurringCardComponent {}
