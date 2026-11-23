import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { CURRENT_YEAR } from '@core/config/current-year';
import { AnalyticsService } from '@core/services/analytics';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-footer',
  imports: [RouterLink],
  templateUrl: './footer.html',
})
export class FooterComponent {
  protected readonly analytics = inject(AnalyticsService);
  protected readonly year = inject(CURRENT_YEAR);
}
