import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { CookieBannerComponent } from './shared/components/cookie-banner/cookie-banner';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CookieBannerComponent],
  templateUrl: './app.html',
})
export class App {}
