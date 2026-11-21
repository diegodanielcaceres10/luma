import { TestBed } from '@angular/core/testing';

import { BentoPdfExportCardComponent } from './bento-pdf-export-card';

describe('BentoPdfExportCardComponent', () => {
  let root: HTMLElement;

  beforeEach(() => {
    const fixture = TestBed.createComponent(BentoPdfExportCardComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('shows its title as a third-level heading', () => {
    expect(root.querySelector('h3')?.textContent?.trim()).toBe('Exportación Ejecutiva a PDF');
  });

  it('keeps a single heading so the page outline stays predictable', () => {
    expect(root.querySelectorAll('h1, h2, h3, h4')).toHaveLength(1);
  });
});
