import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { GeminiSectionComponent } from './gemini-section';

describe('GeminiSectionComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    const fixture = TestBed.createComponent(GeminiSectionComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('keeps the section anchor used by the navigation', () => {
    expect(root.querySelector('section#lectura-ia')).not.toBeNull();
  });

  it('presents the receipt and statement reading features', () => {
    const headings = Array.from(root.querySelectorAll('h3')).map((h3) => h3.textContent?.trim());

    expect(headings).toContain('Escanear un ticket');
    expect(headings).toContain('Leer un extracto');
  });

  it('explains the three steps in order', () => {
    const headings = Array.from(root.querySelectorAll('h3')).map((h3) => h3.textContent?.trim() ?? '');
    const steps = ['Elige la imagen', 'Recorta y revisa', 'Confirma'].map((step) => headings.indexOf(step));

    expect(steps).not.toContain(-1);
    expect(steps).toEqual([...steps].sort((a, b) => a - b));
  });

  it('links to the privacy policy for the image handling details', () => {
    expect(root.querySelector('a[href="/privacidad"]')).not.toBeNull();
  });
});
