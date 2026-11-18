import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-gemini-section',
  imports: [RouterLink],
  templateUrl: './gemini-section.html',
})
export class GeminiSectionComponent {}
