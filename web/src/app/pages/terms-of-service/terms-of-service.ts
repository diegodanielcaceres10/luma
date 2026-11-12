import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';

import { NavbarComponent } from '../../components/navbar/navbar';
import { FooterComponent } from '../../components/footer/footer';
import { TERMS_OF_SERVICE_LAST_UPDATED } from '../legal-dates';

@Component({
  selector: 'app-terms-of-service',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './terms-of-service.html',
})
export class TermsOfService {
  private readonly titleService = inject(Title);

  protected readonly lastUpdated = TERMS_OF_SERVICE_LAST_UPDATED;

  constructor() {
    this.titleService.setTitle('Condiciones del servicio — Luma');
  }
}
