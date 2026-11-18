import { Environment } from './environment.model';

/** Replaces `environment.ts` in the development build (see `fileReplacements` in angular.json). */
export const environment: Environment = {
  production: false,
  siteUrl: 'http://localhost:4200/',
  analytics: {
    // Keeps local development out of the production reports.
    measurementId: '',
    enabled: false,
  },
};
