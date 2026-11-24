import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const read = (file: string) => readFileSync(resolve(process.cwd(), file), 'utf8');

describe('app config', () => {
  it('recovers from failed lazy chunk loads whenever routes are lazy loaded', () => {
    const lazyRoutes = read('src/app/app.routes.ts').includes('loadComponent');
    const config = read('src/app/app.config.ts');

    expect(lazyRoutes).toBe(true);
    expect(config).toMatch(/provideRouter\([\s\S]*withChunkLoadRecovery\(\)[\s\S]*\)/);
  });
});
