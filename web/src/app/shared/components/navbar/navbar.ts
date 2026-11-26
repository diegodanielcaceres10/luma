import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  afterNextRender,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { RouterLink } from '@angular/router';

import { ActiveSectionService } from '@core/services/active-section';
import { AppVersionComponent } from '../app-version/app-version';

const NAV_SECTIONS = [
  { id: 'funcionalidades', label: 'Funcionalidades' },
  { id: 'experiencia', label: 'Experiencia' },
  { id: 'lectura-ia', label: 'Lectura con IA' },
  { id: 'seguridad', label: 'Privacidad & Seguridad' },
  { id: 'stack', label: 'Tecnología' },
] as const;

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-navbar',
  imports: [AppVersionComponent, RouterLink],
  templateUrl: './navbar.html',
  host: { '(document:keydown.escape)': 'onEscape()' },
})
export class NavbarComponent {
  protected isMobileMenuOpen = signal(false);
  protected readonly sections = NAV_SECTIONS;

  private readonly menuToggle = viewChild<ElementRef<HTMLButtonElement>>('menuToggle');

  private readonly activeSections = inject(ActiveSectionService);
  protected readonly activeSection = this.activeSections.active;

  constructor() {
    afterNextRender(() => this.activeSections.watch(NAV_SECTIONS.map(({ id }) => id)));
    inject(DestroyRef).onDestroy(() => this.activeSections.stop());
  }

  toggleMobileMenu(): void {
    this.isMobileMenuOpen.update((v) => !v);
  }

  closeMobileMenu(): void {
    this.isMobileMenuOpen.set(false);
  }

  /** Closes the open menu and returns focus to the toggle so keyboard users keep their place. */
  protected onEscape(): void {
    if (!this.isMobileMenuOpen()) return;
    this.closeMobileMenu();
    this.menuToggle()?.nativeElement.focus();
  }
}
