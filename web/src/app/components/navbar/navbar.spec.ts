import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { NavbarComponent } from './navbar';

describe('NavbarComponent mobile menu', () => {
  let fixture: ComponentFixture<NavbarComponent>;
  let root: HTMLElement;

  const toggle = () => root.querySelector<HTMLButtonElement>('button[aria-controls="mobile-menu"]');

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideRouter([])] });
    fixture = TestBed.createComponent(NavbarComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
    document.body.appendChild(root);
  });

  afterEach(() => root.remove());

  it('exposes the collapsed state and an opening label on the toggle', () => {
    expect(toggle()).not.toBeNull();
    expect(toggle()!.getAttribute('aria-expanded')).toBe('false');
    expect(toggle()!.getAttribute('aria-label')).toBe('Abrir menú');
  });

  it('reflects the open state in aria-expanded and in the label', () => {
    toggle()!.click();
    fixture.detectChanges();

    expect(toggle()!.getAttribute('aria-expanded')).toBe('true');
    expect(toggle()!.getAttribute('aria-label')).toBe('Cerrar menú');
  });

  it('renders the controlled menu with the id referenced by the toggle when open', () => {
    toggle()!.click();
    fixture.detectChanges();

    expect(root.querySelector('#mobile-menu')).not.toBeNull();
  });

  it('closes the menu with Escape and returns focus to the toggle', () => {
    toggle()!.click();
    fixture.detectChanges();

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();

    expect(toggle()!.getAttribute('aria-expanded')).toBe('false');
    expect(root.querySelector('#mobile-menu')).toBeNull();
    expect(document.activeElement).toBe(toggle());
  });

  it('ignores Escape while the menu is closed', () => {
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    fixture.detectChanges();

    expect(toggle()!.getAttribute('aria-expanded')).toBe('false');
  });

  it('keeps a visible focus indicator instead of removing the outline', () => {
    const classes = toggle()!.className;
    expect(classes).not.toContain('focus:outline-none');
    expect(classes).toContain('focus-visible:outline');
  });
});
