import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const html = readFileSync(resolve(process.cwd(), 'src/index.html'), 'utf8');

const cspMeta = /<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]*)"\s*\/?>/i.exec(html);

const directives = (): Map<string, string[]> =>
  new Map(
    (cspMeta?.[1] ?? '')
      .split(';')
      .map((part) => part.trim().split(/\s+/))
      .filter(([name]) => name)
      .map(([name, ...sources]) => [name, sources]),
  );

const sha256 = (content: string) => `'sha256-${createHash('sha256').update(content).digest('base64')}'`;

/** Inline scripts that the browser executes (JSON data blocks and external scripts are not). */
const inlineScripts = () =>
  [...html.matchAll(/<script(?![^>]*\bsrc=)(?![^>]*type="application\/json")[^>]*>([\s\S]*?)<\/script>/gi)].map(
    ([, content]) => content,
  );

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
