import { Component, afterNextRender, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AnalyticsService } from '../../services/analytics';

@Component({
  selector: 'app-cookie-banner',
  imports: [RouterLink],
  templateUrl: './cookie-banner.html',
})
export class CookieBannerComponent {
  protected readonly analytics = inject(AnalyticsService);

  // The stored choice only exists in the browser. Rendering after hydration
  // keeps the prerendered HTML identical to the first client render.
  protected readonly ready = signal(false);

  constructor() {
    afterNextRender(() => this.ready.set(true));
  }
}
