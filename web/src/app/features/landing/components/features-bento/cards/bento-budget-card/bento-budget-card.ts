import { ChangeDetectionStrategy, Component } from '@angular/core';

/**
 * Dynamic budgets card.
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-budget-card',
  templateUrl: './bento-budget-card.html',
  host: { class: 'contents' },
})
export class BentoBudgetCardComponent {}
