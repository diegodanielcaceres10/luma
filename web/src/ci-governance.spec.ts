import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd(), '..');
const read = (path: string) => readFileSync(resolve(root, path), 'utf8');

const codeownersPath = '.github/CODEOWNERS';
const templatePath = '.github/pull_request_template.md';

describe('repository governance', () => {
  describe('CODEOWNERS', () => {
    const rules = () =>
      read(codeownersPath)
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith('#'));

    it('exists', () => {
      expect(existsSync(resolve(root, codeownersPath))).toBe(true);
    });

    it('assigns an owner to every path with a catch-all rule', () => {
      expect(rules()[0]).toMatch(/^\*\s+@[\w-]+(\/[\w-]+)?(\s+@[\w-]+(\/[\w-]+)?)*$/);
    });

    it('gives the pipelines an explicit owner', () => {
      expect(rules().some((rule) => /^\/\.github\/\s+@[\w-]+/.test(rule))).toBe(true);
    });

    it('only uses well-formed rules (a path followed by one or more owners)', () => {
      expect(rules().filter((rule) => !/^\S+(\s+@[\w-]+(\/[\w-]+)?)+$/.test(rule))).toEqual([]);
    });
  });

  describe('pull request template', () => {
    it('exists', () => {
      expect(existsSync(resolve(root, templatePath))).toBe(true);
    });

    it('asks for the same checks the pull request pipeline enforces', () => {
      const template = read(templatePath);

      expect(template).toContain('npm run lint');
      expect(template).toContain('npm run test');
      expect(template).toContain('npm run build');
      expect(template).toMatch(/web\/package\.json/);
      expect(template).toMatch(/versi[oó]n/i);
    });

    it('has a section to describe the change and a checklist', () => {
      const template = read(templatePath);

      expect(template).toMatch(/^## .+/m);
      expect(template).toMatch(/^- \[ \] /m);
    });
  });
});
