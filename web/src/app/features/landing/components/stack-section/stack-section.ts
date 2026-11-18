import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-stack-section',
  templateUrl: './stack-section.html',
})
export class StackSectionComponent {}
