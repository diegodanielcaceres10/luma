import { ChangeDetectionStrategy, Component } from '@angular/core';

import { UsdPipe } from '@shared/pipes/usd';

/**
 * Income and expenses card (spans 2 columns on large screens).
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-income-card',
  imports: [UsdPipe],
  templateUrl: './bento-income-card.html',
  host: { class: 'contents' },
})
export class BentoIncomeCardComponent {}
