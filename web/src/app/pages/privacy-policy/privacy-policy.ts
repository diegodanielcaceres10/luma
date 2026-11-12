import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';

import { NavbarComponent } from '../../components/navbar/navbar';
import { FooterComponent } from '../../components/footer/footer';
import { PRIVACY_POLICY_LAST_UPDATED } from '../legal-dates';

@Component({
  selector: 'app-privacy-policy',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './privacy-policy.html',
})
export class PrivacyPolicy {
  private readonly titleService = inject(Title);

  protected readonly lastUpdated = PRIVACY_POLICY_LAST_UPDATED;

  constructor() {
    this.titleService.setTitle('Política de privacidad — Luma');
  }
}
