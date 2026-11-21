import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AppShowcaseComponent } from './app-showcase';

describe('AppShowcaseComponent', () => {
  let fixture: ComponentFixture<AppShowcaseComponent>;
  let root: HTMLElement;

  const tabs = () => Array.from(root.querySelectorAll<HTMLButtonElement>('[role="tab"]'));
  const panel = () => root.querySelector<HTMLElement>('[role="tabpanel"]');
  const selected = () => tabs().map((tab) => tab.getAttribute('aria-selected'));

  beforeEach(() => {
    fixture = TestBed.createComponent(AppShowcaseComponent);
    fixture.detectChanges();
    root = fixture.nativeElement;
  });

  it('exposes three tabs inside a labelled tablist', () => {
    const tablist = root.querySelector('[role="tablist"]');

    expect(tablist?.getAttribute('aria-label')).toBeTruthy();
    expect(tabs()).toHaveLength(3);
  });

  it('marks only the active tab as selected and focusable', () => {
    expect(selected()).toEqual(['false', 'true', 'false']);
    expect(tabs().map((tab) => tab.tabIndex)).toEqual([-1, 0, -1]);
  });

  it('selects a tab on click and updates the panel label', () => {
    const third = tabs()[2];
    third.click();
    fixture.detectChanges();

    expect(selected()).toEqual(['false', 'false', 'true']);
    expect(panel()!.getAttribute('aria-labelledby')).toBe(third.id);
  });

  describe('keyboard navigation', () => {
    const activeTab = () => tabs().find((tab) => tab.getAttribute('aria-selected') === 'true')!;
    const press = (key: string, target: HTMLElement = activeTab()) => {
      const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
      target.dispatchEvent(event);
      fixture.detectChanges();
      return event;
    };

    beforeEach(() => document.body.appendChild(root));
    afterEach(() => root.remove());

    it('moves selection and focus with the arrow keys, Home and End', () => {
      press('ArrowRight');
      expect(selected()).toEqual(['false', 'false', 'true']);
      expect(document.activeElement).toBe(tabs()[2]);

      press('Home');
      expect(selected()).toEqual(['true', 'false', 'false']);

      press('End');
      expect(selected()).toEqual(['false', 'false', 'true']);
    });

    it('wraps around at both ends', () => {
      press('End');
      press('ArrowRight');
      expect(selected()).toEqual(['true', 'false', 'false']);

      press('ArrowLeft');
      expect(selected()).toEqual(['false', 'false', 'true']);
    });

    it('ignores key presses that do not come from a tab', () => {
      const tablist = root.querySelector<HTMLElement>('[role="tablist"]')!;
      const before = selected();

      expect(press('ArrowRight', tablist).defaultPrevented).toBe(false);
      expect(selected()).toEqual(before);
    });

    it('prevents the default action only for navigation keys', () => {
      expect(press('ArrowRight').defaultPrevented).toBe(true);
      expect(press('a').defaultPrevented).toBe(false);
      expect(selected()).toEqual(['false', 'false', 'true']);
    });
  });
});
