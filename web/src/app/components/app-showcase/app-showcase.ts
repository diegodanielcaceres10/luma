import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-showcase',
  templateUrl: './app-showcase.html',
})
export class AppShowcaseComponent {
  protected activeFilter = signal<'all' | 'income' | 'expense'>('all');

  setFilter(filter: 'all' | 'income' | 'expense'): void {
    this.activeFilter.set(filter);
  }
}
