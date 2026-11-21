import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { NavbarComponent } from '@shared/components/navbar/navbar';
import { FooterComponent } from '@shared/components/footer/footer';
import { TERMS_OF_SERVICE_LAST_UPDATED } from '../../legal-dates';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-terms-of-service',
  imports: [RouterLink, NavbarComponent, FooterComponent],
  templateUrl: './terms-of-service.html',
})
export class TermsOfService {
  protected readonly lastUpdated = TERMS_OF_SERVICE_LAST_UPDATED;
}
