import { Environment } from './environment.model';

/** Production values. Everything here ships in the public bundle: never add secrets. */
export const environment: Environment = {
  production: true,
  /** Public origin of the deployed site, including the GitHub Pages sub-path. */
  siteUrl: 'https://diegodanielcaceres10.github.io/luma/',
  analytics: {
    /** Public by design: GA4 measurement IDs ship in every page that uses them. */
    measurementId: 'G-0E4MJ98XS2',
    enabled: true,
  },
};
