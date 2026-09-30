import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-experience-tabs',
  templateUrl: './experience-tabs.html',
})
export class ExperienceTabsComponent {
  protected activeTab = signal<'flow' | 'budget' | 'security'>('flow');

  setTab(tab: 'flow' | 'budget' | 'security'): void {
    this.activeTab.set(tab);
  }
}
