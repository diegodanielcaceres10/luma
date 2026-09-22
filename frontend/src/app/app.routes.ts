import { Routes } from '@angular/router';
import { Home } from './pages/home/home';
import { PrivacyPolicy } from './pages/privacy-policy/privacy-policy';
import { TermsOfService } from './pages/terms-of-service/terms-of-service';

export const routes: Routes = [
  { path: '', component: Home },
  { path: 'privacidad', component: PrivacyPolicy },
  { path: 'condiciones', component: TermsOfService },
  { path: '**', redirectTo: '' }
];
