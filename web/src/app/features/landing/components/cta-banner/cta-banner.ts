import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-cta-banner',
  templateUrl: './cta-banner.html',
})
export class CtaBannerComponent {}
