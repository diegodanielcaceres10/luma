import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    title: 'Luma — Finanzas personales simples',
    loadComponent: () => import('@features/landing/pages/home/home').then((m) => m.Home),
  },
  {
    path: 'privacidad',
    title: 'Política de privacidad — Luma',
    loadComponent: () =>
      import('@features/legal/pages/privacy-policy/privacy-policy').then((m) => m.PrivacyPolicy),
  },
  {
    path: 'condiciones',
    title: 'Condiciones del servicio — Luma',
    loadComponent: () =>
      import('@features/legal/pages/terms-of-service/terms-of-service').then((m) => m.TermsOfService),
  },
  { path: '**', redirectTo: '' },
];
