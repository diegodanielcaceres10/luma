import { Route } from '@angular/router';

import { routes } from './app.routes';

describe('app routes', () => {
  const pageRoutes = routes.filter((route): route is Route => !route.redirectTo);

  it('declares at least one page route', () => {
    expect(pageRoutes.length).toBeGreaterThan(0);
  });

  it('loads every page lazily instead of importing it eagerly', () => {
    const eager = pageRoutes.filter((route) => route.component).map((route) => route.path);

    expect(eager).toEqual([]);
  });

  it('resolves the home page through loadComponent', async () => {
    const home = routes.find((route) => route.path === '');

    expect(home?.loadComponent).toBeTypeOf('function');
    expect(await home?.loadComponent?.()).toBeTypeOf('function');
  });
});
