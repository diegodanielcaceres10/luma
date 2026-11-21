import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { NavbarComponent } from '@shared/components/navbar/navbar';
import { FooterComponent } from '@shared/components/footer/footer';
import { PRIVACY_POLICY_LAST_UPDATED } from '../../legal-dates';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-privacy-policy',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './privacy-policy.html',
})
export class PrivacyPolicy {
  protected readonly lastUpdated = PRIVACY_POLICY_LAST_UPDATED;
}
