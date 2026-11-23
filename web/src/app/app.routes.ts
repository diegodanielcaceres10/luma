import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    title: 'Luma — Finanzas personales simples',
    data: {
      description:
        'Luma es una app ligera para llevar el control de ingresos, gastos, presupuestos e insights mensuales de tus finanzas personales.',
    },
    loadComponent: () => import('@features/landing/pages/home/home').then((m) => m.Home),
  },
  {
    path: 'privacidad',
    title: 'Política de privacidad — Luma',
    data: {
      description:
        'Política de privacidad de Luma: qué datos se recopilan, cómo se usan y dónde se almacenan, la analítica del sitio y tus derechos sobre ellos.',
    },
    loadComponent: () =>
      import('@features/legal/pages/privacy-policy/privacy-policy').then((m) => m.PrivacyPolicy),
  },
  {
    path: 'condiciones',
    title: 'Condiciones del servicio — Luma',
    data: {
      description:
        'Condiciones del servicio de Luma: naturaleza del proyecto, uso permitido, ausencia de garantías y responsabilidades de quien lo utiliza.',
    },
    loadComponent: () =>
      import('@features/legal/pages/terms-of-service/terms-of-service').then((m) => m.TermsOfService),
  },
  { path: '**', redirectTo: '' },
];
