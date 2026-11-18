import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-security-section',
  templateUrl: './security-section.html',
})
export class SecuritySectionComponent {}
