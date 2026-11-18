import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';

import { PageUrlService } from '@core/services/page-url';
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
  private readonly titleService = inject(Title);
  private readonly pageUrl = inject(PageUrlService);

  protected readonly lastUpdated = PRIVACY_POLICY_LAST_UPDATED;

  constructor() {
    this.titleService.setTitle('Política de privacidad — Luma');
    this.pageUrl.set('privacidad');
  }
}
