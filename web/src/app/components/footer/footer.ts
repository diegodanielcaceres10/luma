import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AnalyticsService } from '../../services/analytics';

@Component({
  selector: 'app-footer',
  imports: [RouterLink],
  templateUrl: './footer.html',
})
export class FooterComponent {
  protected readonly analytics = inject(AnalyticsService);
  protected readonly year = new Date().getFullYear();
}
