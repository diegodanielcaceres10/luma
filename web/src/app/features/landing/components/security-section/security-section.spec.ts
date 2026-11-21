import { TestBed } from '@angular/core/testing';

import { SecuritySectionComponent } from './security-section';

describe('SecuritySectionComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(SecuritySectionComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('keeps the section anchor used by the navigation', () => {
    expect(root.querySelector('section#seguridad')).not.toBeNull();
  });

  it('states the privacy promise in its main heading', () => {
    expect(root.querySelector('h2')?.textContent).toContain('Tus finanzas no son un producto publicitario');
  });

  it('lists the three security guarantees', () => {
    const headings = Array.from(root.querySelectorAll('h3')).map((h3) => h3.textContent?.trim());

    expect(headings).toEqual(
      expect.arrayContaining([
        'Row Level Security (RLS) en Postgres',
        'Autenticación OAuth con Google',
        'Código Abierto y Auditable',
        'Compromiso de Privacidad',
      ]),
    );
  });
});
