import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { UsdPipe } from '@shared/pipes/usd';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-gemini-section',
  imports: [RouterLink, UsdPipe],
  templateUrl: './gemini-section.html',
})
export class GeminiSectionComponent {}
