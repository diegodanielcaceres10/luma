import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ExperienceTabsComponent } from './experience-tabs';

describe('ExperienceTabsComponent', () => {
  let fixture: ComponentFixture<ExperienceTabsComponent>;
  let root: HTMLElement;

  const tabs = () => Array.from(root.querySelectorAll<HTMLButtonElement>('[role="tab"]'));
  const panel = () => root.querySelector<HTMLElement>('[role="tabpanel"]');

  beforeEach(() => {
    fixture = TestBed.createComponent(ExperienceTabsComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('exposes three tabs inside a labelled tablist', () => {
    const tablist = root.querySelector('[role="tablist"]');
    expect(tablist?.getAttribute('aria-label')).toBeTruthy();
    expect(tabs().length).toBe(3);
  });

  it('marks only the active tab as selected and focusable', () => {
    const [first, second, third] = tabs();
    expect(first.getAttribute('aria-selected')).toBe('true');
    expect(second.getAttribute('aria-selected')).toBe('false');
    expect(third.getAttribute('aria-selected')).toBe('false');
    expect(first.tabIndex).toBe(0);
    expect(second.tabIndex).toBe(-1);
  });

  it('links every tab to the single tabpanel, which is labelled by the active tab', () => {
    const active = tabs()[0];
    expect(panel()).not.toBeNull();
    for (const tab of tabs()) {
      expect(tab.getAttribute('aria-controls')).toBe(panel()!.id);
    }
    expect(panel()!.getAttribute('aria-labelledby')).toBe(active.id);
  });

  it('selects a tab on click and updates the panel label', () => {
    const second = tabs()[1];
    second.click();
    fixture.detectChanges();

    expect(second.getAttribute('aria-selected')).toBe('true');
    expect(tabs()[0].getAttribute('aria-selected')).toBe('false');
    expect(panel()!.getAttribute('aria-labelledby')).toBe(second.id);
  });

  it('moves selection and focus with the arrow keys, Home and End', () => {
    const activeTab = () => tabs().find((tab) => tab.getAttribute('aria-selected') === 'true')!;
    const press = (key: string) => {
      activeTab().dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
      fixture.detectChanges();
    };
    document.body.appendChild(root);

    press('ArrowRight');
    expect(tabs()[1].getAttribute('aria-selected')).toBe('true');
    expect(document.activeElement).toBe(tabs()[1]);

    press('End');
    expect(tabs()[2].getAttribute('aria-selected')).toBe('true');

    press('ArrowRight');
    expect(tabs()[0].getAttribute('aria-selected')).toBe('true');

    root.remove();
  });

  it('ignores key presses that do not come from a tab', () => {
    const tablist = root.querySelector<HTMLElement>('[role="tablist"]')!;
    const event = new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true, cancelable: true });

    tablist.dispatchEvent(event);
    fixture.detectChanges();

    expect(event.defaultPrevented).toBe(false);
    expect(tabs()[0].getAttribute('aria-selected')).toBe('true');
  });

  it('styles only the selected tab as active, and follows the selection', () => {
    const isActive = (tab: HTMLElement) => tab.classList.contains('bg-emerald-500');

    expect(tabs().map(isActive)).toEqual([true, false, false]);
    expect(tabs()[1].classList.contains('text-neutral-400')).toBe(true);

    tabs()[2].click();
    fixture.detectChanges();

    expect(tabs().map(isActive)).toEqual([false, false, true]);
    expect(tabs()[0].classList.contains('text-neutral-400')).toBe(true);
  });

  it('shows a visible focus style on tabs', () => {
    expect(tabs().length).toBe(3);
    for (const tab of tabs()) {
      expect(tab.className).toContain('focus-visible:outline');
    }
  });
});
