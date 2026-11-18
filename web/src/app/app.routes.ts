import { Routes } from '@angular/router';
import { Home } from './features/landing/pages/home/home';

export const routes: Routes = [
  { path: '', component: Home },
  {
    path: 'privacidad',
    loadComponent: () =>
      import('./features/legal/pages/privacy-policy/privacy-policy').then((m) => m.PrivacyPolicy),
  },
  {
    path: 'condiciones',
    loadComponent: () =>
      import('./features/legal/pages/terms-of-service/terms-of-service').then((m) => m.TermsOfService),
  },
  { path: '**', redirectTo: '' },
];
