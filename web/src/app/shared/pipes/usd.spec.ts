import { UsdPipe } from './usd';

const NBSP = ' ';

describe('UsdPipe', () => {
  const pipe = new UsdPipe();

  it('formats whole amounts with the Spanish thousands separator', () => {
    expect(pipe.transform(1920)).toBe(`$${NBSP}1.920`);
    expect(pipe.transform(18450)).toBe(`$${NBSP}18.450`);
  });

  it('uses a decimal comma when decimals are requested', () => {
    expect(pipe.transform(120, { decimals: 2 })).toBe(`$${NBSP}120,00`);
  });

  it('shows the sign of gains and losses when asked to', () => {
    expect(pipe.transform(1450, { signed: true })).toBe(`+$${NBSP}1.450`);
    expect(pipe.transform(-95, { signed: true })).toBe(`-$${NBSP}95`);
  });

  it('does not sign zero', () => {
    expect(pipe.transform(0, { signed: true })).toBe(`$${NBSP}0`);
  });

  it('shows the currency code instead of the symbol when asked to', () => {
    expect(pipe.transform(18.5, { decimals: 2, code: true })).toBe(`USD${NBSP}18,50`);
  });

  it('renders nothing for a missing amount', () => {
    expect(pipe.transform(null)).toBe('');
    expect(pipe.transform(undefined)).toBe('');
  });
});
