import { Environment } from './environment.model';

/** Default values: local work and any development environment. Never add secrets. */
export const environment: Environment = {
  production: false,
  siteUrl: 'http://localhost:4200/',
  analytics: {
    // Keeps local development out of the production reports.
    measurementId: '',
    enabled: false,
  },
};
