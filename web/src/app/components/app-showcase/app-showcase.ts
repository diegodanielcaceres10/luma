import { Component, signal } from '@angular/core';

type TabletScreenId = 'login' | 'home' | 'charts';

interface TabletScreen {
  id: TabletScreenId;
  label: string;
  src: string;
  alt: string;
}

@Component({
  selector: 'app-showcase',
  templateUrl: './app-showcase.html',
})
export class AppShowcaseComponent {
  protected activeFilter = signal<'all' | 'income' | 'expense'>('all');

  protected readonly tabletScreens: readonly TabletScreen[] = [
    {
      id: 'login',
      label: 'Acceso',
      src: 'screens/tablet-login.webp',
      alt: 'Pantalla de inicio de sesión de Luma en tablet',
    },
    {
      id: 'home',
      label: 'Inicio',
      src: 'screens/tablet-home.webp',
      alt: 'Pantalla de inicio de Luma en tablet con menú lateral, balance del mes y últimos movimientos',
    },
    {
      id: 'charts',
      label: 'Estadísticas',
      src: 'screens/tablet-charts.webp',
      alt: 'Pantalla de estadísticas de Luma en tablet con ingresos, gastos y distribución del gasto',
    },
  ];

  protected activeTablet = signal<TabletScreenId>('home');

  setFilter(filter: 'all' | 'income' | 'expense'): void {
    this.activeFilter.set(filter);
  }

  selectTablet(id: TabletScreenId): void {
    this.activeTablet.set(id);
  }

  /** Arrow keys, Home and End move between tabs, as in the WAI-ARIA tabs pattern. */
  onTabletKeydown(event: KeyboardEvent): void {
    const last = this.tabletScreens.length - 1;
    const current = this.tabletScreens.findIndex((s) => s.id === this.activeTablet());
    let next: number;

    switch (event.key) {
      case 'ArrowRight':
        next = current === last ? 0 : current + 1;
        break;
      case 'ArrowLeft':
        next = current === 0 ? last : current - 1;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = last;
        break;
      default:
        return;
    }

    event.preventDefault();
    this.activeTablet.set(this.tabletScreens[next].id);
    const tabs = (event.currentTarget as HTMLElement).querySelectorAll<HTMLElement>('[role="tab"]');
    tabs[next]?.focus();
  }
}
