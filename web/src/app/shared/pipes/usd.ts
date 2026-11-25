import { Pipe, PipeTransform } from '@angular/core';

/** One fixed locale, so the prerendered page and the browser always print the same text. */
const LOCALE = 'es-AR';

export interface UsdOptions {
  /** Fraction digits, always shown (default 0). */
  decimals?: number;
  /** Prefix gains with "+" and losses with "-". */
  signed?: boolean;
  /** Show "USD" instead of the "$" symbol. */
  code?: boolean;
}

const formatters = new Map<string, Intl.NumberFormat>();

const formatterFor = ({ decimals = 0, signed = false, code = false }: UsdOptions): Intl.NumberFormat => {
  const key = `${decimals}|${signed}|${code}`;
  let formatter = formatters.get(key);
  if (!formatter) {
    formatter = new Intl.NumberFormat(LOCALE, {
      style: 'currency',
      currency: 'USD',
      currencyDisplay: code ? 'code' : 'narrowSymbol',
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
      signDisplay: signed ? 'exceptZero' : 'auto',
    });
    formatters.set(key, formatter);
  }
  return formatter;
};

/** Formats the dollar amounts shown in the app mockups with Spanish number conventions. */
@Pipe({ name: 'usd' })
export class UsdPipe implements PipeTransform {
  transform(value: number | null | undefined, options: UsdOptions = {}): string {
    return value == null ? '' : formatterFor(options).format(value);
  }
}
