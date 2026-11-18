/** Shape shared by every environment file, so they cannot drift apart. */
export interface Environment {
  production: boolean;
  /** Public origin of the site, absolute and ending with a slash. */
  siteUrl: string;
  analytics: {
    measurementId: string;
    enabled: boolean;
  };
}
