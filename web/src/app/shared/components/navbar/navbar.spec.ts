import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { ActiveSectionService } from '@core/services/active-section';
import { NavbarComponent } from './navbar';

const SECTION_IDS = ['funcionalidades', 'experiencia', 'lectura-ia', 'seguridad', 'stack'];

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

  describe('reacting to signal changes', () => {
    const settle = async () => {
      await fixture.whenStable();
      fixture.detectChanges();
    };

    const menuLinks = () => Array.from(root.querySelectorAll<HTMLAnchorElement>('#mobile-menu a'));

    beforeEach(() => {
      // Prevents jsdom from attempting real navigation when a link is clicked.
      root.addEventListener('click', (event) => event.preventDefault());
    });

    it('opens and closes the menu on consecutive toggles', async () => {
      toggle()!.click();
      await settle();
      expect(root.querySelector('#mobile-menu')).not.toBeNull();

      toggle()!.click();
      await settle();
      expect(root.querySelector('#mobile-menu')).toBeNull();
    });

    it('closes the open menu after choosing any of its links', async () => {
      toggle()!.click();
      await settle();
      const count = menuLinks().length;
      expect(count).toBeGreaterThan(0);

      for (let index = 0; index < count; index++) {
        if (!root.querySelector('#mobile-menu')) {
          toggle()!.click();
          await settle();
        }
        menuLinks()[index]!.click();
        await settle();

        expect(root.querySelector('#mobile-menu')).toBeNull();
        expect(toggle()!.getAttribute('aria-expanded')).toBe('false');
      }
    });

    it('keeps the section anchors of the menu aligned with the desktop navigation', async () => {
      toggle()!.click();
      await settle();

      const anchors = (selector: string) =>
        Array.from(root.querySelectorAll<HTMLAnchorElement>(selector))
          .map((a) => a.getAttribute('href'))
          .filter((href) => href?.startsWith('#'));

      expect(anchors('#mobile-menu a')).toEqual(anchors('nav a'));
    });
  });
});

describe('NavbarComponent section highlight', () => {
  const active = signal<string | null>(null);
  const watch = vi.fn();
  const stop = vi.fn();
  let fixture: ComponentFixture<NavbarComponent>;
  let root: HTMLElement;

  const desktopLinks = () => Array.from(root.querySelectorAll<HTMLAnchorElement>('nav a'));
  const mobileLinks = () => Array.from(root.querySelectorAll<HTMLAnchorElement>('#mobile-menu a[href^="#"]'));
  const current = (links: HTMLAnchorElement[]) =>
    links.filter((a) => a.getAttribute('aria-current') === 'location').map((a) => a.getAttribute('href'));

  beforeEach(async () => {
    active.set(null);
    watch.mockReset();
    stop.mockReset();
    TestBed.configureTestingModule({
      providers: [provideRouter([]), { provide: ActiveSectionService, useValue: { active, watch, stop } }],
    });
    fixture = TestBed.createComponent(NavbarComponent);
    await fixture.whenStable();
    root = fixture.nativeElement;
  });

  it('watches the sections of the navigation in order once rendered', () => {
    expect(watch).toHaveBeenCalledWith(SECTION_IDS);
    expect(desktopLinks().map((a) => a.getAttribute('href'))).toEqual(SECTION_IDS.map((id) => `#${id}`));
  });

  it('marks no link as current while no section is active', () => {
    expect(current(desktopLinks())).toEqual([]);
  });

  it('marks the active section as the current location in the desktop navigation', () => {
    active.set('seguridad');
    fixture.detectChanges();

    expect(current(desktopLinks())).toEqual(['#seguridad']);
  });

  it('marks the active section in the mobile menu too', () => {
    root.querySelector<HTMLButtonElement>('button[aria-controls="mobile-menu"]')!.click();
    active.set('stack');
    fixture.detectChanges();

    expect(current(mobileLinks())).toEqual(['#stack']);
  });

  it('stops watching when destroyed', () => {
    fixture.destroy();

    expect(stop).toHaveBeenCalledTimes(1);
  });
});
