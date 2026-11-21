import { ChangeDetectionStrategy, Component } from '@angular/core';

/**
 * Monthly insights card.
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-insights-card',
  templateUrl: './bento-insights-card.html',
  host: { class: 'contents' },
})
export class BentoInsightsCardComponent {}
