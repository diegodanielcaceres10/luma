import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const html = readFileSync(resolve(process.cwd(), 'src/index.html'), 'utf8');

const cspMeta = /<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]*)"\s*\/?>/i.exec(html);

const directives = (): Map<string, string[]> =>
  new Map(
    (cspMeta?.[1] ?? '')
      .split(';')
      .flatMap((part) => {
        const [name, ...sources] = part.trim().split(/\s+/);
        return name ? [[name, sources] as [string, string[]]] : [];
      }),
  );

const sha256 = (content: string) => `'sha256-${createHash('sha256').update(content).digest('base64')}'`;

/** Inline scripts that the browser executes (JSON data blocks and external scripts are not). */
const inlineScripts = () =>
  [...html.matchAll(/<script(?![^>]*\bsrc=)(?![^>]*type="application\/json")[^>]*>([\s\S]*?)<\/script>/gi)].map(
    ([, content = '']) => content,
  );

/**
 * Script that @angular/build (beasties) appends to every built page when `styles.inlineCritical` is on:
 * it switches the deferred stylesheet from media="print" to media="all". It does not exist in src/index.html,
 * so its hash must be allowed by hand. After an Angular upgrade, compare it with dist/web/browser/index.html.
 */
const CRITICAL_CSS_SWITCH_SCRIPT =
  "document.querySelectorAll('link[data-beasties-media]').forEach(function(l){l.media=l.getAttribute('data-beasties-media');l.removeAttribute('data-beasties-media')})";

describe('index.html Content-Security-Policy', () => {
  it('declares a policy through a meta tag', () => {
    expect(cspMeta).not.toBeNull();
  });

  it('is declared before any script, stylesheet or other resource', () => {
    const metaPosition = cspMeta?.index ?? Infinity;
    const firstResource = html.search(/<(script|link|style|img)\b/i);

    expect(metaPosition).toBeLessThan(firstResource);
  });

  it('never allows inline or eval script execution', () => {
    const scriptSources = directives().get('script-src') ?? [];

    expect(scriptSources.length).toBeGreaterThan(0);
    expect(scriptSources).not.toContain("'unsafe-inline'");
    expect(scriptSources).not.toContain("'unsafe-eval'");
  });

  it('allows each inline script by its hash so the policy cannot drift from the markup', () => {
    const scripts = inlineScripts();
    const scriptSources = directives().get('script-src') ?? [];

    expect(scripts.length).toBeGreaterThan(0);
    scripts.forEach((content) => expect(scriptSources).toContain(sha256(content)));
  });

  it('allows the script that Angular adds to activate the deferred stylesheet', () => {
    expect(directives().get('script-src')).toContain(sha256(CRITICAL_CSS_SWITCH_SCRIPT));
  });

  it('does not need unsafe-hashes because no inline event handlers remain', () => {
    expect(directives().get('script-src')).not.toContain("'unsafe-hashes'");
  });

  it('blocks plugins and restricts the base URL', () => {
    expect(directives().get('object-src')).toEqual(["'none'"]);
    expect(directives().get('base-uri')).toEqual(["'self'"]);
  });

  it('allows only the Google Analytics origins that the consent flow needs', () => {
    const policy = directives();

    expect(policy.get('script-src')).toContain('https://www.googletagmanager.com');
    expect(policy.get('connect-src')).toContain('https://*.google-analytics.com');
    expect(policy.get('connect-src')).not.toContain('*');
    expect(policy.get('default-src')).toEqual(["'self'"]);
  });
});
