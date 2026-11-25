import { TestBed } from '@angular/core/testing';

import { BentoAccountsCardComponent } from './bento-accounts-card';

describe('BentoAccountsCardComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(BentoAccountsCardComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('shows its title as a third-level heading', () => {
    expect(root.querySelector('h3')?.textContent?.trim()).toBe('Múltiples Cuentas y Divisas');
  });

  it('keeps a single heading so the page outline stays predictable', () => {
    expect(root.querySelectorAll('h1, h2, h3, h4')).toHaveLength(1);
  });

  it('writes its balances with Spanish number conventions', () => {
    const text = root.textContent ?? '';

    expect(text).toContain('$\u00a018.450');
    expect(text).toContain('$\u00a05.200');
  });
});
