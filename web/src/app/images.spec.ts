import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';

const APP_DIR = resolve(process.cwd(), 'src/app');

const templates = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return templates(path);
    return entry.name.endsWith('.html') ? [path] : [];
  });

interface Image {
  where: string;
  tag: string;
}

const images: Image[] = templates(APP_DIR).flatMap((file) => {
  const source = readFileSync(file, 'utf8');
  return [...source.matchAll(/<img\b[^>]*>/gis)].map(([tag]) => ({
    where: `${relative(APP_DIR, file)}:${source.slice(0, source.indexOf(tag)).split('\n').length}`,
    tag,
  }));
});

/** Matches `name="..."` as well as the Angular bindings `[name]` and `[attr.name]`. */
const hasAttribute = (tag: string, name: string) =>
  new RegExp(`\\s(?:\\[(?:attr\\.)?${name}\\]|${name})\\s*=`, 'i').test(tag);

describe('template images', () => {
  it('finds the images used by the application', () => {
    expect(images.length).toBeGreaterThan(0);
  });

  it('reserves the space of every image with width and height', () => {
    const missing = images.filter(({ tag }) => !hasAttribute(tag, 'width') || !hasAttribute(tag, 'height'));

    expect(missing.map(({ where }) => where)).toEqual([]);
  });

  it('declares how every image loads: lazily, or with an explicit fetch priority', () => {
    const undeclared = images.filter(
      ({ tag }) => !/\sloading\s*=\s*"lazy"/i.test(tag) && !hasAttribute(tag, 'fetchpriority'),
    );

    expect(undeclared.map(({ where }) => where)).toEqual([]);
  });

  it('describes every image with an alt attribute', () => {
    const missing = images.filter(({ tag }) => !hasAttribute(tag, 'alt'));

    expect(missing.map(({ where }) => where)).toEqual([]);
  });
});
