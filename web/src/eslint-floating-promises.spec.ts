import { ESLint } from 'eslint';

/** Lints a snippet as if it were the given application file, using the project's real ESLint config. */
const lint = async (code: string, filePath: string) => {
  const [result] = await new ESLint({ cwd: process.cwd() }).lintText(code, { filePath });
  return result?.messages.map((message) => message.ruleId) ?? [];
};

describe('ESLint promise handling (OBS-04)', () => {
  const timeout = 60_000;

  it('rejects a promise that is neither awaited nor handled', async () => {
    const rules = await lint('Promise.resolve(1);\n', 'src/app/core/services/page-url.ts');

    expect(rules).toContain('@typescript-eslint/no-floating-promises');
  }, timeout);

  it('accepts a promise whose rejection is handled', async () => {
    const rules = await lint('Promise.resolve(1).catch((error) => console.error(error));\n', 'src/main.ts');

    expect(rules).not.toContain('@typescript-eslint/no-floating-promises');
  }, timeout);
});
