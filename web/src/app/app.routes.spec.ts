import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { Route } from '@angular/router';

import { routes } from './app.routes';

describe('app routes', () => {
  const pageRoutes = routes.filter((route): route is Route => route.redirectTo === undefined);

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

  it('declares a title for every page route', () => {
    const untitled = pageRoutes.filter((route) => !route.title).map((route) => route.path);

    expect(untitled).toEqual([]);
  });

  it('declares a description of at most 160 characters for every page route', () => {
    const invalid = pageRoutes
      .filter((route) => {
        const description = route.data?.['description'];
        return typeof description !== 'string' || description.length === 0 || description.length > 160;
      })
      .map((route) => route.path);

    expect(invalid).toEqual([]);
  });

  it('gives every page route a different description', () => {
    const descriptions = pageRoutes.map((route) => route.data?.['description']);

    expect(new Set(descriptions).size).toBe(descriptions.length);
  });

  it('keeps the home description equal to the static one in index.html', () => {
    const html = readFileSync(resolve(process.cwd(), 'src/index.html'), 'utf8');
    const staticDescription = /<meta name="description" content="([^"]*)"/.exec(html)?.[1];
    const home = routes.find((route) => route.path === '');

    expect(home?.data?.['description']).toBe(staticDescription);
  });
});
