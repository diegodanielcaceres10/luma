import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';

import { NavbarComponent } from '../../components/navbar/navbar';
import { FooterComponent } from '../../components/footer/footer';

@Component({
  selector: 'app-privacy-policy',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './privacy-policy.html',
})
export class PrivacyPolicy {
  private readonly titleService = inject(Title);

  protected readonly lastUpdated = new Date().toLocaleDateString('es-AR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  constructor() {
    this.titleService.setTitle('Política de privacidad — Luma');
  }
}
