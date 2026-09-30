import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Title } from '@angular/platform-browser';

import { NavbarComponent } from '../../components/navbar/navbar';
import { FooterComponent } from '../../components/footer/footer';

@Component({
  selector: 'app-terms-of-service',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './terms-of-service.html',
})
export class TermsOfService {
  private readonly titleService = inject(Title);

  protected readonly lastUpdated = new Date().toLocaleDateString('es-AR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  constructor() {
    this.titleService.setTitle('Condiciones del servicio — Luma');
  }
}
