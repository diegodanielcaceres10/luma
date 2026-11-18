import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('@features/landing/pages/home/home').then((m) => m.Home),
  },
  {
    path: 'privacidad',
    loadComponent: () =>
      import('@features/legal/pages/privacy-policy/privacy-policy').then((m) => m.PrivacyPolicy),
  },
  {
    path: 'condiciones',
    loadComponent: () =>
      import('@features/legal/pages/terms-of-service/terms-of-service').then((m) => m.TermsOfService),
  },
  { path: '**', redirectTo: '' },
];
