import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';

import { UsdPipe } from '@shared/pipes/usd';
import { nextTabIndex } from '@shared/tabs-keyboard';

type ExperienceTabId = 'flow' | 'budget' | 'security';

interface ExperienceTab {
  id: ExperienceTabId;
  label: string;
}

const TAB_BASE_CLASSES =
  'min-h-11 rounded-xl px-5 text-xs sm:text-sm transition-all focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-300';
const TAB_ACTIVE_CLASSES = `${TAB_BASE_CLASSES} bg-emerald-500 font-semibold text-neutral-950 shadow-md shadow-emerald-500/20`;
const TAB_INACTIVE_CLASSES = `${TAB_BASE_CLASSES} font-medium text-neutral-400 hover:text-white`;

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-experience-tabs',
  imports: [UsdPipe],
  templateUrl: './experience-tabs.html',
})
export class ExperienceTabsComponent {
  protected readonly tabs: readonly ExperienceTab[] = [
    { id: 'flow', label: '1. Registro Inmediato' },
    { id: 'budget', label: '2. Presupuestos en Tiempo Real' },
    { id: 'security', label: '3. Informes & Respaldo' },
  ];

  protected activeTab = signal<ExperienceTabId>('flow');

  setTab(tab: ExperienceTabId): void {
    this.activeTab.set(tab);
  }

  /** Recomputed only when the selection changes, instead of on every change detection pass. */
  protected readonly tabClasses = computed(() =>
    Object.fromEntries(
      this.tabs.map(({ id }) => [id, this.activeTab() === id ? TAB_ACTIVE_CLASSES : TAB_INACTIVE_CLASSES]),
    ),
  );

  /** Arrow keys, Home and End move between tabs, as in the WAI-ARIA tabs pattern. */
  onTabsKeydown(event: KeyboardEvent): void {
    const current = this.tabs.findIndex((tab) => tab.id === this.activeTab());
    const next = nextTabIndex(event.key, current, this.tabs.length);
    const target = next === null ? undefined : this.tabs[next];
    if (next === null || !target) return;

    event.preventDefault();
    this.activeTab.set(target.id);
    const tablist = (event.currentTarget as HTMLElement).closest('[role="tablist"]');
    tablist?.querySelectorAll<HTMLElement>('[role="tab"]')[next]?.focus();
  }
}
