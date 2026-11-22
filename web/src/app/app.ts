import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { CookieBannerComponent } from '@shared/components/cookie-banner/cookie-banner';
import { SkipLinkComponent } from '@shared/components/skip-link/skip-link';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-root',
  imports: [RouterOutlet, CookieBannerComponent, SkipLinkComponent],
  templateUrl: './app.html',
})
export class App {}
