import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';

const APP = resolve(process.cwd(), 'src/app');

const templates = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return templates(path);
    return path.endsWith('.html') ? [path] : [];
  });

/** Visible text of a template, without tags, comments, bindings or SVG data. */
const visibleText = (html: string): string =>
  html
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<svg\b[\s\S]*?<\/svg>/g, '')
    .replace(/\{\{[\s\S]*?\}\}/g, '')
    .replace(/<[^>]+>/g, ' ');

const offenders = (pattern: RegExp): string[] =>
  templates(APP).flatMap((file) =>
    (visibleText(readFileSync(file, 'utf8')).match(pattern) ?? []).map((text) => `${file.slice(APP.length + 1)}: ${text}`),
  );

describe('amount formatting in templates (I18N-08)', () => {
  it('has no money written as a literal currency symbol or code next to a number', () => {
    expect(offenders(/[$€£]\s?\d[\d.,]*|\d[\d.,]*\s?(?:USD|EUR|GBP)\b/g)).toEqual([]);
  });

  it('has no number written with a decimal point in visible text', () => {
    expect(offenders(/(?<![\w.])\d{1,3}\.\d{1,2}(?![\d.])\s?%?/g)).toEqual([]);
  });

  it('has no thousands separated with a comma in visible text', () => {
    expect(offenders(/\d{1,3},\d{3}(?!\d)/g)).toEqual([]);
  });
});
