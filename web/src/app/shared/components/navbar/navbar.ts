import { Component, ElementRef, signal, viewChild } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-navbar',
  imports: [RouterLink],
  templateUrl: './navbar.html',
  host: { '(document:keydown.escape)': 'onEscape()' },
})
export class NavbarComponent {
  protected isMobileMenuOpen = signal(false);

  private readonly menuToggle = viewChild<ElementRef<HTMLButtonElement>>('menuToggle');

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
