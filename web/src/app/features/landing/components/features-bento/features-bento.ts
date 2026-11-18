import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-features-bento',
  templateUrl: './features-bento.html',
})
export class FeaturesBentoComponent {}
