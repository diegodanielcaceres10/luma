import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const MINIMUM = 80;
const METRICS = ['statements', 'branches', 'functions', 'lines'] as const;

interface TestOptions {
  coverage?: boolean;
  coverageThresholds?: Partial<Record<(typeof METRICS)[number], number>> & { perFile?: boolean };
}

const options = (): TestOptions => {
  const workspace = JSON.parse(readFileSync(resolve(process.cwd(), 'angular.json'), 'utf8'));
  return workspace.projects.web.architect.test.options ?? {};
};

describe('coverage gate', () => {
  it('collects coverage on every test run, not only when a flag is passed', () => {
    expect(options().coverage).toBe(true);
  });

  it.each(METRICS)(`enforces a %s threshold of at least ${MINIMUM} percent`, (metric) => {
    expect(options().coverageThresholds?.[metric]).toBeGreaterThanOrEqual(MINIMUM);
  });
});
