import { ChangeDetectionStrategy, Component } from '@angular/core';

/**
 * Executive PDF export card (spans 2 columns on large screens).
 * The host uses `display: contents` so the card box stays a direct item of the bento grid.
 */
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-bento-pdf-export-card',
  templateUrl: './bento-pdf-export-card.html',
  host: { class: 'contents' },
})
export class BentoPdfExportCardComponent {}
