import { TestBed } from '@angular/core/testing';

import { FeaturesBentoComponent } from './features-bento';

describe('FeaturesBentoComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(FeaturesBentoComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  const grid = () => root.querySelector<HTMLElement>('.grid');
  const headings = () => Array.from(root.querySelectorAll('h3')).map((h3) => h3.textContent?.trim());

  it('keeps the section anchor used by the navigation', () => {
    expect(root.querySelector('section#funcionalidades')).not.toBeNull();
  });

  it('shows the six feature cards in order', () => {
    expect(headings()).toEqual([
      'Ingresos y Gastos al Detalle',
      'Presupuestos',
      'Insights Mensuales',
      'Múltiples Cuentas y Divisas',
      'Servicios Periódicos',
      'Exportación Ejecutiva a PDF',
    ]);
  });

  it('renders each card as its own component inside the grid', () => {
    const cards = Array.from(grid()?.children ?? []).map((child) => child.tagName.toLowerCase());

    expect(cards).toEqual([
      'app-bento-income-card',
      'app-bento-budget-card',
      'app-bento-insights-card',
      'app-bento-accounts-card',
      'app-bento-recurring-card',
      'app-bento-pdf-export-card',
    ]);
  });

  it('keeps every card box as a direct grid item so the layout does not change', () => {
    const hosts = Array.from(grid()?.children ?? []);

    expect(hosts.length).toBe(6);
    hosts.forEach((host) => {
      expect(host.classList.contains('contents')).toBe(true);
      expect(host.firstElementChild?.classList.contains('rounded-3xl')).toBe(true);
    });
  });
});
